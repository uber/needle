class NamespacedRootComp: NeedleFoundation.BootstrapComponent {
    var rootObj: Obj {
        return shared {
            Obj()
        }
    }
}
