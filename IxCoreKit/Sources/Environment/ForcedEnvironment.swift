//
//  ForcedEnvironment.swift
//  IxCoreKit
//
//  Created by Giulio Pimenoff Verdolin on 04/05/25.
//


@propertyWrapper
public struct ForcedEnvironment<Value>: DynamicProperty {
    @Environment private var env: Value?
    
    init(_ keyPath: KeyPath<EnvironmentValues, Value?>) {
        _env = Environment(keyPath)
    }
    
    var wrappedValue: Value {
        if let env {
            return env
        } else {
            fatalError("\(Value.self) not provided")
        }
    }
}
