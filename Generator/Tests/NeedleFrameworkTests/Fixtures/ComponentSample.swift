import UIKit
import RIBs;    import Foundation

protocol MyDependency: Dependency {
    var candy: Candy { get }
    var cheese: Cheese { get }
}

protocol RandomProtocol {
    var blah: Int { get }
}

let randomValue = 1234

class MyComponent: Component<MyDependency> {

    let stream: Stream = Stream()

    var donut: Donut {
        return Donut()
    }

    var sweetsBasket: Basket {
        return shared {
            Basket(dependency.candy, self.donut)
        }
    }

    var myChildComponent: MyChildComponent {
        return MyChildComponent(parent: self)
    }
}

protocol SomeNonCoreDependency: Dependency {
    var aNonCoreDep: Dep { get }
    var maybeNonCoreDep: MaybeDep? { get }
}

class SomeNonCoreComponent: NonCoreComponent<SomeNonCoreDependency> {
    var newNonCoreObject: NonCoreObject? {
        return NonCoreObject()
    }
    var sharedNonCoreObject: SharedObject {
        return shared {
            return SharedObject()
        }
    }
}

class My2Component: Component<My2Dependency> {
    var book: Book {
        return shared {
            Book()
        }
    }

    var maybeWallet: Wallet? {
        return Wallet()
    }

    private var banana: Banana {
        return Banana()
    }

    fileprivate var apple: Apple {
        return Apple()
    }
}

protocol ADependency: Dependency {
    var maybe: Maybe? { get }
}

protocol BExtension: PluginExtension {
    var myPluginPoint: MyPluginPoint { get }
}

class SomePluginizedComp: PluginizedComponent<ADependency, BExtension, SomeNonCoreComponent>, Stuff {
    var tv: Tv {
        return LGOLEDTv()
    }
}

protocol My2Dependency: Dependency {
    var backPack: Pack { get }
    var maybeMoney: Dollar? { get }
}

class RandomClass {

}

extension Dependency {

}
