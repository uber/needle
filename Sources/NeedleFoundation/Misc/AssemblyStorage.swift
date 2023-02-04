//
//  AssemblyStorage.swift
//  NeedleFoundation
//
//  Created by Mikhail Maslo on 04.02.23.
//

final class AssemblyStorage {
    final class WeakBox {
        weak var object: AnyObject?

        init<Object: AnyObject>(object: Object) {
            self.object = object
        }
    }

    private lazy var strongObjects: [Key: Any] = [:]
    private lazy var weakObjects: [Key: WeakBox] = [:]

    init() {}

    func shared<Args: Hashable, Object>(function: StaticString, args: Args, factory: () -> Object) -> Object {
        let key = Key(function: function, args: args)
        if let object = strongObjects[key] {
            return object as! Object
        }

        let object = factory()
        strongObjects[key] = object
        return object
    }

    func weakShared<Args: Hashable, Object: AnyObject>(function: StaticString, args: Args, factory: () -> Object) -> Object {
        let key = Key(function: function, args: args)
        if let object = weakObjects[key]?.object {
            return object as! Object
        }

        let object = factory()
        weakObjects[key] = WeakBox(object: object)
        return object
    }
}

final class Key: Hashable {
    // MARK: - Private properties

    private let function: StaticString
    private let args: AnyHashable

    // MARK: - Init

    init<Args>(function: StaticString, args: Args) where Args: Hashable {
        self.function = function
        self.args = args
    }

    // MARK: - Hashable

    static func == (lhs: Key, rhs: Key) -> Bool {
        isSameFunction(function1: lhs.function, function2: rhs.function) && lhs.args == rhs.args
    }

    func hash(into hasher: inout Hasher) {
        var hasher = Hasher()

        if function.hasPointerRepresentation {
            hasher.combine(function.utf8Start)
        } else {
            hasher.combine(function.unicodeScalar)
        }

        hasher.combine(args)
    }

    // MARK: - Private methods

    private static func isSameFunction(function1: StaticString, function2: StaticString) -> Bool {
        guard function1.hasPointerRepresentation == function2.hasPointerRepresentation else {
            return false
        }

        if function1.hasPointerRepresentation {
            return function1.utf8Start == function2.utf8Start
        } else {
            return function1.unicodeScalar == function2.unicodeScalar
        }
    }
}
