
// Copyright (c) 2022 NetEase, Inc. All rights reserved.
// Use of this source code is governed by a MIT license that can be
// found in the LICENSE file.

import UIKit

class QChatTimeTableViewCell: UITableViewCell {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    contentView.addSubview(timeLabel)
    NSLayoutConstraint.activate([
      timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
      timeLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor),
      timeLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor),
      timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public var messageFrame: QChatMessageFrame? {
    didSet {
      timeLabel.text = messageFrame?.time
    }
  }

  private lazy var timeLabel: UILabel = {
    let label = UILabel()
    label.font = DefaultTextFont(12)
    label.textColor = UIColor.ne_emptyTitleColor
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
}
