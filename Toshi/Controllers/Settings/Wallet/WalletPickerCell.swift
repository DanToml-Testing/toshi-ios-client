// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit

final class WalletPickerCell: BasicTableViewCell {
    
    override func addSubviewsAndConstraints() {
        contentView.addSubview(leftImageView)
        contentView.addSubview(titleTextField)
        contentView.addSubview(valueLabel)
        contentView.addSubview(checkmarkView)

        setupTitleTextField()
        setupLeftImageView()
        setupValueLabel()
        setupCheckmarkView()
    }

    private func setupTitleTextField() {
        titleTextField.centerY(to: contentView)
        titleTextField.leftToRight(of: leftImageView, offset: BasicTableViewCell.largeInterItemMargin)
        titleTextField.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    private func setupLeftImageView() {
        leftImageView.size(CGSize(width: BasicTableViewCell.imageSize, height: BasicTableViewCell.imageSize))
        leftImageView.centerY(to: contentView, priority: .defaultHigh)
        leftImageView.left(to: contentView, offset: BasicTableViewCell.horizontalMargin)
        leftImageView.top(to: contentView, offset: BasicTableViewCell.imageMargin, relation: .equalOrGreater)
        leftImageView.bottom(to: contentView, offset: -BasicTableViewCell.imageMargin, relation: .equalOrGreater)
    }

    private func setupValueLabel() {
        valueLabel.leftToRight(of: titleTextField, offset: BasicTableViewCell.horizontalMargin)
        valueLabel.top(to: contentView, offset: BasicTableViewCell.verticalMargin)
        valueLabel.rightToLeft(of: checkmarkView, offset: -BasicTableViewCell.horizontalMargin)
        valueLabel.bottom(to: contentView, offset: -BasicTableViewCell.verticalMargin)
        valueLabel.width(100)
    }

    private func setupCheckmarkView() {
        checkmarkView.centerY(to: contentView)
        checkmarkView.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin)
        checkmarkView.layer.borderColor = UIColor.red.cgColor
        checkmarkView.checked = false
    }
}
