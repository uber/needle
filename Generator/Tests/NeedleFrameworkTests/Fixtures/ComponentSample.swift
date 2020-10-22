import UIKit
import RIBs;    import Foundation
import protocol Audio.Recordable

protocol MyDependency: Dependency {
    var candy: Candy { get }
    var cheese: Cheese { get }
}

protocol RandomProtocol {
    var blah: Int { get }
}

let randomValue = 1234

class MyComponent: NeedleFoundation.Component<
    MyDependency
> {

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

    func childComponent(with dynamicDependency: String) -> MyChildComponent {
        return MyChildComponent(parent: self, dynamicDependency: dynamicDependency)
    }
}

protocol SomeNonCoreDependency: Dependency {
    var aNonCoreDep: Dep { get }
    var maybeNonCoreDep: MaybeDep? { get }
}

class SomeNonCoreComponent: NeedleFoundation.NonCoreComponent<    SomeNonCoreDependency  > {
    var newNonCoreObject: NonCoreObject? {
        return NonCoreObject()
    }
    var sharedNonCoreObject: SharedObject {
        return shared {
            return SharedObject()
        }
    }
}

class MyRComp: BootstrapComponent {
    var rootObj: Obj {
        return shared {
            Obj()
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
    
    var myStore: MyStorage<MyStorageKey> {
        return MyStorage()
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

class SomePluginizedComp: PluginizedComponent<
  ADependency,
BExtension,    SomeNonCoreComponent
>, Stuff {
    var tv: Tv {
        return LGOLEDTv()
    }
}

class SimpleComponentizedBuilder: ComponentizedBuilder<Component, Dependency, (), ()> {}

class SimpleComponentizedBuilderTwo: NeedleFoundation.ComponentizedBuilder<Component, Dependency, (), ()> {}

class NestedNonComponent: NeedleFoundation.Component.NonComponent<Component, Dependency> {}

protocol My2Dependency: NeedleFoundation.Dependency {
    var backPack: Pack { get }
    var maybeMoney: Dollar? { get }
}

class RandomClass {

}

extension Dependency {

}
