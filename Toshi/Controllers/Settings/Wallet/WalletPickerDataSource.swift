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

final class WalletPickerDataSource: NSObject {

    var selectedWallet: Wallet? {
        guard let index = indexPathForSelectedWallet?.row, wallets.count > index  else { return nil }
        return wallets[index]
    }

    private var tableView: UITableView
    private var wallets = [Wallet]()
    private var indexPathForSelectedWallet: IndexPath? {
        didSet {
            tableView.reloadData()
        }
    }

    init(tableView: UITableView) {
        self.tableView = tableView

        super.init()

        self.tableView.dataSource = self
        self.tableView.delegate = self

        //TODO: implement getting the actual wallets of the user
        self.wallets = [
            Wallet(name: "Wallet1", address: "0xf1c76a75d8b3175fr8", imagePath: "https://bakkenbaeck.com/images/team/marijn.096ca0b8ab.jpg"),
            Wallet(name: "Wallet2", address: "0xf3a65c12d8d3175fr8", imagePath: "https://bakkenbaeck.com/images/team/ellen.2454e06760.jpg"),
            Wallet(name: "Wallet3", address: "0xf7b76a75d8b3175fr8", imagePath: "https://bakkenbaeck.com/images/team/yulia.dfc4e6cba7.jpg"),
            Wallet(name: "Wallet4", address: "0xf353ca75d8b3175fr8", imagePath: "https://bakkenbaeck.com/images/team/mark.f73a421a3e.jpg")]
    }
}

extension WalletPickerDataSource: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let wallet = wallets[indexPath.row]

        let configurator = WalletPickerCellConfigurator()

        guard let cell = tableView.dequeueReusableCell(withIdentifier: WalletPickerCell.reuseIdentifier, for: indexPath) as? WalletPickerCell else { fatalError("Unexpected cell") }

        configurator.configureCell(cell, withWallet: wallet)
        cell.checkmarkView.checked = indexPathForSelectedWallet == indexPath

        return cell
    }
}

extension WalletPickerDataSource: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        indexPathForSelectedWallet = indexPath
    }
}

struct Wallet {
    let name: String
    let address: String
    let imagePath: String
}
