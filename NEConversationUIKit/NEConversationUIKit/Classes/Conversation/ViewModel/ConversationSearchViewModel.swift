// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import NEChatKit
import NIMSDK
import UIKit

@objcMembers
open class ConversationSearchViewModel: NSObject, NETeamListener, NEContactListener {
  let conversationRepo = ConversationRepo.shared

  /// 群数据缓存
  var teamDic = [String: ConversationSearchListModel]()
  /// 好友数据缓存
  var friendDic = [String: ConversationSearchListModel]()
  /// 好友搜索结果
  var friendDatas = [ConversationSearchListModel]()
  /// 讨论组搜索结果
  var discussionDatas = [ConversationSearchListModel]()
  /// 高级群搜索结果
  var seniorDatas = [ConversationSearchListModel]()

  private let className = "ConversationSearchViewModel"

  override public init() {
    super.init()
    ContactRepo.shared.addContactListener(self)
    TeamRepo.shared.addTeamListener(self)

    weak var weakSelf = self
    getSearchData {
      NEALog.infoLog(ModuleName + " " + (weakSelf?.className() ?? ""), desc: "get data finish")
      print("get data finish")
    }
  }

  deinit {
    ContactRepo.shared.removeContactListener(self)
    TeamRepo.shared.removeTeamListener(self)
  }

  /// 搜索
  /// - Parameter searchText: 搜索文案
  /// - Parameter completion: 完成回调
  open func doSearch(_ searchText: String?, _ completion: @escaping () -> Void) {
    NEALog.infoLog(
      ModuleName + " " + className,
      desc: #function + ", searchTexty: \(searchText ?? "")"
    )

    friendDatas.removeAll()
    discussionDatas.removeAll()
    seniorDatas.removeAll()

    guard let search = searchText else {
      completion()
      return
    }
    for (_, value) in friendDic {
      if let user = value.userInfo {
        if user.showName()?.contains(search) == true {
          friendDatas.append(value)
        } else if user.user?.accountId?.contains(search) == true {
          friendDatas.append(value)
        }
      }
    }
    for (_, value) in teamDic {
      if let showName = value.team?.getShowName() {
        if showName.contains(search) == true {
          if let serverExtension = value.team?.serverExtension, serverExtension.contains(discussTeamKey) == true {
            discussionDatas.append(value)
          } else {
            seniorDatas.append(value)
          }
        }
      }
    }
    friendDatas.sort()
    discussionDatas.sort()
    seniorDatas.sort()
    completion()
  }

  /// 获取所有数据
  /// - Parameter completion: 完成回调
  func getSearchData(_ completion: @escaping () -> Void) {
    let workingGroup = DispatchGroup()
    let workingQueue = DispatchQueue(label: "get_search_data_queue")
    weak var weakSelf = self
    workingGroup.enter()
    workingQueue.async {
      let userFriends = NEFriendUserCache.shared.getFriendListNotInBlocklist()
      for (uid, userFriend) in userFriends {
        let model = ConversationSearchListModel()
        model.userInfo = userFriend
        weakSelf?.friendDic[uid] = model
      }
    }

    workingGroup.enter()
    workingQueue.async {
      TeamRepo.shared.getTeamList { teams, error in
        teams?.forEach { team in
          if let tid = team.v2Team?.teamId {
            let model = ConversationSearchListModel()
            model.team = team.v2Team
            weakSelf?.teamDic[tid] = model
          }
        }
        workingGroup.leave()
      }
    }

    workingGroup.notify(queue: workingQueue) {
      DispatchQueue.main.async {
        completion()
      }
    }
  }

  // MARK: - NEContactListener

  /// 好友信息更新
  /// - Parameter friendInfo: 好友信息
  public func onFriendInfoChanged(_ friendInfo: V2NIMFriend) {
    if let uid = friendInfo.accountId {
      ContactRepo.shared.getFriendInfoList(accountIds: [uid]) { [weak self] u, error in
        if let user = u?.first {
          let model = ConversationSearchListModel()
          model.userInfo = user
          self?.friendDic[uid] = model
        }
      }
    }
  }

  // MARK: - V2NIMTeamListener

  /// 群信息更新回调
  /// - Parameter team: 群
  public func onTeamInfoUpdated(_ team: V2NIMTeam) {
    if let model = teamDic[team.teamId] {
      model.team = team
    } else {
      addTeam(team)
    }
  }

  /// 加入群回调
  /// - Parameters:
  ///   - team: 群
  public func onTeamJoined(_ team: V2NIMTeam) {
    addTeam(team)
  }

  /// 创建群回调
  /// - Parameter team: 群
  public func onTeamCreated(_ team: V2NIMTeam) {
    addTeam(team)
  }

  /// 群解散回调
  /// - Parameter team: 群
  public func onTeamDismissed(_ team: V2NIMTeam) {
    removeTeam(team)
  }

  /// 退出群回调
  /// - Parameters:
  ///   - team: 群
  ///   - isKicked: 是否被踢
  public func onTeamLeft(_ team: V2NIMTeam, isKicked: Bool) {
    removeTeam(team)
  }

  /// 移除群
  /// - Parameter team: 群
  private func removeTeam(_ team: V2NIMTeam) {
    teamDic.removeValue(forKey: team.teamId)
  }

  /// 添加群
  /// - Parameter team: 群
  private func addTeam(_ team: V2NIMTeam) {
    let model = ConversationSearchListModel()
    model.team = team
    teamDic[team.teamId] = model
  }
}
