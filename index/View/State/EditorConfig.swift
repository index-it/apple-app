//
//  EditorConfig.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/01/26.
//

import IxCoreKit

struct EditorConfig<Entity: Validatable & Sanitizable & EmptyInitializable> {
    var entity: Entity = .empty()

    var mode: EditorMode = .create
    var multi: Bool = false
    var loading: Bool = false

    var isPresented = false

    func sanitizeAndValidateRes() -> Result<Entity, ValidationError> {
        let sanitized = entity.sanitized

        return sanitized.validationRes.map { _ in sanitized }
    }

    func sanitizeAndValidate() throws -> Entity {
        return try sanitizeAndValidateRes().get()
    }

    /// Reset the entity to empty and loading to false
    mutating func reset() {
        entity = Entity.empty()
        loading = false
    }

    /// Present the editor resetting the loading state and using the provided entity and multi flag
    mutating func present(
        entity: Entity = .empty(),
        mode: EditorMode = .create,
        multi: Bool = false
    ) {
        self.entity = entity
        self.mode = mode
        self.multi = multi
        loading = false
        isPresented = true
    }
}
