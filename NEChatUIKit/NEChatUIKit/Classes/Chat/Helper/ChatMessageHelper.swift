
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import CommonCrypto
import Foundation
import NEChatKit
import NECommonKit
import NECoreIM2Kit
import NECoreKit
import NIMSDK

@objcMembers
public class ChatMessageHelper: NSObject {
  public static let repo = ChatRepo.shared

  /// 获取图片合适尺寸
  /// - Parameters:
  ///   - maxSize: 最大宽高
  ///   - size: 图片宽高
  ///   - miniWH: 最小宽高
  /// - Returns: 消息列表中展示的尺寸
  public class func getSizeWithMaxSize(_ maxSize: CGSize, size: CGSize,
                                       miniWH: CGFloat) -> CGSize {
    var realSize = CGSize.zero

    if min(size.width, size.height) > 0 {
      if size.width > size.height {
        // 宽大 按照宽给高
        let width = CGFloat(min(maxSize.width, size.width))
        realSize = CGSize(width: width, height: width * size.height / size.width)
        if realSize.height < miniWH {
          realSize.height = miniWH
        }
      } else {
        // 高大 按照高给宽
        let height = CGFloat(min(maxSize.height, size.height))
        realSize = CGSize(width: height * size.width / size.height, height: height)
        if realSize.width < miniWH {
          realSize.width = miniWH
        }
      }
    } else {
      realSize = maxSize
    }

    return realSize
  }

  /// 获取会话昵称
  /// - Parameters:
  ///   - conversationId: 会话 id
  ///   - showAlias: 是否优先显示备注
  /// - Returns: 会话昵称
  public static func getSessionName(conversationId: String, showAlias: Bool = true) -> String {
    guard let sessionId = V2NIMConversationIdUtil.conversationTargetId(conversationId) else {
      return ""
    }
    if V2NIMConversationIdUtil.conversationType(conversationId) == .CONVERSATION_TYPE_P2P {
      return NEFriendUserCache.shared.getShowName(sessionId).name
    } else {
      return ChatTeamCache.shared.getTeamInfo()?.name ?? ""
    }
  }

  // MARK: message

  /// 获取消息列表单元格注册列表
  /// - Parameter isFun: 是否是娱乐皮肤
  /// - Returns: 单元格注册列表
  public static func getChatCellRegisterDic(isFun: Bool) -> [String: UITableViewCell.Type] {
    [
      "\(MessageType.text.rawValue)":
        isFun ? FunChatMessageTextCell.self : ChatMessageTextCell.self,
      "\(MessageType.rtcCallRecord.rawValue)":
        isFun ? FunChatMessageCallCell.self : ChatMessageCallCell.self,
      "\(MessageType.audio.rawValue)":
        isFun ? FunChatMessageAudioCell.self : ChatMessageAudioCell.self,
      "\(MessageType.image.rawValue)":
        isFun ? FunChatMessageImageCell.self : ChatMessageImageCell.self,
      "\(MessageType.revoke.rawValue)":
        isFun ? FunChatMessageRevokeCell.self : ChatMessageRevokeCell.self,
      "\(MessageType.video.rawValue)":
        isFun ? FunChatMessageVideoCell.self : ChatMessageVideoCell.self,
      "\(MessageType.file.rawValue)":
        isFun ? FunChatMessageFileCell.self : ChatMessageFileCell.self,
      "\(MessageType.reply.rawValue)":
        isFun ? FunChatMessageReplyCell.self : ChatMessageReplyCell.self,
      "\(MessageType.location.rawValue)":
        isFun ? FunChatMessageLocationCell.self : ChatMessageLocationCell.self,
      "\(MessageType.time.rawValue)":
        isFun ? FunChatMessageTipCell.self : ChatMessageTipCell.self,
      "\(MessageType.multiForward.rawValue)":
        isFun ? FunChatMessageMultiForwardCell.self : ChatMessageMultiForwardCell.self,
      "\(MessageType.richText.rawValue)":
        isFun ? FunChatMessageRichTextCell.self : ChatMessageRichTextCell.self,
    ]
  }

  /// 获取标记列表单元格注册列表
  /// - Parameter isFun: 是否是娱乐皮肤
  /// - Returns: 单元格注册列表
  public static func getPinCellRegisterDic(isFun: Bool) -> [String: NEBasePinMessageCell.Type] {
    [
      "\(MessageType.text.rawValue)":
        isFun ? FunPinMessageTextCell.self : PinMessageTextCell.self,
      "\(MessageType.image.rawValue)":
        isFun ? FunPinMessageImageCell.self : PinMessageImageCell.self,
      "\(MessageType.audio.rawValue)":
        isFun ? FunPinMessageAudioCell.self : PinMessageAudioCell.self,
      "\(MessageType.video.rawValue)":
        isFun ? FunPinMessageVideoCell.self : PinMessageVideoCell.self,
      "\(MessageType.location.rawValue)":
        isFun ? FunPinMessageLocationCell.self : PinMessageLocationCell.self,
      "\(MessageType.file.rawValue)":
        isFun ? FunPinMessageFileCell.self : PinMessageFileCell.self,
      "\(MessageType.multiForward.rawValue)":
        isFun ? FunPinMessageMultiForwardCell.self : PinMessageMultiForwardCell.self,
      "\(MessageType.richText.rawValue)":
        isFun ? FunPinMessageRichTextCell.self : PinMessageRichTextCell.self,
      "\(NEBasePinMessageTextCell.self)":
        isFun ? FunPinMessageDefaultCell.self : PinMessageDefaultCell.self,
    ]
  }

  /// 构造消息体
  /// - Parameter message: 消息
  /// - Returns: 消息体
  public static func modelFromMessage(message: V2NIMMessage) -> MessageModel {
    var model: MessageModel
    switch message.messageType {
    case .MESSAGE_TYPE_VIDEO:
      model = MessageVideoModel(message: message)
    case .MESSAGE_TYPE_TEXT:
      model = MessageTextModel(message: message)
    case .MESSAGE_TYPE_IMAGE:
      model = MessageImageModel(message: message)
    case .MESSAGE_TYPE_AUDIO:
      model = MessageAudioModel(message: message)
    case .MESSAGE_TYPE_NOTIFICATION, .MESSAGE_TYPE_TIP:
      model = MessageTipsModel(message: message)
    case .MESSAGE_TYPE_FILE:
      model = MessageFileModel(message: message)
    case .MESSAGE_TYPE_LOCATION:
      model = MessageLocationModel(message: message)
    case .MESSAGE_TYPE_CALL:
      model = MessageCallRecordModel(message: message)
    case .MESSAGE_TYPE_CUSTOM:
      if let type = NECustomAttachment.typeOfCustomMessage(message.attachment) {
        if type == customMultiForwardType {
          return MessageCustomModel(message: message, contentHeight: Int(customMultiForwardCellHeight))
        }
        if type == customRichTextType {
          return MessageRichTextModel(message: message)
        }
      }
      fallthrough
    default:
      // 未识别的消息类型，默认为文本消息类型，text为未知消息体
      message.text = chatLocalizable("msg_unknown")
      model = MessageTextModel(message: message)
    }
    return model
  }

  /// 构造消息体
  /// - Parameters:
  ///   - message: 消息
  ///   - completion: 完成回调
  public static func modelFromMessage(message: V2NIMMessage, _ completion: @escaping (MessageModel) -> Void) {
    var model: MessageModel
    switch message.messageType {
    case .MESSAGE_TYPE_VIDEO:
      model = MessageVideoModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_TEXT:
      model = MessageTextModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_IMAGE:
      model = MessageImageModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_AUDIO:
      model = MessageAudioModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_NOTIFICATION, .MESSAGE_TYPE_TIP:
      // 查询通知消息中 targetId 的用户信息
      if message.messageType == .MESSAGE_TYPE_NOTIFICATION,
         let attach = message.attachment as? V2NIMMessageNotificationAttachment,
         var accIds = attach.targetIds {
        if let senderId = message.senderId {
          accIds.append(senderId)
        }

        if let conversationId = message.conversationId, let tid = V2NIMConversationIdUtil.conversationTargetId(conversationId) {
          ChatTeamCache.shared.loadShowName(userIds: accIds, teamId: tid) {
            completion(MessageTipsModel(message: message))
          }
        } else {
          completion(MessageTipsModel(message: message))
        }
      } else {
        completion(MessageTipsModel(message: message))
      }
    case .MESSAGE_TYPE_FILE:
      model = MessageFileModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_LOCATION:
      model = MessageLocationModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_CALL:
      model = MessageCallRecordModel(message: message)
      completion(model)
    case .MESSAGE_TYPE_CUSTOM:
      if let type = NECustomAttachment.typeOfCustomMessage(message.attachment) {
        if type == customMultiForwardType {
          completion(MessageCustomModel(message: message, contentHeight: Int(customMultiForwardCellHeight)))
          return
        }
        if type == customRichTextType {
          completion(MessageRichTextModel(message: message))
          return
        }
      }
      fallthrough
    default:
      // 未识别的消息类型，默认为文本消息类型，text为未知消息体
      message.text = chatLocalizable("msg_unknown")
      model = MessageTextModel(message: message)
      completion(model)
    }
  }

  /// 获取消息列表的中所以图片消息的 url
  /// - Parameter messages: 消息列表
  /// - Returns: 图片路径列表
  public static func getUrls(messages: [MessageModel]) -> [String] {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function)
    var urls = [String]()
    for model in messages {
      if model.type == .image, let message = model.message?.attachment as? V2NIMMessageImageAttachment {
        if let url = message.url {
          urls.append(url)
        } else {
          if let path = message.path, FileManager.default.fileExists(atPath: path) {
            urls.append(path)
          }
        }
      }
    }
    return urls
  }

  /// 为消息体添加时间
  /// - Parameters:
  ///   - model: 消息体
  ///   - lastModel: 最后一条消息
  static func addTimeMessage(_ model: MessageModel, _ lastModel: MessageModel?) {
    guard let message = model.message else {
      NEALog.errorLog(ModuleName + " " + className(), desc: #function + ", model.message is nil")
      return
    }

    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", messageId: \(String(describing: message.messageClientId))")
    if NotificationMessageUtils.isDiscussSeniorTeamNoti(message: message) {
      return
    }

    let lastTs = lastModel?.message?.createTime ?? 0.0
    let curTs = message.createTime
    let dur = curTs - lastTs
    if (dur / 60) > 5 {
      let timeText = String.stringFromDate(date: Date(timeIntervalSince1970: curTs))
      model.timeContent = timeText
    }
  }

  /// 获取消息外显文案
  /// - Parameter message: 消息
  /// - Returns: 外显文案
  public static func contentOfMessage(_ message: V2NIMMessage?) -> String {
    switch message?.messageType {
    case .MESSAGE_TYPE_TEXT:
      if let t = message?.text {
        return t
      } else {
        return chatLocalizable("message_not_found")
      }
    case .MESSAGE_TYPE_IMAGE:
      return chatLocalizable("msg_image")
    case .MESSAGE_TYPE_AUDIO:
      return chatLocalizable("msg_audio")
    case .MESSAGE_TYPE_VIDEO:
      return chatLocalizable("msg_video")
    case .MESSAGE_TYPE_FILE:
      return chatLocalizable("msg_file")
    case .MESSAGE_TYPE_LOCATION:
      return chatLocalizable("msg_location")
    case .MESSAGE_TYPE_CALL:
      if let attachment = message?.attachment as? V2NIMMessageCallAttachment {
        return attachment.type == 1 ? chatLocalizable("msg_rtc_audio") : chatLocalizable("msg_rtc_video")
      }
      return chatLocalizable("msg_rtc_call")
    case .MESSAGE_TYPE_CUSTOM:
      if let content = NECustomAttachment.contentOfRichText(message?.attachment) {
        return content
      }

      if let customType = NECustomAttachment.typeOfCustomMessage(message?.attachment),
         customType == customMultiForwardType {
        return "[\(chatLocalizable("chat_history"))]"
      }

      return chatLocalizable("msg_custom")
    default:
      return chatLocalizable("msg_unknown")
    }
  }

  /// 移除消息扩展字段中的 回复、@
  /// - Parameter forwardMessage: 消息
  public static func clearForwardAtMark(_ forwardMessage: V2NIMMessage) {
    guard var remoteExt = getDictionaryFromJSONString(forwardMessage.serverExtension ?? "") as? [String: Any] else { return }
    remoteExt.removeValue(forKey: yxAtMsg)
    remoteExt.removeValue(forKey: keyReplyMsgKey)
    if remoteExt.count <= 0 {
      remoteExt = [:]
    }
    forwardMessage.serverExtension = getJSONStringFromDictionary(remoteExt)
  }

  /// 构建合并转发消息附件的 header
  /// - Parameters:
  ///   - messageCount: 消息数量
  ///   - completion: 完成回调
  public static func buildHeader(messageCount: Int) -> String {
    var dic = [String: Any]()
    dic["version"] = 0 // 功能版本
    dic["terminal"] = 2 // iOS
    //    dic["sdk_version"] = IMKitClient.instance.sdkVersion()
    //    dic["app_version"] = imkitVersion
    dic["message_count"] = messageCount // 转发消息数量

    return getJSONStringFromDictionary(dic)
  }

  /// 构建合并转发消息附件的 body
  /// - Parameters:
  ///   - messages: 消息
  ///   - completion: 完成回调
  public static func buildBody(messages: [V2NIMMessage],
                               _ completion: @escaping (String, [[String: Any]]) -> Void) {
    let enter = "\n" // 分隔符
    var body = "" // 序列化结果
    var abstracts = [[String: Any]]() // 摘要信息

    for (i, msg) in messages.enumerated() {
      // 移除扩展字段中的 回复、@ 信息
      let remoteExt = msg.serverExtension
      clearForwardAtMark(msg)

      // 保存消息昵称和头像
      if let from = msg.senderId {
        let user = ChatTeamCache.shared.getTeamMemberInfo(accountId: from)?.nimUser ?? NEFriendUserCache.shared.getFriendInfo(from) ?? ChatUserCache.shared.getUserInfo(from)
        if let user = user {
          let senderNick = user.showNameWithAliasControl(false)
          if var remoteExt = getDictionaryFromJSONString(msg.serverExtension ?? "") as? [String: Any] {
            remoteExt[mergedMessageNickKey] = senderNick
            remoteExt[mergedMessageAvatarKey] = user.user?.avatar ?? getShortName(senderNick ?? "")
            msg.serverExtension = getJSONStringFromDictionary(remoteExt)
          } else {
            let remoteExt = [mergedMessageNickKey: senderNick as Any,
                             mergedMessageAvatarKey: user.user?.avatar as Any]
            msg.serverExtension = getJSONStringFromDictionary(remoteExt)
          }

          // 摘要信息
          if i < 3 {
            let content = ChatMessageHelper.contentOfMessage(msg)
            abstracts.append(["senderNick": senderNick as Any,
                              "content": content,
                              "userAccId": from])
          }
        }
        if let stringData = ChatRepo.shared.messageSerialization(msg) {
          body.append(enter + stringData)
        }
      }

      // 恢复扩展字段中的 回复、@ 信息
      msg.serverExtension = remoteExt
    }

    completion(body, abstracts)
  }

  /// 获取消息的客户端本地扩展信息（转换为[String: Any]）
  /// - Parameter message: 消息
  /// - Returns: 客户端本地扩展信息
  public static func getMessageLocalExtension(message: V2NIMMessage) -> [String: Any]? {
    guard let localExtension = message.localExtension else { return nil }

    if let localExt = getDictionaryFromJSONString(localExtension) as? [String: Any] {
      return localExt
    }
    return nil
  }

  /// 判断消息是否已撤回
  /// - Parameter message: 消息
  /// - Returns: 是否已撤回
  public static func isRevokeMessage(message: V2NIMMessage?) -> Bool {
    guard let message = message else { return false }

    if let localExt = getMessageLocalExtension(message: message),
       let isRevoke = localExt[revokeLocalMessage] as? Bool, isRevoke == true {
      return true
    }
    return false
  }

  /// 获取消息撤回前的内容（用于重新编辑）
  /// - Parameter message: 消息
  /// - Returns: 撤回前的内容
  public static func getRevokeMessageContent(message: V2NIMMessage?) -> String? {
    guard let message = message else { return nil }

    if let localExt = getMessageLocalExtension(message: message) {
      if let content = localExt[revokeLocalMessageContent] as? String {
        return content
      }
    }
    return nil
  }

  /// 查找回复信息键值对
  /// - Parameter message: 消息
  /// - Returns: 回复消息的 id
  public static func getReplyDictionary(message: V2NIMMessage) -> [String: Any]? {
    if let remoteExt = getDictionaryFromJSONString(message.serverExtension ?? ""),
       let yxReplyMsg = remoteExt[keyReplyMsgKey] as? [String: Any] {
      return yxReplyMsg
    }

    return nil
  }

  ///    全名后几位
  public static func getShortName(_ name: String, _ length: Int = 2) -> String {
    NEALog.infoLog(ModuleName + " " + className(), desc: #function + ", name: " + name)
    return name
      .count > length ? String(name[name.index(name.endIndex, offsetBy: -length)...]) : name
  }

  /// 获取文件 MD5 值
  /// - Parameter fileURL: 文件 URL
  /// - Returns: md5 值
  public static func getFileChecksum(fileURL: URL) -> String? {
    // 打开文件，创建文件句柄
    let file = FileHandle(forReadingAtPath: fileURL.path)
    guard file != nil else { return nil }

    // 创建 CC_MD5_CTX 上下文对象
    var context = CC_MD5_CTX()
    CC_MD5_Init(&context)

    // 读取文件数据并更新上下文对象
    while autoreleasepool(invoking: {
      let data = file?.readData(ofLength: 1024)
      if data?.count == 0 {
        return false
      }
      data?.withUnsafeBytes { buffer in
        CC_MD5_Update(&context, buffer.baseAddress, CC_LONG(buffer.count))
      }
      return true
    }) {}

    // 计算 MD5 值并关闭文件
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    CC_MD5_Final(&digest, &context)
    file?.closeFile()

    // 将 MD5 值转换为字符串格式
    let md5String = digest.map { String(format: "%02hhx", $0) }.joined()
    return md5String
  }

  /// 构造消息附件的本地文件路径
  /// - Parameter message: 消息
  /// - Returns: 本地文件路径
  public static func createFilePath(_ message: V2NIMMessage?) -> String {
    var path = NEPathUtils.getDirectoryForDocuments(dir: "NEIMUIKit") ?? ""
    guard let attach = message?.attachment as? V2NIMMessageFileAttachment else {
      return path
    }

    switch message?.messageType {
    case .MESSAGE_TYPE_AUDIO:
      path = NEPathUtils.getDirectoryForDocuments(dir: "NEIMUIKit/audio/") ?? ""
    case .MESSAGE_TYPE_IMAGE:
      path = NEPathUtils.getDirectoryForDocuments(dir: "NEIMUIKit/image/") ?? ""
    case .MESSAGE_TYPE_VIDEO:
      path = NEPathUtils.getDirectoryForDocuments(dir: "NEIMUIKit/video/") ?? ""
    default:
      path = NEPathUtils.getDirectoryForDocuments(dir: "NEIMUIKit/file/") ?? ""
    }

    if let messageClientId = message?.messageClientId {
      path += messageClientId
    }

    // 后缀（例如：.png）
    if let ext = attach.ext {
      path += ext
    }

    return path
  }
}
