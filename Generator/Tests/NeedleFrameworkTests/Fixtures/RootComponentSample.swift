class NonNamespaceRootComp: NeedleFoundation.RootComponent {
    var rootObj: Obj {
        return shared {
            Obj()
        }
    }
}
