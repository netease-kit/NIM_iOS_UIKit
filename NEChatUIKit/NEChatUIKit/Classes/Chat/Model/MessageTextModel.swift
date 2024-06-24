
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import Foundation
import NECommonKit
import NIMSDK

@objcMembers
open class MessageTextModel: MessageContentModel {
  public var attributeStr: NSMutableAttributedString?
  public var textHeight: CGFloat = 0

  public required init(message: NIMMessage?) {
    super.init(message: message)
    type = .text

    attributeStr = NEEmotionTool.getAttWithStr(
      str: message?.text ?? "",
      font: UIFont.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize)
    )

    if let remoteExt = message?.remoteExt, let dic = remoteExt[yxAtMsg] as? [String: AnyObject] {
      for (key, value) in dic {
        if let contentDic = value as? [String: AnyObject] {
          if let array = contentDic[atSegmentsKey] as? [AnyObject] {
            if let models = NSArray.yx_modelArray(with: MessageAtInfoModel.self, json: array) as? [MessageAtInfoModel] {
              for model in models {
                if attributeStr?.length ?? 0 > model.end {
                  attributeStr?.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.ne_blueText, range: NSMakeRange(model.start, model.end - model.start + atRangeOffset))
                }
              }
            }
          }
        }
      }
    }

    let textSize = attributeStr?.finalSize(.systemFont(ofSize: NEKitChatConfig.shared.ui.messageProperties.messageTextSize), CGSize(width: chat_text_maxW, height: CGFloat.greatestFiniteMagnitude)) ?? .zero

    textHeight = textSize.height
    contentSize = CGSize(width: textSize.width + chat_content_margin * 2, height: textHeight + chat_content_margin * 2)
    height = contentSize.height + chat_content_margin * 2 + fullNameHeight
  }
}
