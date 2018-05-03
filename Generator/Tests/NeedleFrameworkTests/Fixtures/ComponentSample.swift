protocol MyDependency {
    var candy: Candy { get }
}

class MyComponent: Component<MyDependency> {
    var donut: Donut {
        return Donut()
    }

    var sweetsBasket: Basket {
        return shared {
            Basket(dependency.candy, self.donut)
        }
    }
}
