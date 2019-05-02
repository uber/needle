class NamespacedRootComp: NeedleFoundation.RootComponent {
    var rootObj: Obj {
        return shared {
            Obj()
        }
    }
}
