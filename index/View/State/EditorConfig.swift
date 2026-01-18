//
//  EditorConfig.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/01/26.
//

import IxCoreKit

struct EditorConfig<Entity: Validatable & Sanitizable & EmptyInitializable> {
    var entity: Entity = .empty

    var mode: EditorMode = .create
    var multi: Bool = false
    var loading: Bool = false

    var isPresented = false

    func sanitizeAndValidate() -> Result<Entity, ValidationError> {
        let sanitized = entity.sanitized

        return sanitized.validationRes.map { _ in sanitized }
    }

    /// Reset the entity to empty and loading to false
    mutating func reset() {
        entity = Entity.empty
        loading = false
    }

    /// Reset the entity to empty and loading to false, and present the editor
    mutating func resetAndPresent(
        multi: Bool = false
    ) {
        entity = Entity.empty
        self.multi = multi
        loading = false
        isPresented = true
    }
}
