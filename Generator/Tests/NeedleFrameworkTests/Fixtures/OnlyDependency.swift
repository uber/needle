import UIKit
import RIBs;    import Foundation

protocol Only1Dependency: Dependency {
    var candy: Candy { get }
    var cheese: Cheese { get }
}
