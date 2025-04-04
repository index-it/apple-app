//
//  AppIconProvider.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 23/03/25.
//

import SwiftUI

struct AppIconProvider {
    static func appIcon(in bundle: Bundle = .main) -> String {
        guard let icons = bundle.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconFileName = iconFiles.last else {
            fatalError("Could not find icons in bundle")
        }

        return iconFileName
    }
}

struct AppIcon: View {
    var body: some View {
        Image(uiImage: UIImage(named: AppIconProvider.appIcon()) ?? UIImage())
    }
}
