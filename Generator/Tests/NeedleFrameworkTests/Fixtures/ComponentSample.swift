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

class My2Component: Component<My2Dependency> {
    var book: Book {
        return shared {
            Book()
        }
    }

    private var banana: Banana {
        return Banana()
    }

    fileprivate var apple: Apple {
        return Apple()
    }
}

protocol My2Dependency: Dependency {
    var backPack: Pack { get }
}

class RandomClass {

}

extension Dependency {

}
