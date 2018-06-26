import UIKit
import RIBs;    import Foundation

class ANonCoreComponent: NonCoreComponent<EmptyDependency> {}

protocol BExtension: PluginExtension {}

class SomePluginizedCompo: PluginizedComponent<ADependency, BExtension, ANonCoreComponent>, Stuff {
}
