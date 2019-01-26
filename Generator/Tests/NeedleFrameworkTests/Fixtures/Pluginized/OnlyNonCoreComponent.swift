import NeedleFoundation
import ScoreSheet

/// Component for the Game non core scope.
public class GameNonCoreComponent: NeedleFoundation.NonCoreComponent<EmptyDependency> {

    public var scoreSheetBuilder: ScoreSheetBuilder {
        return ScoreSheetComponent(parent: self)
    }
}
