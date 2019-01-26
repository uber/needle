class CParentComponent: Component<EmptyDependency> {

    var myComponent2: MyComponent2 {
        return MyComponent2   (  parent   :    self.blah)
    }
}
