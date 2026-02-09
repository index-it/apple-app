//
//  IxListEntity.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 03/02/26.
//

import AppIntents
import IxCoreKit

// TODO: Implement Transferrable protocol
@available(iOS 26.0, *)
struct IxListEntity: IndexedEntity {
    static let defaultQuery = IxListEntityQuery()

    var id: String

    @Property(indexingKey: \.displayName)
    var name: String

    @Property
    var icon: String

    @Property
    var color: String

    @Property
    var archived: Bool

    @Property
    var isPublic: Bool

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("List", table: "AppIntents", comment: "The type name for the list entity"),
            numericFormat: "\(placeholder: .int) lists"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        let image = EmojiHelper.emojiImageData(icon).flatMap { data in
            DisplayRepresentation.Image(data: data, isTemplate: false, displayStyle: .default)
        }
        return DisplayRepresentation(title: "\(name)", image: image)
    }

    init(list: IxList) {
        id = list.id
        name = list.name
        icon = list.icon
        color = list.color
        archived = list.archived
        isPublic = list.isPublic
    }
}

@available(iOS 26.0, *)
extension IxListEntity: URLRepresentableEntity {
    static var urlRepresentation: URLRepresentation {
        // cannot use IxUniversalLinks struct to compute this unfortunately
        "https://web.index-it.app/lists/\(.id)"
    }
}
