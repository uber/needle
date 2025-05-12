//
//  AssemblyStorage.swift
//  NeedleFoundation
//
//  Created by Mikhail Maslo on 04.02.23.
//

struct Nothing {
    public init() {}
}

extension Nothing: Equatable {
    public static func == (lhs: Nothing, rhs: Nothing) -> Bool {
        true
    }
}

extension Nothing: Hashable {
    public func hash(into hasher: inout Hasher) {
        // Do nothing
    }
}
