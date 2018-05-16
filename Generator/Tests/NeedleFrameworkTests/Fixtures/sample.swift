import RxSwift
import Utility

protocol SomeDependency: Dependency {
    var count: Integer { get }
    var name: String { get }
    var stream: Observable<Bool> { get }
}

class SomeComponent: Component<SomeDependency> {
    let x: Int
    let y: String

    var name: String {
        return "slim shady"
    }
}

protocol OtherDependency: Dependency {
    // Comment
    var c: Integer { get }
    // More comments
    var s: String { get}
}

class OtherComponent: Component  <OtherDependency> {
    let x: Int

    var name: String {
        return "max power"
    }
}

protocol IgnoreDependency {
    var total: Double { get }
}
