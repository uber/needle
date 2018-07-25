import UIKit
import RIBs;    import Foundation

fileprivate protocol PrivateDependency: Dependency {
    var candy: Candy { get }
    var cheese: Cheese { get }
}

private class PrivateComponent: Component<MyDependency> {

    private let stream: Stream = Stream()

    fileprivate var donut: Donut {
        return Donut()
    }
}
