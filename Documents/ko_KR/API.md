Needle API
==========
이 문서에서는 Needle API와 코드에서 Needle과 상호 작용하는 데 사용하는 클래스에 대해 설명합니다.

1. [소개 및 용어](#소개-및-용어)
2. [Components](#components)
3. [Dependencies](#dependencies)
4. [Component 사용하기](#Component-사용하기)
4. [Tree-structure](#tree-structure)

## 설치

#### [Carthage](https://github.com/Carthage/Carthage) 사용 시

표준 [카르타고 설치 절차](https://github.com/Carthage/Carthage#quick-start)를 따라 `NeedleFoundation` framework를 Swift 프로젝트에 추가 합니다.
```shell
github "https://github.com/uber/needle.git" ~> VERSION_OF_NEEDLE
```

#### [Swift Package Manager](https://github.com/apple/swift-package-manager) 사용시

`NeedleFoundation` 프레임워크를 Swift 프로젝트와 통합하려면 표준 [Swift Package Manager 패키지 정의 프로세스](https://github.com/apple/swift-package-manager/blob/master/Documentation/Usage.md)를 통해 Needle을 의존성에 추가 합니다.
```swift
dependencies: [
    .package(url: "https://github.com/uber/needle.git", .upToNextMajor(from: "VERSION_NUMBER")),
],
targets: [
    .target(
        name: "YOUR_MODULE",
        dependencies: [
            "NeedleFoundation",
        ]),
],
```

# 소개 및 용어

## Basics

의존성 주입(Dependency Injection, 이하부터 DI로 표기)을 사용하는 주요 이유는 별도의 [문서](/WHY_DI.md)에 설명되어 있습니다. 당신의 앱이 DI의 혜택을 받을 수 있는지 확실하지 않은 경우 계속하기 전에 이 내용을 읽어보십시오.

## 핵심 요소

가장 중심에는 정말로 마스터해야 할 클래스가 하나 있는데 바로 `Component`입니다. Needle은 계층 구조를 가진 모든 앱에 사용할 수 있습니다. 이 튜토리얼에서는 고전적인 `MVC` 앱에 대해 이야기한다고 가정합니다. (본문에서는 `UIViewController`를 사용하지만, `NSViewController` 혹은 `MVC`와는 다른 아키텍처에서 동등한 개념으로 쉽게 적용되어야 합니다).

따라서 앱의 모든 'UIViewController'에는 일반적으로 `Component` 하위 클래스가 있어야 합니다. `WelcomeViewController`라는 클래스의 경우 component의 이름은 일반적으로 `WelcomeComponent`입니다.

# Components

각 `Component`는 `Scope`로 간주됩니다. component의 구현부는 비교적 간단합니다. 일반적으로 구현부는 새로운 객체를 생성하는 몇 가지 computed property들입니다. 다음은 `Component`의 예입니다.

```swift
import NeedleFoundation

class LoggedInComponent: Component<LoggedInDependency> {
    var scoreStream: ScoreStream {
        return mutableScoreStream
    }

    var mutableScoreStream: MutableScoreStream {
        return shared { ScoreStreamImpl() }
    }

    var loggedInViewController: UIViewController {
        return LoggedInViewController(gameBuilder: gameComponent, scoreStream: scoreStream, scoreSheetBuilder: scoreSheetComponent)
    }
}
```
**참고:** *DI 그래프*에서 의미가 있는 항목과 `ViewController` 하위 클래스의 지역 변수일 수 있는 항목을 결정하는 것은 사용자의 몫입니다. Swift에는 'OCMock'과 같은 도구가 없기 때문에 테스트 중에 mocking하고 싶은 것은 무엇이든 (프로토콜로) 전달해야 합니다.

예제의 `shared` 구문은 우리가 (`Component` 기본 클래스 내부에서) 제공하는 유틸리티 함수로 이 `var`에 액세스할 때마다 단순하게 동일한 인스턴스를 반환합니다. (아래에 선언된 프로퍼티는 대조적으로 새로운 매번 인스턴스를 반환합니다). 이렇게 하면 이 프로퍼티의 라이프사이클이 Component의 라이프사이클에 연결됩니다.

component를 사용하여 이 component와 쌍을 이루는 `ViewController`를 구성할 수도 있습니다. 위의 예제에서 볼 수 있듯이, 이것은 `ViewController`가 프로젝트에서 DI 시스템을 사용하고 있다는 사실을 인식하지 않고도 `ViewController`가 필요로 하는 모든 의존성을 전달할 수 있도록 합니다. **"DI의 이점"** 문서에서 언급했듯이 구체적인 클래스나 구조체 대신 프로토콜을 전달하는 것이 가장 좋습니다.

# Dependencies

만약 component가 여기서 끝난다면 단순히 각 `ViewController`의 모든 "의존성"을 보유하는 컨테이너가 됩니다. 이것은 `ViewController` 클래스에 대한 더 나은 단위 테스트를 수행할 수 있기 때문에 그 자체로 유용합니다. 물론 `UIViewController` 하위 클래스는 쉽게 단위 테스트가 가능하지 않은 경우가 많으므로 우리 RIB 아키텍처(및 다른 많은 아키텍처)는 "비즈니스 로직"을 단위 테스트 가능한 별도의 클래스로 분할하는 이유입니다.

진정한 힘은 동일한 트리 내에서 상위 `Components`에서도 항목을 가져올 수 있다는 점에서 나옵니다.

이를 위해 `Dependency Protocol`이라고 하는 프로토콜의 상위 component에서 가져오려는 의존성을 지정합니다. Uber에서는 `NameEntryComponent`와 관련된 의존성 프로토콜을 `NameEntryDependency`라고 합니다. 다음은 예입니다.(**참고:** 우리는 이미 위의 `Component` 클래스의 일반 매개변수에서 이 프로토콜을 사용했습니다):

```swift
protocol LoggedInDependency: Dependency {
    var imageCache: ImageCache { get }
    var networkService: NetworkService { get }
}
```

# Component 사용하기

좋은 점은 Needle command-line 코드 제네레이터를 실행할 준비가 되지 않았더라도 코드를 작성하고 컴파일할 준비가 되었다는 것입니다. 우리는 또한 `imageCache`와 `networkService`가 어느 상위 `Component`에서 왔는지 시스템에 알리지 않았습니다.

처음 예제에서는 현재 `Scope`에서 생성된 항목만 사용합니다. 만약 다른 범위에서 가져올 것으로 예상되는 항목을 ViewController에 전달하려는 경우 loginViewController는 다음과 같습니다.

```swift
    var loginViewController: UIViewController {
        return LoggedInViewController(
            gameBuilder: gameComponent,
            scoreStream: scoreStream,
            scoreSheetBuilder: scoreSheetComponent,
            imageCache: dependency.imageCache
        )
    }
```

# Tree-Structure

이 퍼즐의 마지막 조각은 우리가 의존성 프로토콜에 나열된 항목들이 실제로 어디에서 왔는지 어떻게 시스템에 알릴 것인가에 대한 질문입니다. 우리가 만든 모든 `Component` 하위 클래스는 트리로 함께 연결되어야 합니다. 이 작업은 시스템에 모든 component 간의 부모-자식 관계를 알려줌으로써 수행됩니다. 단순하게 부모 component의 자식 component에 대한 생성자를 작성하여 이러한 관계를 지정하기만 하면 됩니다. 이것은 다음과 같습니다.

```swift
class LoggedInComponent: Component {

    ...

    var loginViewController: UIViewController {
        return LoggedInViewController(
            gameBuilder: gameComponent,
            scoreStream: scoreStream,
            scoreSheetBuilder: scoreSheetComponent,
            imageCache: dependency.imageCache
        )
    }

    // MARK: - Children

    var gameComponent: GameComponent {
    	return GameComponent(parent: self)
    }
}
```

이 트리 구조가 코드로 선언되면 Needle command-line 도구는 이 구조를 사용하여 특정 범위의 의존성을 결정합니다. 알고리즘은 간단합니다. 이 `Scope`가 요구하는 각 항목에 대해, 우리는 부모들의 사슬을 따라 올라갑니다. 항목을 제공할 수 있는 **가장 가까운 부모**가 해당 프로퍼티를 가져오는 부모입니다.

# Bootstrap Root

DI 트리의 루트에는 상위 component가 없기 때문에 특수한 `BootstrapComponent` 클래스를 사용하여 루트 범위를 부트스트랩합니다.

```swift
let rootComponent = RootComponent()

class RootComponent: NeedleFoundation.BootstrapComponent {
    /// Root component code...
}
```
`RootComponent`는 `NeedleFoundation.BootstrapComponent`에서 상속하여 의존성 프로토콜을 지정할 필요가 없습니다. DI 그래프의 루트에는 어쨌든 의존성을 획득할 부모가 없습니다.

`root`에는 부모가 없다는 것을 알고 있기 때문에 애플리케이션 코드에서 `RootComponent()`를 호출하여 루트 범위를 인스턴스화할 수 있습니다.

# 유연성

프로젝트가 작동하고 Needle API 및 DI에 대해 전반적으로 잘 이해하고 있다고 생각되는 경우에만 위의 권장 사항/컨벤션에서 벗어나는 시도를 하는 것을 좋습니다. 예를 들어 각 `ViewController`에는 각 `ViewController`에 해당 `Component`가 있는 것이 좋지만 API의 어떤 것도 여러 ViewController 간에 하나의 `Component` 하위 클래스를 공유하는 것을 방해하지 않습니다.