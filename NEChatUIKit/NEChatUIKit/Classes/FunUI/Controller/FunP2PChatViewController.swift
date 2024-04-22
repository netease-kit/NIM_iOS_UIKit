// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class FunP2PChatViewController: FunChatViewController {
  /// 重写父类的构造方法
  /// - Parameter conversationId: 会话id
  override public init(conversationId: String) {
    super.init(conversationId: conversationId)
    viewModel = P2PChatViewModel(conversationId: conversationId, anchor: nil)
  }

  /// 重写父类的构造方法
  /// - Parameter conversationId: 会话id
  /// - Parameter anchor: 锚点消息
  public init(conversationId: String, anchor: V2NIMMessage?) {
    super.init(conversationId: conversationId)
    viewModel = P2PChatViewModel(conversationId: conversationId, anchor: anchor)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override open var title: String? {
    didSet {
      super.title = title
      if let showName = title {
        let text = chatLocalizable("fun_chat_input_placeholder")
        let attribute = NSMutableAttributedString(string: text)
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        style.alignment = .left
        attribute.addAttribute(.font, value: UIFont.systemFont(ofSize: 16), range: NSMakeRange(0, text.utf16.count))
        attribute.addAttribute(.foregroundColor, value: UIColor.funChatInputViewPlaceholderTextColor, range: NSMakeRange(0, text.utf16.count))
        attribute.addAttribute(.paragraphStyle, value: style, range: NSMakeRange(0, text.utf16.count))
        chatInputView.textView.attributedPlaceholder = attribute
        chatInputView.textView.setNeedsLayout()
      }
    }
  }

  override open func getSessionInfo(sessionId: String, _ completion: @escaping () -> Void) {
    super.getSessionInfo(sessionId: sessionId) { [weak self] in
      self?.viewModel.loadShowName([sessionId]) {
        let name = self?.viewModel.getShowName(sessionId).name ?? sessionId
        self?.title = name
        self?.titleContent = name
      }
      completion()
    }
  }

  /// 重写检查并发送正在输入状态
  /// - Parameter endEdit: 是否停止输入
  override open func checkAndSendTypingState(endEdit: Bool = false) {
    guard let viewModel = viewModel as? P2PChatViewModel else {
      return
    }

    if endEdit {
      viewModel.sendInputTypingEndState()
      return
    }

    if chatInputView.chatInpuMode == .normal {
      if let content = chatInputView.textView.text, content.count > 0 {
        viewModel.sendInputTypingState()
      } else {
        viewModel.sendInputTypingEndState()
      }
    } else {
      var title = ""
      var content = ""

      if let titleText = chatInputView.titleField.text {
        title = titleText
      }

      if let contentText = chatInputView.textView.text {
        content = contentText
      }
      if title.count <= 0, content.count <= 0 {
        viewModel.sendInputTypingEndState()
      } else {
        viewModel.sendInputTypingState()
      }
    }
  }
}
