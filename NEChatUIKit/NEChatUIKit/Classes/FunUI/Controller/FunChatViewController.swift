// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NECommonKit
import NIMSDK
import UIKit

@objcMembers
open class FunChatViewController: ChatViewController, FunChatInputViewDelegate, FunChatRecordViewDelegate {
  public weak var recordView: FunRecordAudioView?

  override public init(conversationId: String) {
    super.init(conversationId: conversationId)
    cellRegisterDic = ChatMessageHelper.getChatCellRegisterDic(isFun: true)

    normalInputHeight = 90
    brokenNetworkViewHeight = 48
    navigationView.titleBarBottomLine.backgroundColor = .funChatNavigationBottomLineColor
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .funChatBackgroundColor // 换肤颜色提取
    view.bringSubviewToFront(chatInputView)
    brokenNetworkView.errorIconView.isHidden = false
    brokenNetworkView.backgroundColor = .funChatNetworkBrokenBackgroundColor
    brokenNetworkView.contentLabel.textColor = .funChatNetworkBrokenTitleColor
    getFunInputView()?.funDelegate = self
  }

  override open func getMenuView() -> NEBaseChatInputView {
    let input = FunChatInputView()
    input.multipleLineDelegate = self
    let gesture = UILongPressGestureRecognizer(target: self, action: #selector(holdToSpeak(gesture:)))
    input.holdToSpeakView.addGestureRecognizer(gesture)
    return input
  }

  override open func getForwardAlertController() -> NEBaseForwardAlertViewController {
    FunForwardAlertViewController()
  }

  override open func getMultiForwardViewController(_ messageAttachmentUrl: String?,
                                                   _ messageAttachmentFilePath: String,
                                                   _ messageAttachmentMD5: String?) -> MultiForwardViewController {
    FunMultiForwardViewController(messageAttachmentUrl, messageAttachmentFilePath, messageAttachmentMD5)
  }

  override func getUserSelectVC() -> NEBaseSelectUserViewController {
    FunSelectUserViewController(sessionId: viewModel.sessionId, showSelf: false)
  }

  override func getTextViewController(title: String?, body: String?) -> TextViewController {
    let textViewController = super.getTextViewController(title: title, body: body)
    textViewController.view.backgroundColor = .funChatBackgroundColor
    return textViewController
  }

  open func recordModeChangeDidClick() {
    normalOffset = 0
    if chatInputView.chatInpuMode == .multipleSend {
      normalInputHeight = 90
      if let inputView = chatInputView as? FunChatInputView {
        inputView.setRecordNormalStyle()
      }
    }

    layoutInputView(offset: 0)

    UIApplication.shared.keyWindow?.endEditing(true)
  }

  open func didHideRecordMode() {
    if chatInputView.chatInpuMode == .multipleSend {
      normalInputHeight = 130
      if let inputView = chatInputView as? FunChatInputView {
        inputView.resotreMutipleModeFromRecordMode()
      }
      layoutInputView(offset: 0)
    }
  }

  open func didHideReplyMode() {
    viewModel.isReplying = false

    if currentKeyboardHeight > 0 {
      normalOffset = 30
    } else {
      normalOffset = 0
    }
    layoutInputView(offset: currentKeyboardHeight)
  }

  open func didShowReplyMode() {
    viewModel.isReplying = true
    chatInputView.textView.becomeFirstResponder()
  }

  override open func expandMoreAction() {
    var items = NEChatUIKitClient.instance.getMoreActionData(sessionType: V2NIMConversationIdUtil.conversationType(viewModel.conversationId))
    if NEChatKitClient.instance.delegate == nil {
      items = items.filter { item in
        if item.type == .location {
          return false
        }
        return true
      }
    }
    let photo = NEMoreItemModel()
    photo.image = UIImage.ne_imageNamed(name: "fun_chat_photo")
    photo.title = chatLocalizable("chat_photo")
    photo.type = .photo
    photo.customDelegate = self
    photo.action = #selector(openPhoto)
    items.insert(photo, at: 0)
    chatInputView.chatAddMoreView.configData(data: items)
  }

  func openPhoto() {
    NEALog.infoLog(className(), desc: "open photo")
    willSelectItem(button: chatInputView.currentButton, index: showPhotoTag)
  }

  override open func showRtcCallAction() {
    let sessionId = viewModel.sessionId

    var param = [String: Any]()
    param["remoteUserAccid"] = sessionId
    param["currentUserAccid"] = IMKitClient.instance.account()
    param["remoteShowName"] = titleContent

    if let user = viewModel.getShowName(sessionId).user {
      param["remoteAvatar"] = user.user?.avatar
    }

    let videoCallAction = NECustomAlertAction(title: chatLocalizable("video_call")) {
      param["type"] = NSNumber(integerLiteral: 2)
      Router.shared.use(CallViewRouter, parameters: param)
    }

    let audioCallAction = NECustomAlertAction(title: chatLocalizable("audio_call")) {
      param["type"] = NSNumber(integerLiteral: 1)
      Router.shared.use(CallViewRouter, parameters: param)
    }

    showCustomActionSheet([videoCallAction, audioCallAction])
  }

  override func getUserSettingViewController() -> NEBaseUserSettingViewController {
    FunUserSettingViewController(userId: viewModel.sessionId)
  }

  override open func keyBoardWillShow(_ notification: Notification) {
    if chatInputView.chatInpuMode == .normal || chatInputView.chatInpuMode == .multipleSend {
      if viewModel.isReplying {
        normalOffset = -10
      } else {
        normalOffset = 30
      }
    }

    let keyboardRect = (notification
      .userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    currentKeyboardHeight = keyboardRect.height
    super.keyBoardWillShow(notification)
  }

  override open func keyBoardWillHide(_ notification: Notification) {
    if chatInputView.chatInpuMode == .normal || chatInputView.chatInpuMode == .multipleSend {
      if viewModel.isReplying {
        normalOffset = -30
      } else {
        normalOffset = 0
      }
    }

    currentKeyboardHeight = 0
    super.keyBoardWillHide(notification)
  }

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // Get the new view controller using segue.destination.
    // Pass the selected object to the new view controller.
  }

  open func holdToSpeak(gesture: UILongPressGestureRecognizer) {
    switch gesture.state {
    case .possible:

      break
    case .began:
      print("start show record audio view")
      if NEAuthManager.hasAudioAuthoriztion() {
        showRecordView()
      } else {
        weak var weakSelf = self
        NEAuthManager.requestAudioAuthorization { granted in
          if granted == false {
            DispatchQueue.main.async {
              weakSelf?.showSingleAlert(message: commonLocalizable("jump_microphone_setting")) {}
            }
          }
        }
      }
    case .changed:
      let location = gesture.location(in: view)
      if location.y < UIScreen.main.bounds.height - FunRecordAudioView.getGestureHeight() {
        recordView?.changeToCancelStyle()
      } else {
        recordView?.changeToNormalStyle()
      }
    case .ended:
      removeRecordView()
    case .cancelled:
      removeRecordView()
    case .failed:
      removeRecordView()
      break
    @unknown default:
      break
    }
  }

  override open func showTakePicture() {
    showCustomBottomVideoAction(self, false)
  }

  override open func showFileAction() {
    showCustomBottomFileAction(self)
  }

  open func showRecordView() {
    if recordView == nil {
      let recordAudio = FunRecordAudioView()
      recordAudio.delegate = self
      recordAudio.frame = UIScreen.main.bounds
      recordView = recordAudio
      UIApplication.shared.keyWindow?.addSubview(recordAudio)
    }
    startRecord()
  }

  open func removeRecordView() {
    if let record = recordView {
      if record.isRecordNormalStyle() {
        endRecord(insideView: true)
      } else {
        endRecord(insideView: false)
      }
    }
    recordView?.removeFromSuperview()
    recordView = nil
  }

  open func didEndRecord(view: FunRecordAudioView) {
    endRecord(insideView: true)
    view.removeFromSuperview()
    if let hodlToSpeakView = getFunInputView()?.holdToSpeakView {
      hodlToSpeakView.resignFirstResponder()
    }
  }

  func getFunInputView() -> FunChatInputView? {
    if let funInput = chatInputView as? FunChatInputView {
      return funInput
    }
    return nil
  }

  override open func setMutilSelectBottomView() {
    mutilSelectBottomView.backgroundColor = .white
    mutilSelectBottomView.buttonTopAnchor?.constant = 6
    mutilSelectBottomView.multiForwardButton.setImage(.ne_imageNamed(name: "fun_select_multiForward"), for: .normal)
    mutilSelectBottomView.multiForwardButton.setImage(.ne_imageNamed(name: "fun_unselect_multiForward"), for: .disabled)
    mutilSelectBottomView.singleForwardButton.setImage(.ne_imageNamed(name: "fun_select_singleForward"), for: .normal)
    mutilSelectBottomView.singleForwardButton.setImage(.ne_imageNamed(name: "fun_unselect_singleForward"), for: .disabled)
    mutilSelectBottomView.deleteButton.setImage(.ne_imageNamed(name: "fun_select_delete"), for: .normal)
    mutilSelectBottomView.deleteButton.setImage(.ne_imageNamed(name: "fun_unselect_delete"), for: .disabled)
    mutilSelectBottomView.setLabelColor(color: .funChatInputHoldspeakTextColor)
  }

  override open func closeReply(button: UIButton?) {
    viewModel.isReplying = false
    getFunInputView()?.hideReplyMode()
    getFunInputView()?.replyLabel.attributedText = nil
  }

  override open func showReplyMessageView(isReEdit: Bool = false) {
    viewModel.isReplying = true
    guard let replyView = getFunInputView() else { return }
    replyView.showReplyMode()
    if let message = viewModel.operationModel?.message {
      if isReEdit {
        replyView.replyLabel.attributedText = NEEmotionTool.getAttWithStr(str: viewModel.operationModel?.replyText ?? "",
                                                                          font: .systemFont(ofSize: 13),
                                                                          color: .ne_greyText)
        viewModel.getReplyMessageWithoutThread(message: message) { model in
          if let replyMessage = model as? MessageContentModel {
            self.viewModel.operationModel = replyMessage
          }
        }
      } else {
        var text = chatLocalizable("msg_reply")
        if let uid = message.senderId {
          var (showName, _) = ChatTeamCache.shared.getShowName(uid, false)
          if V2NIMConversationIdUtil.conversationType(viewModel.conversationId) != .CONVERSATION_TYPE_P2P,
             !IMKitClient.instance.isMe(uid) {
            addToAtUsers(addText: "@" + showName + "", isReply: true, accid: uid)
          }

          (showName, _) = ChatTeamCache.shared.getShowName(uid)
          text += " " + showName
          text += ": \(ChatMessageHelper.contentOfMessage(message))"
          getFunInputView()?.replyLabel.attributedText = NEEmotionTool.getAttWithStr(str: text,
                                                                                     font: .systemFont(ofSize: 13),
                                                                                     color: .ne_greyText)
        }
      }
      if chatInputView.textView.isFirstResponder {
        normalOffset = -10
        layoutInputView(offset: currentKeyboardHeight)
      } else {
        chatInputView.textView.becomeFirstResponder()
      }
    }
  }

  override open func getReadView(_ message: V2NIMMessage, _ teamId: String) -> NEBaseReadViewController {
    FunReadViewController(message: message, teamId: teamId)
  }

  override open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let model = viewModel.messages[indexPath.row]

    if let contentModel = model as? MessageContentModel {
      if contentModel.type == .revoke {
        if let time = contentModel.timeContent, !time.isEmpty {
          return 28 + chat_timeCellH
        }
        return 28
      }
    }

    return model.cellHeight()
  }

  open func getMessageModel(model: MessageModel) {
    if model.type == .tip || model.type == .notification {
      return
    }

    let contentWidth = model.contentSize.width
    let contentHeight = model.contentSize.height
    if contentHeight < 42 {
      let subHeight = 42 - contentHeight
      model.contentSize = CGSize(width: contentWidth, height: 42)
      model.offset = CGFloat(subHeight)
    }

    if model.type == .reply {
      model.offset += 44 + chat_content_margin
    }

    if model.type == .rtcCallRecord {
      model.contentSize = CGSize(width: contentWidth, height: contentHeight - 2)
      model.offset = -2
    }
  }

  override open func addToAtUsers(addText: String, isReply: Bool = false, accid: String, _ isLongPress: Bool = false) {
    if let isRecordMode = getFunInputView()?.isRecordMode(), isRecordMode {
      getFunInputView()?.hideRecordMode()
    }
    getFunInputView()?.hideRecordMode()
    super.addToAtUsers(addText: addText, isReply: isReply, accid: accid, isLongPress)
  }

  // MARK: NEMutilSelectBottomViewDelegate

  override open func multiForwardForward(_ depth: Int) {
    weak var weakSelf = self
    if IMKitClient.instance.getConfigCenter().teamEnable {
      let userAction = NECustomAlertAction(title: chatLocalizable("contact_user")) {
        weakSelf?.forwardMessageToUser(isMultiForward: true, depth: depth) {
          weakSelf?.cancelMutilSelect()
        }
      }

      let teamAction = NECustomAlertAction(title: chatLocalizable("team")) {
        weakSelf?.forwardMessageToTeam(isMultiForward: true, depth: depth) {
          weakSelf?.cancelMutilSelect()
        }
      }

      showCustomActionSheet([teamAction, userAction])
    } else {
      forwardMessageToUser(isMultiForward: true, depth: depth) {
        weakSelf?.cancelMutilSelect()
      }
    }
  }

  override open func singleForward() {
    weak var weakSelf = self
    if IMKitClient.instance.getConfigCenter().teamEnable {
      let userAction = NECustomAlertAction(title: chatLocalizable("contact_user")) {
        weakSelf?.forwardMessageToUser {
          weakSelf?.cancelMutilSelect()
        }
      }

      let teamAction = NECustomAlertAction(title: chatLocalizable("team")) {
        weakSelf?.forwardMessageToTeam {
          weakSelf?.cancelMutilSelect()
        }
      }

      showCustomActionSheet([teamAction, userAction])
    } else {
      forwardMessageToUser {
        weakSelf?.cancelMutilSelect()
      }
    }
  }

  override open func expandButtonDidClick() {
    super.expandButtonDidClick()
    print("expandButtonDidClick ")
    chatInputView.changeToMultipleLineStyle()
    normalInputHeight = 295
    bottomViewTopAnchor?.constant = -normalInputHeight
  }

  override open func didHideMultipleButtonClick() {
    super.didHideMultipleButtonClick()
    setInputValue()
    layoutInputViewWithAnimation(offset: 0)
  }

  override open func titleTextDidClearEmpty() {
    if chatInputView.chatInpuMode == .multipleSend {
      chatInputView.chatInpuMode = .normal
      setInputValue()
      chatInputView.restoreNormalInputStyle()
      chatInputView.textView.becomeFirstResponder()
      layoutInputViewWithAnimation(offset: currentKeyboardHeight)
    }
  }

  func setInputValue() {
    if chatInputView.chatInpuMode == .normal {
      normalInputHeight = 90
    } else if chatInputView.chatInpuMode == .multipleSend {
      normalInputHeight = 130
    }

    if viewModel.isReplying {
      normalOffset = -30
    } else {
      normalOffset = 0
    }
  }

  // 不隐藏键盘
  override open func didHideMultiple() {
    normalInputHeight = 90
    if currentKeyboardHeight > 0 {
      normalOffset = 30
    }
    layoutInputViewWithAnimation(offset: currentKeyboardHeight)
  }
}
