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

final class AdvancedSettingsCell: BasicTableViewCell {
    override func prepareForReuse() {
        super.prepareForReuse()

        titleTextField.text = nil
        valueLabel.text = nil
    }

    override open func addSubviewsAndConstraints() {
        accessoryType = .disclosureIndicator

        contentView.addSubview(titleTextField)
        contentView.addSubview(valueLabel)

        titleTextField.centerY(to: contentView)
        titleTextField.left(to: contentView, offset: BasicTableViewCell.horizontalMargin)

        valueLabel.centerY(to: contentView)
        valueLabel.leftToRight(of: titleTextField, offset: BasicTableViewCell.horizontalMargin)
        valueLabel.right(to: contentView, offset: -BasicTableViewCell.horizontalMargin)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }
}
