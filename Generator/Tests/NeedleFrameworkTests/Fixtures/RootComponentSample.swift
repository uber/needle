class NonNamespaceRootComp: BootstrapComponent {
    var rootObj: Obj {
        return shared {
            Obj()
        }
    }
}
