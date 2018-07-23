import UIKit
import RIBs;    import Foundation

class NamespacedNonCoreComponent: NeedleFoundation.NonCoreComponent<EmptyDependency> {}

protocol BExtension: NeedleFoundation.PluginExtension {}

class SomePluginizedCompo: NeedleFoundation.PluginizedComponent<ADependency, BExtension, ANonCoreComponent>, Stuff {
}
