import UIKit
import RIBs;    import Foundation

protocol NamespacedDep: NeedleFoundation.Dependency {
    var blah: Blah { get }
}

class NamespacedComp: NeedleFoundation.Component<NamespacedDep> {
    var donut: Donut {
        return Donut()
    }
}
