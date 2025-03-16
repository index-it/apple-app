//
//  ShareViewController.swift
//  indexShareExtension
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import SwiftData

@objc(ShareViewController)
class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textDataType = UTType.plainText.identifier
        let urlDataType = UTType.url.identifier
        
        if let inputItem = (extensionContext?.inputItems.first as? NSExtensionItem),
           let itemProvider = inputItem.attachments?.first {
            if itemProvider.hasItemConformingToTypeIdentifier(urlDataType) {
                itemProvider.loadItem(forTypeIdentifier: urlDataType, options: nil) { (url, error) in
                    if error == nil {
                        if let url = (url as? URL) {
                            self.showView(name: nil, url: url.absoluteString)
                        }
                    }
                }
            }
           else if itemProvider.hasItemConformingToTypeIdentifier(textDataType) {
                itemProvider.loadItem(forTypeIdentifier: textDataType, options: nil) { (text, error) in
                    if error == nil {
                        if let text = text as? String {
                            self.showView(name: text, url: nil)
                        }
                    }
                }
            }
        }
        
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
            contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
            contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
        }
    }
    
    /// Close the Share Extension
    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
