
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class ChatMessageRichTextCell: ChatMessageReplyCell {
  public lazy var titleLabelLeft: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEnabled = false
    label.numberOfLines = 0
    label.isUserInteractionEnabled = false
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize, weight: .semibold)
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.messageTitle"
    return label
  }()

  public lazy var titleLabelRight: UILabel = {
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.isEnabled = false
    label.numberOfLines = 0
    label.isUserInteractionEnabled = false
    label.font = .systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize, weight: .semibold)
    label.backgroundColor = .clear
    label.accessibilityIdentifier = "id.messageTitle"
    return label
  }()

  public var replyLabelLeftHeightAnchor: NSLayoutConstraint?
  public var replyLabelRightHeightAnchor: NSLayoutConstraint?
  public var titleLabelLeftTopAnchor: NSLayoutConstraint?
  public var titleLabelLeftHeightAnchor: NSLayoutConstraint?
  public var titleLabelRightTopAnchor: NSLayoutConstraint?
  public var titleLabelRightHeightAnchor: NSLayoutConstraint?
  public var contentLabelLeftHeightAnchor: NSLayoutConstraint?
  public var contentLabelRightHeightAnchor: NSLayoutConstraint?

  override open func commonUI() {
    /// left
    bubbleImageLeft.addSubview(replyLabelLeft)
    replyLabelLeftHeightAnchor = replyLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    replyLabelLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyLabelLeft.leadingAnchor.constraint(equalTo: bubbleImageLeft.leadingAnchor, constant: chat_content_margin),
      replyLabelLeft.topAnchor.constraint(equalTo: bubbleImageLeft.topAnchor, constant: chat_content_margin),
      replyLabelLeft.trailingAnchor.constraint(equalTo: bubbleImageLeft.trailingAnchor, constant: -chat_content_margin),
    ])

    bubbleImageLeft.addSubview(titleLabelLeft)
    titleLabelLeftTopAnchor = titleLabelLeft.topAnchor.constraint(equalTo: replyLabelLeft.bottomAnchor, constant: chat_content_margin)
    titleLabelLeftTopAnchor?.isActive = true
    titleLabelLeftHeightAnchor = titleLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    titleLabelLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleLabelLeft.rightAnchor.constraint(equalTo: bubbleImageLeft.rightAnchor, constant: -chat_content_margin),
      titleLabelLeft.leftAnchor.constraint(equalTo: bubbleImageLeft.leftAnchor, constant: chat_content_margin),
    ])

    bubbleImageLeft.addSubview(contentLabelLeft)
    contentLabelLeftHeightAnchor = contentLabelLeft.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelLeftHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabelLeft.rightAnchor.constraint(equalTo: titleLabelLeft.rightAnchor, constant: 0),
      contentLabelLeft.leftAnchor.constraint(equalTo: titleLabelLeft.leftAnchor, constant: 0),
      contentLabelLeft.topAnchor.constraint(equalTo: titleLabelLeft.bottomAnchor, constant: chat_content_margin),
    ])

    /// right
    bubbleImageRight.addSubview(replyLabelRight)
    replyLabelRightHeightAnchor = replyLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    replyLabelRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      replyLabelRight.leadingAnchor.constraint(equalTo: bubbleImageRight.leadingAnchor, constant: chat_content_margin),
      replyLabelRight.topAnchor.constraint(equalTo: bubbleImageRight.topAnchor, constant: chat_content_margin),
      replyLabelRight.trailingAnchor.constraint(equalTo: bubbleImageRight.trailingAnchor, constant: -chat_content_margin),
    ])

    bubbleImageRight.addSubview(titleLabelRight)
    titleLabelRightTopAnchor = titleLabelRight.topAnchor.constraint(equalTo: replyLabelRight.bottomAnchor, constant: chat_content_margin)
    titleLabelRightTopAnchor?.isActive = true
    titleLabelRightHeightAnchor = titleLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    titleLabelRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      titleLabelRight.rightAnchor.constraint(equalTo: bubbleImageRight.rightAnchor, constant: -chat_content_margin),
      titleLabelRight.leftAnchor.constraint(equalTo: bubbleImageRight.leftAnchor, constant: chat_content_margin),
    ])

    bubbleImageRight.addSubview(contentLabelRight)
    contentLabelRightHeightAnchor = contentLabelRight.heightAnchor.constraint(equalToConstant: CGFloat.greatestFiniteMagnitude)
    contentLabelRightHeightAnchor?.isActive = true
    NSLayoutConstraint.activate([
      contentLabelRight.rightAnchor.constraint(equalTo: titleLabelRight.rightAnchor, constant: -0),
      contentLabelRight.leftAnchor.constraint(equalTo: titleLabelRight.leftAnchor, constant: 0),
      contentLabelRight.topAnchor.constraint(equalTo: titleLabelRight.bottomAnchor, constant: chat_content_margin),
    ])
  }

  override open func showLeftOrRight(showRight: Bool) {
    super.showLeftOrRight(showRight: showRight)
    titleLabelLeft.isHidden = showRight
    titleLabelRight.isHidden = !showRight
  }

  override open func setModel(_ model: MessageContentModel, _ isSend: Bool) {
    super.setModel(model, isSend)
    let replyLabelHeightAnchor = isSend ? replyLabelRightHeightAnchor : replyLabelLeftHeightAnchor
    let titleLabel = isSend ? titleLabelRight : titleLabelLeft
    let titleLabelTopAnchor = isSend ? titleLabelRightTopAnchor : titleLabelLeftTopAnchor
    let titleLabelHeightAnchor = isSend ? titleLabelRightHeightAnchor : titleLabelLeftHeightAnchor
    let contentLabelHeightAnchor = isSend ? contentLabelRightHeightAnchor : contentLabelLeftHeightAnchor

    if model.replyText == nil || model.replyText!.isEmpty {
      replyLabelHeightAnchor?.constant = 0
      titleLabelTopAnchor?.constant = 0
    } else {
      replyLabelHeightAnchor?.constant = 16
      titleLabelTopAnchor?.constant = chat_content_margin
    }

    if let m = model as? MessageTextModel {
      contentLabelHeightAnchor?.constant = m.textHeight
    }

    if let m = model as? MessageRichTextModel {
      titleLabel.attributedText = m.titleAttributeStr
      titleLabelHeightAnchor?.constant = m.titleTextHeight
    }
  }
}
