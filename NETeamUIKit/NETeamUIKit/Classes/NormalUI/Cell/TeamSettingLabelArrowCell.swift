//// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

@objcMembers
open class TeamSettingLabelArrowCell: TeamArrowSettingCell {
  let arrowLabel: UILabel = {
    let q = UILabel()
    q.translatesAutoresizingMaskIntoConstraints = false
    q.textColor = .ne_lightText
    q.font = UIFont.systemFont(ofSize: 16)
    q.textAlignment = .right
    return q
  }()

  override open func setupUI() {
    super.setupUI()
    contentView.addSubview(arrowLabel)
    NSLayoutConstraint.activate([
      arrowLabel.centerYAnchor.constraint(equalTo: arrowView.centerYAnchor),
      arrowLabel.rightAnchor.constraint(equalTo: arrowView.leftAnchor, constant: -4),
    ])
  }

  override open func configure(_ anyModel: Any) {
    super.configure(anyModel)
    if let model = anyModel as? SettingCellLabelArrowModel {
      arrowLabel.text = model.arrowLabelText
    }
  }
}
