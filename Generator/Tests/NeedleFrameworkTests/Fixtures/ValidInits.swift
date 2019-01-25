class AParentComponent: Component<EmptyDependency> {

    var myComponent: MyComponent {
        return MyComponent   (  parent   :    self  ,   x  :   X(y: 10) )
    }

    var my1Component: My1Component {
        return My1Component   (  parent   :    self
        )
    }

    var myComponent2: MyComponent2 {
        return MyComponent2   (  parent   :    self)
    }
}

class AnotherParentComponent: Component<EmptyDependency> {
    var myCompo3nent: MyCompo3nent {
        return MyCompo3nent   (  parent   :    self, x  :   X(y: 10) )
    }
}

let root = RootComponent(parent :   BootstrapComponent())
