
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NIMSDK

@objcMembers
open class MessageRichTextModel: MessageTextModel {
  public var titleAttributeStr: NSMutableAttributedString?
  public var titleTextHeight: CGFloat = 0

  public required init(message: V2NIMMessage?) {
    guard let data = NECustomAttachment.dataOfCustomMessage(message?.attachment),
          let title = data["title"] as? String else {
      super.init(message: message)
      return
    }

    let body = (data["body"] as? String) ?? ""
    message?.text = body
    super.init(message: message)
    type = .custom

    let font = UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize, weight: .semibold)
    titleAttributeStr = NEEmotionTool.getAttWithStr(
      str: title,
      font: font
    )

    let textSize = NSAttributedString.getRealSize(titleAttributeStr, messageTextFont, messageMaxSize)
    titleTextHeight = textSize.height
    contentSize = CGSize(width: max(textWidght, textSize.width) + chat_content_margin * 2,
                         height: contentSize.height + titleTextHeight +
                           (body.isEmpty ? 0 : chat_content_margin))
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight + chat_pin_height
  }
}
