class MyChildComponent: Component<My2Dependency> {
    var book: Book {
        return shared {
            Book()
        }
    }
}
