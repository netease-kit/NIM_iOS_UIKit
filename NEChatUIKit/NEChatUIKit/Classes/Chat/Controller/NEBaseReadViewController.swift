
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonUIKit
import NECoreIM2Kit
import NIMSDK
import UIKit

@objcMembers
open class NEBaseReadViewController: ChatBaseViewController, UIScrollViewDelegate, UITableViewDelegate,
  UITableViewDataSource {
  public var read: Bool = true
  public var line: UIView = .init()
  public var lineLeftCons: NSLayoutConstraint?
  public var readTableView = UITableView(frame: .zero, style: .plain)
  public var readUsers = [NETeamMemberInfoModel]()
  public var unReadUsers = [NETeamMemberInfoModel]()
  public let readButton = UIButton(type: .custom)
  public let unreadButton = UIButton(type: .custom)
  private var message: V2NIMMessage
  private var teamId: String
  private let chatRepo = ChatRepo.shared
  private let contactRepo = ContactRepo.shared
  init(message: V2NIMMessage, teamId: String) {
    self.message = message
    self.teamId = teamId
    super.init(nibName: nil, bundle: nil)
  }

  public required init?(coder: NSCoder) {
    message = V2NIMMessage()
    teamId = ""
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    commonUI()
    loadData(message: message)
  }

  open func commonUI() {
    title = chatLocalizable("message_read")
    navigationView.moreButton.isHidden = true

    readButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    readButton.setTitle(chatLocalizable("read"), for: .normal)
    readButton.setTitleColor(UIColor.ne_darkText, for: .normal)
    readButton.translatesAutoresizingMaskIntoConstraints = false
    readButton.addTarget(self, action: #selector(readButtonEvent), for: .touchUpInside)
    readButton.accessibilityIdentifier = "id.tabHasRead"

    unreadButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
    unreadButton.setTitle(chatLocalizable("unread"), for: .normal)
    unreadButton.setTitleColor(UIColor.ne_darkText, for: .normal)
    unreadButton.translatesAutoresizingMaskIntoConstraints = false
    unreadButton.addTarget(self, action: #selector(unreadButtonEvent), for: .touchUpInside)
    unreadButton.accessibilityIdentifier = "id.tabUnRead"

    view.addSubview(readButton)
    NSLayoutConstraint.activate([
      readButton.topAnchor.constraint(equalTo: view.topAnchor, constant: topConstant),
      readButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      readButton.heightAnchor.constraint(equalToConstant: 48),
      readButton.widthAnchor.constraint(equalToConstant: kScreenWidth / 2.0),
    ])

    view.addSubview(unreadButton)
    NSLayoutConstraint.activate([
      unreadButton.topAnchor.constraint(equalTo: readButton.topAnchor),
      unreadButton.leadingAnchor.constraint(equalTo: readButton.trailingAnchor),
      unreadButton.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      unreadButton.heightAnchor.constraint(equalToConstant: 48),
    ])

    line.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(line)
    lineLeftCons = line.leadingAnchor.constraint(equalTo: view.leadingAnchor)
    NSLayoutConstraint.activate([
      line.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 0),
      line.heightAnchor.constraint(equalToConstant: 1),
      line.widthAnchor.constraint(equalTo: readButton.widthAnchor),
      lineLeftCons!,
    ])

    view.addSubview(emptyView)
    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        emptyView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
        emptyView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0),
        emptyView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0),
        emptyView.bottomAnchor.constraint(
          equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
          constant: 0
        ),
      ])
    } else {
      NSLayoutConstraint.activate([
        emptyView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
        emptyView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
        emptyView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
        emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
      ])
    }
    readTableView.delegate = self
    readTableView.dataSource = self
    readTableView.sectionHeaderHeight = 0
    readTableView.sectionFooterHeight = 0
    readTableView.translatesAutoresizingMaskIntoConstraints = false
    readTableView.separatorStyle = .none
    readTableView.tableFooterView = UIView()
    view.addSubview(readTableView)

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate([
        readTableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
        readTableView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
        readTableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        readTableView.bottomAnchor
          .constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
      ])
    } else {
      // Fallback on earlier versions
      NSLayoutConstraint.activate([
        readTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        readTableView.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 1),
        readTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        readTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      ])
    }
  }

  open func readButtonEvent(button: UIButton) {
    if read {
      return
    }
    read = true
    lineLeftCons?.constant = 0
    UIView.animate(withDuration: 0.5) {
      self.view.layoutIfNeeded()
    }
    if readUsers.count == 0 {
      readTableView.isHidden = true
      emptyView.isHidden = false
    } else {
      readTableView.isHidden = false
      emptyView.isHidden = true
      readTableView.reloadData()
    }
  }

  open func unreadButtonEvent(button: UIButton) {
    if !read {
      return
    }
    read = false
    lineLeftCons?.constant = button.width
    UIView.animate(withDuration: 0.5) {
      self.view.layoutIfNeeded()
    }
    if unReadUsers.count == 0 {
      readTableView.isHidden = true
      emptyView.isHidden = false
    } else {
      readTableView.isHidden = false
      emptyView.isHidden = true
      readTableView.reloadData()
    }
  }

  func loadData(message: V2NIMMessage) {
    chatRepo.getTeamMessageReceiptDetail(message: message, memberAccountIds: []) { readReceiptDetail, error in
      guard let readReceiptDetail = readReceiptDetail else { return }
      let group = DispatchGroup()
      if let error = error as? NSError {
        if error.code == protocolSendFailed {
          self.showToast(commonLocalizable("network_error"))
        } else {
          self.showToast(error.localizedDescription)
        }
        return
      }

      self.readButton.setTitle("已读 (" + "\(readReceiptDetail.readAccountList.count)" + ")", for: .normal)
      self.unreadButton.setTitle("未读 (" + "\(readReceiptDetail.unreadAccountList.count)" + ")", for: .normal)

      // 加载用户信息
      let loadUserIds = readReceiptDetail.readAccountList + readReceiptDetail.unreadAccountList
      group.enter()
      ChatTeamCache.shared.loadShowName(userIds: loadUserIds, teamId: self.teamId) {
        // 已读用户
        for userId in readReceiptDetail.readAccountList {
          if let memberInfo = ChatTeamCache.shared.getTeamMemberInfo(accountId: userId) {
            self.readUsers.append(memberInfo)
          }
        }

        // 未读用户
        for userId in readReceiptDetail.unreadAccountList {
          if let memberInfo = ChatTeamCache.shared.getTeamMemberInfo(accountId: userId) {
            self.unReadUsers.append(memberInfo)
          }
        }

        group.leave()
      }

      group.notify(queue: .main) {
        self.readTableView.reloadData()
        if self.read, self.readUsers.count == 0 {
          self.readTableView.isHidden = true
          self.emptyView.isHidden = false
        } else {
          self.readTableView.isHidden = false
          self.emptyView.isHidden = true
        }
      }
    }
  }

  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if read {
      return readUsers.count
    } else {
      return unReadUsers.count
    }
  }

  func cellSetModel(cell: UserBaseTableViewCell, indexPath: IndexPath) -> UITableViewCell {
    if read {
      let model = readUsers[indexPath.row]
      cell.setModel(model)

    } else {
      let model = unReadUsers[indexPath.row]
      cell.setModel(model)
    }
    return cell
  }

  open func tableView(_ tableView: UITableView,
                      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "\(UserBaseTableViewCell.self)",
      for: indexPath
    ) as! UserBaseTableViewCell
    return cellSetModel(cell: cell, indexPath: indexPath)
  }

  public lazy var emptyView: NEEmptyDataView = {
    let view = NEEmptyDataView(
      imageName: "emptyView",
      content: chatLocalizable("message_all_unread"),
      frame: .zero
    )
    view.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(view)
    return view
  }()
}
