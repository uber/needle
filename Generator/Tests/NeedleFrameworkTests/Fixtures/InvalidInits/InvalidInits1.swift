class BParentComponent: Component<EmptyDependency> {

    func newComp(param: Stuff) -> MyComponent {
        return MyComponent   (  parent   :    param)
    }
}
