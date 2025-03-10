//
//  ShareViewController.swift
//  indexShareExtension
//
//  Created by Giulio Pimenoff Verdolin on 10/03/25.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            // Check type identifier
            let textDataType = UTType.plainText.identifier
            let urlDataType = UTType.url.identifier
            
            var data: String? = "prova"
            var urlData: String? = nil
            
            extensionContext?.inputItems.forEach({ inputItem in
                (inputItem as? NSExtensionItem)?.attachments?.forEach({ itemProvider in
//                    if itemProvider.hasItemConformingToTypeIdentifier(urlDataType) && urlData == nil {
//                        itemProvider.loadItem(forTypeIdentifier: urlDataType, options: nil) { (url, error) in
//                            if error == nil {
//                                print(url)
//                            }
//                        }
//                    } else if itemProvider.hasItemConformingToTypeIdentifier(textDataType) && data == nil {
//                        itemProvider.loadItem(forTypeIdentifier: textDataType, options: nil) { (text, error) in
//                            if error == nil {
//                                print(text)
////                                if let text = text as? String {
////                                    data = text
////                                }
//                            }
//                        }
//                    }
                })
            })
            
//            print((extensionContext?.inputItems.first as? NSExtensionItem)?.attachments?.first?.loadItem(forTypeIdentifier: urlDataType))
            
            if data == nil && urlData == nil {
                self.close()
                return
            }
            
            DispatchQueue.main.async {
                let contentView = UIHostingController(rootView: ShareExtensionView(name: data, link: urlData))
                //            let contentView = UIHostingController(rootView: ShareExtensionView(data: "", url: ""))
                self.addChild(contentView)
                self.view.addSubview(contentView.view)
                
                // set up constraints
                contentView.view.translatesAutoresizingMaskIntoConstraints = false
                contentView.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                contentView.view.bottomAnchor.constraint (equalTo: self.view.bottomAnchor).isActive = true
                contentView.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
                contentView.view.rightAnchor.constraint (equalTo: self.view.rightAnchor).isActive = true
            }
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name("close.share.extension"), object: nil, queue: nil) { _ in
                DispatchQueue.main.async {
                    self.close()
                }
            }
        } catch {
            print(error)
        }
    }
    
    /// Close the Share Extension
    func close() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
