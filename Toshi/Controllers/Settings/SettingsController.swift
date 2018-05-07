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
import SweetUIKit

class SettingsController: UIViewController {
    static var headerHeight: CGFloat = 38.0
    static var footerHeight: CGFloat = 20.0

    enum SettingsSection: Int {
        case profile
        case security
        case advanced
        case other

        var items: [SettingsItem] {
            switch self {
            case .profile:
                return [.profile]
            case .security:
                return [.security]
            case .advanced:
                return [.wallet, .network]
            case .other:
                return [.localCurrency, .about, .signOut]
            }
        }

        var headerTitle: String? {
            switch self {
            case .profile:
                return Localized.settings_header_profile
            case .security:
                return Localized.settings_header_security
            case .advanced:
                return Localized.settings_header_advanced
            case .other:
                return Localized.settings_header_other
            }
        }

        var footerTitle: String? {
            switch self {
            case .other:
                return SettingsSection.appVersionString
            default:
                return nil
            }
        }

        private static var appVersionString: String {
            let info = Bundle.main.infoDictionary!
            let version = info["CFBundleShortVersionString"]
            let buildNumber = info["CFBundleVersion"]

            return "App version: \(version ?? "").\(buildNumber ?? "")"
        }
    }

    enum SettingsItem: Int {
        case profile, security, wallet, network, localCurrency, about, signOut
    }

    private var ethereumAPIClient: EthereumAPIClient {
        return EthereumAPIClient.shared
    }

    private var chatAPIClient: ChatAPIClient {
        return ChatAPIClient.shared
    }

    private var idAPIClient: IDAPIClient {
        return IDAPIClient.shared
    }

    private var isAccountSecured: Bool {
        return Profile.current?.verified ?? false
    }

    private let sections: [SettingsSection] = [.profile, .security, .advanced, .other]

    private lazy var tableView: UITableView = {

        let view = UITableView(frame: self.view.frame, style: .grouped)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.allowsSelection = true
        view.estimatedRowHeight = 64.0
        view.dataSource = self
        view.delegate = self
        view.tableFooterView = UIView()
        view.preservesSuperviewLayoutMargins = true

        view.register(UITableViewCell.self)
        view.register(AdvancedSettingsCell.self)
        view.register(SecuritySettingsCell.self)

        return view
    }()

    static func instantiateFromNib() -> SettingsController {
        guard let settingsController = UIStoryboard(name: "Settings", bundle: nil).instantiateInitialViewController() as? SettingsController else { fatalError("Storyboard named 'Settings' should be provided in application") }

        return  settingsController
    }

    private override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localized.settings_navigation_title

        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        tableView.backgroundColor = Theme.lightGrayBackgroundColor

        tableView.registerNib(SettingsProfileCell.self)

        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .currentUserUpdated, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        IDAPIClient.shared.updateContact(with: Cereal.shared.address)

        preferLargeTitleIfPossible(true)
    }

    @objc private func updateUI() {
        self.tableView.reloadData()
    }

    private func handleSignOut() {
        guard let currentUser = Profile.current else {
            let alert = UIAlertController(title: Localized.settings_signout_error_title, message: Localized.settings_signout_error_message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localized.settings_signout_action_ok, style: .default, handler: { _ in
                fatalError()
            }))
            Navigator.presentModally(alert)

            return
        }

        let alert = self.alertController(balance: currentUser.balance)
        // We dispatch it back to the main thread here, even tho we are already inside the main thread
        // to avoid some weird issue where the alert controller will take seconds to present, instead of being instant.
        DispatchQueue.main.async {
            Navigator.presentModally(alert)
        }
    }

    func alertController(balance: NSDecimalNumber) -> UIAlertController {
        var alert: UIAlertController

        if self.isAccountSecured {
            alert = UIAlertController(title: Localized.settings_signout_insecure_title, message: Localized.settings_signout_insecure_message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localized.cancel_action_title, style: .cancel))

            alert.addAction(UIAlertAction(title: Localized.settings_signout_action_signout, style: .destructive) { _ in
                SessionManager.shared.signOutUser()
            })
        } else if balance == .zero {
            alert = UIAlertController(title: Localized.settings_signout_nofunds_title, message: Localized.settings_signout_nofunds_message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localized.cancel_action_title, style: .cancel))

            alert.addAction(UIAlertAction(title: Localized.settings_signout_action_delete, style: .destructive) { _ in
                SessionManager.shared.signOutUser()
            })
        } else {
            alert = UIAlertController(title: Localized.settings_signout_stepsneeded_title, message: Localized.settings_signout_stepsneeded_message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localized.settings_signout_action_ok, style: .cancel))
        }

        alert.view.tintColor = Theme.tintColor

        return alert
    }
}

extension SettingsController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell: UITableViewCell

        let section = sections[indexPath.section]

        switch section {
        case .profile:
            cell = cellForProfileSectionAt(indexPath: indexPath)
        case .security:
            cell = cellForSecuritySectionAt(indexPath: indexPath)
        case .advanced:
            cell = cellForAdvancedSectionAt(indexPath: indexPath)
        case .other:
            cell = cellForOtherSectionAt(indexPath: indexPath)
        }

        cell.isAccessibilityElement = true
        
        return cell
    }

    private func cellForProfileSectionAt(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(SettingsProfileCell.self, for: indexPath)
        guard let currentUserProfile = Profile.current else { return cell}

        cell.displayNameLabel.text = currentUserProfile.name
        cell.usernameLabel.text = currentUserProfile.displayUsername

        guard let avatarPath = currentUserProfile.avatar else { return cell }
        AvatarManager.shared.avatar(for: avatarPath) { image, _ in
            cell.avatarImageView.image = image
        }

        return cell
    }

    private func cellForSecuritySectionAt(indexPath: IndexPath) -> UITableViewCell {
        let securityCellConfigurator = SecuritySettingsCellConfigurator()
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SecuritySettingsCell.reuseIdentifier, for: indexPath)as? SecuritySettingsCell else { return UITableViewCell() }

        securityCellConfigurator.configureCell(cell, withTitle: Localized.settings_cell_passphrase, checked: isAccountSecured)

        return cell
    }

    private func cellForAdvancedSectionAt(indexPath: IndexPath) -> UITableViewCell {
        let item = SettingsSection.advanced.items[indexPath.row]

        let walletCellConfigurator = AdvancedSettingsCellConfigurator()
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AdvancedSettingsCell.reuseIdentifier, for: indexPath)as? AdvancedSettingsCell else { return UITableViewCell() }

        switch item {
        case .wallet:
            //TODO: Implement real selected wallet cell name
            walletCellConfigurator.configureCell(cell, withTitle: Localized.settings_cell_wallet, value: "Wallet 1")
        case .network:
            walletCellConfigurator.configureCell(cell, withTitle: Localized.settings_cell_network, value: NetworkSwitcher.shared.activeNetwork.label)
        default:
            break
        }

        return cell
    }

    private func cellForOtherSectionAt(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(UITableViewCell.self, for: indexPath)
        cell.textLabel?.textColor = Theme.darkTextColor
        cell.textLabel?.font = Theme.preferredRegular()

        let item = SettingsSection.other.items[indexPath.row]

        switch item {
        case .localCurrency:
            cell.textLabel?.text = Localized.settings_cell_local_currency
            cell.accessoryType = .disclosureIndicator
        case .about:
            cell.textLabel?.text = Localized.settings_cell_about
            cell.accessoryType = .disclosureIndicator
        case .signOut:
            cell.textLabel?.text = Localized.settings_cell_signout
            cell.textLabel?.textColor = Theme.errorColor
            cell.accessoryType = .none
        default:
            break
        }

        cell.isAccessibilityElement = true
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = sections[section]
        return sectionInfo.items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

extension SettingsController: UITableViewDelegate {

    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let sectionInfo = sections[indexPath.section]
        let item = sectionInfo.items[indexPath.row]

        switch item {
        case .profile:
            guard let current = Profile.current else { return }
            let profileVC = ProfileViewController(profile: current, readOnlyMode: false)

            self.navigationController?.pushViewController(profileVC, animated: true)
        case .security:
            self.navigationController?.pushViewController(PassphraseEnableController(), animated: true)
        case .wallet:
            self.navigationController?.pushViewController(WalletPickerController(), animated: true)
        case .network:
            navigationController?.pushViewController(NetworkSettingsController(), animated: true)
        case .localCurrency:
            self.navigationController?.pushViewController(CurrencyPicker(), animated: true)
        case .about:
            //TODO: implement about ViewController when design is ready
            DLog("push about ViewController")
        case .signOut:
            self.handleSignOut()
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionItem = sections[section]

        switch sectionItem {
        case .security:
            let view = SettingsSectionHeader(title: Localized.settings_header_security, error: Localized.settings_header_security_text)
            view.setErrorHidden(isAccountSecured)

            return view
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionItem = sections[section]

        switch sectionItem {
        case .profile:
            return SettingsController.headerHeight + SettingsController.footerHeight
        default:
            return SettingsController.headerHeight
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }

        headerView.textLabel?.font = Theme.preferredFootnote()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {

        let sectionItem = sections[section]

        switch sectionItem {
        case .other:
            return .defaultCellHeight
        default:
            return SettingsController.footerHeight
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = sections[section]
        return sectionInfo.headerTitle
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let sectionInfo = sections[section]
        return sectionInfo.footerTitle
    }
}
