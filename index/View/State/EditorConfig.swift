//
//  ItemEditorConfig.swift
//  index
//
//  Created by Giulio Pimenoff Verdolin on 18/01/26.
//

import IxCoreKit

struct EditorConfig<Entity: Validatable & Sanitizable & EmptyInitializable> {
    var entity: Entity = Entity.empty
    
    var mode: EditorMode = .create
    var multi: Bool = false
    var loading: Bool = false
    
    var isPresented = false
    
    func sanitizeAndValidate() -> Result<Entity, ValidationError> {
        let sanitized = entity.sanitized
        
        return sanitized.validationRes.map { _ in sanitized }
    }
    
    mutating func resetAndPresent(
        multi: Bool = false
    ) {
        entity = Entity.empty
        self.multi = multi
        loading = false
        isPresented = true
    }
}
