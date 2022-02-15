//
//  PairedBrowsersViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class DesktopPairingViewController: UITableViewController, ExternalURLSource {
    @IBOutlet private var infoButton: UIBarButtonItem!
    private var sessions = [WCKeySession]()

    // Change to switch the implementations for debugging or testing
    private let usesNewImplementation = false

    private let wcServerController = WalletConnectKeysServerController.shared
    private var connectionController = WebConnectionController.shared

    private lazy var relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter
    }()
    var url: URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        url = App.configuration.help.desktopPairingURL

        title = "Connect to Web"

        wcServerController.delegate = self

        tableView.backgroundColor = .primaryBackground
        tableView.registerCell(DetailedCell.self)
        tableView.registerHeaderFooterView(DesktopPairingHeaderView.self)
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        infoButton = UIBarButtonItem(image: UIImage(named: "ico-info"),
                style: UIBarButtonItem.Style.plain,
                target: self,
                action: #selector(openHelpUrl))
        navigationItem.rightBarButtonItem = infoButton
        
        subscribeToNotifications()
        update()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.desktopPairing)
    }

    private func subscribeToNotifications() {
        [NSNotification.Name.wcConnectingKeyServer,
         .wcDidConnectKeyServer,
         .wcDidDisconnectKeyServer,
         .wcDidFailToConnectKeyServer].forEach {
            NotificationCenter.default.addObserver(self, selector: #selector(update), name: $0, object: nil)
         }
    }

    @objc private func openHelpUrl() {
        openExternalURL()
        Tracker.trackEvent(.desktopPairingLearnMore)
    }

    @objc private func update() {
        do {
            sessions = try WCKeySession.getAll().filter {
                $0.session != nil && (try? Session.from($0)) != nil
            }
        } catch {
            LogService.shared.error("Failed to get WCKeySession: \(error.localizedDescription)")
        }

        DispatchQueue.main.async { [unowned self] in
            self.tableView.reloadData()
        }
    }

    private func scan() {
        let vc = QRCodeScannerViewController()

        let string = "Go to Gnosis Safe Web and select Connect wallet." as NSString
        let textStyle = GNOTextStyle.primary.color(.white)
        let highlightStyle = textStyle.weight(.bold)
        let label = NSMutableAttributedString(string: string as String, attributes: textStyle.attributes)
        label.setAttributes(highlightStyle.attributes, range: string.range(of: "Gnosis Safe Web"))
        label.setAttributes(highlightStyle.attributes, range: string.range(of: "Connect wallet"))
        vc.attributedLabel = label

        vc.scannedValueValidator = { [unowned self] value in
            guard value.starts(with: "safe-wc:") else {
                return .failure(GSError.InvalidWalletConnectQRCode())
            }
            var url = value
            if !usesNewImplementation {
                url.removeFirst("safe-".count)
            }
            return .success(url)
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        present(vc, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sessions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let session = sessions[indexPath.row]

        switch session.status {
        case .connecting:
            return tableView.detailedCell(
                imageUrl: nil,
                header: "Connecting...",
                description: nil,
                indexPath: indexPath,
                canSelect: false,
                placeholderImage: UIImage(named: "ico-empty-circle"))

        case .connected:
            let relativeTime = relativeDateFormatter.localizedString(for: session.created!, relativeTo: Date())
            let session = try! Session.from(session)
            let dappIcon = session.dAppInfo.peerMeta.icons.isEmpty ? nil : session.dAppInfo.peerMeta.icons[0]

            return tableView.detailedCell(
                imageUrl: dappIcon,
                header: session.dAppInfo.peerMeta.name,
                description: relativeTime,
                indexPath: indexPath,
                canSelect: false,
                placeholderImage: UIImage(named: "ico-empty-circle"))
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(DesktopPairingHeaderView.self)
        view.onScan = { [unowned self] in
            self.scan()
        }
        return view
    }

    override func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let session = sessions[indexPath.row]
        let actions = [
            UIContextualAction(style: .destructive, title: "Disconnect") { _, _, completion in
                WalletConnectKeysServerController.shared.disconnect(topic: session.topic!)
            }]
        return UISwipeActionsConfiguration(actions: actions)
    }
}

extension DesktopPairingViewController: QRCodeScannerViewControllerDelegate {

    func scannerViewControllerDidScan(_ code: String) {
        dismiss(animated: true) { [unowned self] in
            connect(to: code)
        }
    }

    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }

    fileprivate func connect(to code: String) {
        if usesNewImplementation {
            didScanNewImplementation(code)
        } else {
            didScanOldImplementation(code: code)
        }
    }

    private func didScanOldImplementation(code: String) {
        var code = code
        if code.starts(with: "safe-wc:") {
            code.removeFirst("safe-".count)
        }
        do {
            try wcServerController.connect(url: code)
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
        }
    }

    func didScanNewImplementation(_ code: String) {
        do {
            let connection = try WebConnectionController.shared.connect(to: code)
            let connectionVC = WebConnectionRequestViewController()
            connectionVC.connectionController = WebConnectionController.shared
            connectionVC.connection = connection
            connectionVC.onFinish = { [weak self] in
                self?.dismiss(animated: true)
            }
            let nav = UINavigationController(rootViewController: connectionVC)
            present(nav, animated: true)
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
        }
    }

}

extension DesktopPairingViewController: WalletConnectKeysServerControllerDelegate {
    func shouldStart(session: Session, completion: @escaping ([KeyInfo]) -> Void) {
        guard let keys = try? KeyInfo.all(), !keys.isEmpty else {
            DispatchQueue.main.async {
                App.shared.snackbar.show(message: "Please import an owner key to pair with desktop")
            }
            completion([])
            return
        }
        guard keys.filter({ $0.keyType != .walletConnect}).count != 0 else {
            DispatchQueue.main.async {
                App.shared.snackbar.show(message: "Connected via WalletConnect keys can not be paired with the desktop. Please import supported owner key types.")
            }
            completion([])
            return
        }

        DispatchQueue.main.async { [unowned self] in
            let vc = ConfirmConnectionViewController(dappInfo: session.dAppInfo.peerMeta)
            vc.onConnect = { [unowned vc] keys in
                vc.dismiss(animated: true) {
                    completion(keys)
                }
            }
            vc.onCancel = { [unowned vc] in
                vc.dismiss(animated: true) {
                    completion([])
                }
            }
            self.present(UINavigationController(rootViewController: vc), animated: true)
        }
    }
}

extension DesktopPairingViewController: NavigationRouter {
    func canNavigate(to route: NavigationRoute) -> Bool {
        route.path == NavigationRoute.connectToWeb().path
    }

    func navigate(to route: NavigationRoute) {
        if let code = route.info["code"] as? String {
            connect(to: code)
        }
    }
}