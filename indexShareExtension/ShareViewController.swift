//
//  ShareViewController.swift
//  indexShareExtension
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import IxCoreKit
import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await loadExtensionItems()
        }
    }

    func loadExtensionItems() async {
        let textDataType = UTType.plainText.identifier
        let urlDataType = UTType.url.identifier

        guard let extensionContext else { return }

        var name: String? = nil
        var url: String? = nil

        let itemProviders = extensionContext.inputItems.compactMap { ($0 as? NSExtensionItem)?.attachments }.flatMap { $0 }
        for itemProvider in itemProviders {
            if itemProvider.hasItemConformingToTypeIdentifier(urlDataType), url == nil {
                let unparsedUrl = try? await itemProvider.loadItem(forTypeIdentifier: urlDataType, options: nil)
                if let parsedUrl = (unparsedUrl as? URL) {
                    url = parsedUrl.absoluteString
                }
            } else if itemProvider.hasItemConformingToTypeIdentifier(textDataType), name == nil {
                let text = try? await itemProvider.loadItem(forTypeIdentifier: textDataType, options: nil)
                if let text = text as? String {
                    name = text
                }
            }
        }

        showView(name: name, url: url)

        NotificationCenter.default.addObserver(forName: NSNotification.Name("close.share.extension"), object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.close()
            }
        }
    }

    func showView(name: String?, url: String?) {
        DispatchQueue.main.async {
            let contentView = UIHostingController(
                rootView: ShareExtensionView(name: name, link: url).modelContainer(ModelContainerProvider.shared)
            )
            self.addChild(contentView)
            self.view.addSubview(contentView.view)

            // set up constraints
            contentView.view.translatesAutoresizingMaskIntoConstraints = false
            contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            contentView.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            contentView.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        }
    }

    /// Close the Share Extension
    func close() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
