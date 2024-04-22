// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatUIKit
import NECoreKit
import NETeamUIKit
import NIMSDK
import UIKit

@objcMembers
class PersonInfoViewController: NEBaseViewController,
  UINavigationControllerDelegate, PersonInfoViewModelDelegate, UITableViewDelegate,
  UITableViewDataSource, NEContactListener {
  public var cellClassDic = [
    SettingCellType.SettingSubtitleCell.rawValue: CustomTeamSettingSubtitleCell.self,
    SettingCellType.SettingHeaderCell.rawValue: CustomTeamSettingHeaderCell.self,
    SettingCellType.SettingSubtitleCustomCell.rawValue: CustomTeamSettingRightCustomCell.self,
  ]
  private var viewModel = PersonInfoViewModel()
  private var className = "PersonInfoViewController"

  override func viewDidLoad() {
    super.viewDidLoad()
    ContactRepo.shared.addContactListener(self)
    viewModel.getData()
    setupSubviews()
    initialConfig()
  }

  func initialConfig() {
    title = NSLocalizedString("person_info", comment: "")
    navigationView.navTitle.text = title

    if NEStyleManager.instance.isNormalStyle() {
      view.backgroundColor = .ne_backgroundColor
      navigationView.backgroundColor = .ne_backgroundColor
      navigationController?.navigationBar.backgroundColor = .ne_backgroundColor
    } else {
      view.backgroundColor = .funChatBackgroundColor
    }
    viewModel.delegate = self
  }

  func setupSubviews() {
    view.addSubview(tableView)
    if NEStyleManager.instance.isNormalStyle() {
      topConstant += 12
    }
    NSLayoutConstraint.activate([
      tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
      tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
      tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    for (key, value) in cellClassDic {
      tableView.register(value, forCellReuseIdentifier: "\(key)")
    }
  }

  func showAlert(firstContent: String, secondContent: String,
                 selectValue: @escaping ((_ value: NSInteger) -> Void)) {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    alert.modalPresentationStyle = .popover

    let first = UIAlertAction(title: firstContent, style: .default) { action in
      selectValue(0)
    }
    first.setValue(UIColor(hexString: "0x333333"), forKey: "_titleTextColor")
    first.accessibilityIdentifier = "id.action1"

    let second = UIAlertAction(title: secondContent, style: .default) { action in
      selectValue(1)
    }
    second.setValue(UIColor(hexString: "0x333333"), forKey: "_titleTextColor")
    second.accessibilityIdentifier = "id.action2"

    let cancel = UIAlertAction(title: NSLocalizedString("cancel", comment: ""),
                               style: .cancel)

    cancel.setValue(UIColor(hexString: "0x333333"), forKey: "_titleTextColor")
    cancel.accessibilityIdentifier = "id.action3"

    alert.addAction(first)
    alert.addAction(second)
    alert.addAction(cancel)
    fixAlertOnIpad(alert)
    present(alert, animated: true, completion: nil)
  }

  func showCustomAlert(firstContent: String, secondContent: String,
                       selectValue: @escaping ((_ value: NSInteger) -> Void)) {
    let first = NECustomAlertAction(title: firstContent) {
      selectValue(0)
    }

    let second = NECustomAlertAction(title: secondContent) {
      selectValue(1)
    }

    showCustomActionSheet([first, second])
  }

  func showDatePicker() {
    view.addSubview(pickerView)
    pickerView.timeCallBack = { [weak self] time in
      if let t = time {
        self?.viewModel.updateSelfBirthday(t) { error in
          if let err = error {
            if err.code == protocolSendFailed {
              self?.showToast(commonLocalizable("network_error"))
            } else {
              self?.showToast(NSLocalizedString("setting_birthday_failure", comment: ""))
            }
          }
        }
      }
    }
    NSLayoutConstraint.activate([
      pickerView.leftAnchor.constraint(equalTo: view.leftAnchor),
      pickerView.rightAnchor.constraint(equalTo: view.rightAnchor),
      pickerView.topAnchor.constraint(equalTo: view.topAnchor),
      pickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  lazy var tableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .clear
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorColor = .clear
    tableView.separatorStyle = .none
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
    return tableView
  }()

  private lazy var pickerView: BirthdayDatePickerView = {
    let picker = BirthdayDatePickerView()
    picker.translatesAutoresizingMaskIntoConstraints = false
    return picker
  }()

  /// 用户信息变更回调
  /// - Parameter users: 用户列表
  func onUserProfileChanged(_ users: [V2NIMUser]) {
    for user in users {
      if user.accountId == IMKitClient.instance.account() {
        print("change self user profile : ", user.yx_modelToJSONString() as Any)
        viewModel.userInfo = NEUserWithFriend(user: user)
        viewModel.refreshData()
        tableView.reloadData()
        break
      }
    }
  }

  // MARK: UIImagePickerControllerDelegate

  func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController
                               .InfoKey: Any]) {
    let image: UIImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
    uploadHeadImage(image: image)
    dismiss(animated: true, completion: nil)
  }

  public func uploadHeadImage(image: UIImage) {
    weak var weakSelf = self
    if NEChatDetectNetworkTool.shareInstance.manager?.isReachable == false {
      weakSelf?.showToast(commonLocalizable("network_error"))
      return
    }

    view.makeToastActivity(.center)
    if let imageData = image.jpegData(compressionQuality: 0.6) as NSData?,
       var filePath = NEPathUtils.getDirectoryForDocuments(dir: "NEIMUIKit/image/") {
      filePath += "\(IMKitClient.instance.account())_avatar.jpg"
      let succcess = imageData.write(toFile: filePath, atomically: true)
      if succcess {
        let fileTask = ResourceRepo.shared.createUploadFileTask(filePath)
        ResourceRepo.shared.upload(fileTask, nil) { [weak self] urlString, error in
          if error == nil {
            self?.viewModel.updateSelfAvatar(urlString ?? "") { [weak self] error in
              if error != nil {
                self?.showToast(NSLocalizedString("setting_head_failure", comment: ""))
              }
            }
          } else {
            NEALog.errorLog(
              weakSelf?.className ?? "",
              desc: "❌CALLBACK upload image failed,error = \(error!)"
            )
          }
          self?.view.hideToastActivity()
        }
      }
    }
  }

  // MARK: PersonInfoViewModelDelegate

  func didClickHeadImage() {
    if NEStyleManager.instance.isNormalStyle() {
      showBottomAlert(self)
    } else {
      showCustomBottomAlert(self)
    }
  }

  func didClickNickName(name: String) {
    let ctrl = InputPersonInfoController()
    ctrl.configTitle(editType: .nickName)
    ctrl.contentText = name
    weak var weakSelf = self
    ctrl.callBack = { editText in
      weakSelf?.viewModel.updateSelfNickName(editText) { [weak self] error in
        if error != nil {
          self?.showToastInWindow(NSLocalizedString("setting_nickname_failure", comment: ""))
        } else {
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func didClickGender() {
    var gender = V2NIMGender.GENDER_UNKNOWN
    weak var weakSelf = self
    let block: ((_ value: NSInteger) -> Void) = {
      value in
      gender = value == 0 ? .GENDER_MALE : .GENDER_FEMALE

      weakSelf?.viewModel.updateSelfSex(gender) { [weak self] error in
        if error != nil {
          if error?.code == protocolSendFailed {
            self?.showToast(commonLocalizable("network_error"))
          } else {
            self?.showToast(NSLocalizedString("change_gender_failure", comment: ""))
          }
        }
      }
    }
    if NEStyleManager.instance.isNormalStyle() {
      showAlert(firstContent: NSLocalizedString("male", comment: ""),
                secondContent: NSLocalizedString("female", comment: ""),
                selectValue: block)
    } else {
      showCustomAlert(firstContent: NSLocalizedString("male", comment: ""),
                      secondContent: NSLocalizedString("female", comment: ""),
                      selectValue: block)
    }
  }

  func didClickBirthday(birth: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    if let selectDate = formatter.date(from: birth) {
      pickerView.picker.setDate(selectDate, animated: true)
    }
    showDatePicker()
  }

  func didClickMobile(mobile: String) {
    let ctrl = InputPersonInfoController()
    ctrl.configTitle(editType: .cellphone)
    ctrl.contentText = mobile
    weak var weakSelf = self
    ctrl.callBack = { editText in
      weakSelf?.viewModel.updateSelfMobile(editText) { [weak self] error in
        if error != nil {
          self?.showToastInWindow(NSLocalizedString("change_phone_failure", comment: ""))
        } else {
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func isValidEmail(_ email: String) -> Bool {
    let emailRegex = #"^\w+@\w+\.[a-zA-Z]{2,}"#
    return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
  }

  func didClickEmail(email: String) {
    let ctrl = InputPersonInfoController()
    ctrl.configTitle(editType: .email)
    ctrl.contentText = email
    weak var weakSelf = self
    ctrl.callBack = { editText in

      if weakSelf?.isValidEmail(editText) == false {
        weakSelf?.showToastInWindow(NSLocalizedString("change_email_failure", comment: ""))
        return
      }

      weakSelf?.viewModel.updateSelfEmail(editText) { [weak self] error in
        if error != nil {
          self?.showToastInWindow(NSLocalizedString("change_email_failure", comment: ""))
        } else {
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func didClickSign(sign: String) {
    let ctrl = InputPersonInfoController()
    ctrl.configTitle(editType: .specialSign)
    ctrl.contentText = sign
    weak var weakSelf = self
    ctrl.callBack = { editText in
      weakSelf?.viewModel.updateSelfSign(editText) { [weak self] error in
        if error != nil {
          self?.showToastInWindow(NSLocalizedString("change_sign_failure", comment: ""))
        } else {
          self?.navigationController?.popViewController(animated: true)
        }
      }
    }
    navigationController?.pushViewController(ctrl, animated: true)
  }

  func didCopyAccount(account: String) {
    showToast(NSLocalizedString("copy_success", comment: ""))
    UIPasteboard.general.string = account
  }

  // MARK: UITableViewDelegate, UITableViewDataSource

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if viewModel.sectionData.count > section {
      let model = viewModel.sectionData[section]
      return model.cellModels.count
    }
    return 0
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.sectionData.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(model.type)",
      for: indexPath
    ) as? NEBaseTeamSettingCell {
      cell.configure(model)
      return cell
    }
    return UITableViewCell()
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    if let block = model.cellClick {
      block()
    }
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewModel.sectionData[indexPath.section].cellModels[indexPath.row]
    return model.rowHeight
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 {
      return 0
    }
    if viewModel.sectionData.count > section {
      let model = viewModel.sectionData[section]
      if model.cellModels.count > 0 {
        return 12.0
      }
    }
    return 0
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let headerView = UIView()
    headerView.backgroundColor = .ne_lightBackgroundColor
    return headerView
  }
}
