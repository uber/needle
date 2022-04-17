# ![](Images/logo.png)

[![Build Status](https://travis-ci.com/uber/needle.svg?branch=master)](https://travis-ci.com/uber/needle?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

Needle은 Swift의 의존성 주입(DI) 시스템입니다. [Cleanse](https://github.com/square/Cleanse), [Swinject](https://github.com/Swinject/Swinject)와 같은 다른 DI 프레임워크와 달리 Needle은 **계층적 DI 구조를 장려하고 코드 생성을 활용하여 컴파일 시간 안전성을 보장합니다.** 이를 통해 우리는 자신 있게 앱을 개발하고 코드를 변경할 수 있습니다. **컴파일이 되면 동작합니다.** 이런 면에서 Needle은 [Dagger for JVM](https://google.github.io/dagger/)과 비슷합니다.

Needle은 다음과 같은 주요 목표를 달성하는 것을 목표로 합니다.

- 의존성 주입 코드가 컴파일 시간에 안전한지 확인하여 높은 안정성을 제공합니다.
- 수백만 줄의 코드베이스와 함께 사용하는 경우에도 코드 생성이 고성능인지 확인합니다.
- RIB, MVx 등을 포함한 모든 iOS 애플리케이션 아키텍처와 호환됩니다.

## 핵심내용

Needle을 사용하여 애플리케이션을 위한 DI 코드를 작성하는 것은 쉽고 컴파일 시간에 안전합니다. 각 의존성 범위는 `Component`로 정의됩니다. 그리고 그 의존성은 Swift `protocol`로 캡슐화됩니다. 둘은 Swift 제네릭을 사용하여 함께 연결됩니다.

```swift
/// 이 프로토콜은 상위 Scope에서 얻은 의존성을 캡슐화합니다.
protocol MyDependency: Dependency {
    /// 이 객체들은 상위 Scope에서 얻은 객체이므로 현재 Scope에는 없는 객체입니다.
    var chocolate: Food { get }
    var milk: Food { get }
}

/// 이 클래스는 Dependency 프로토콜을 통해 상위 Scope에서 의존성을 획득하고 프로퍼티들을 선언하여
/// DI 그래프에 새 객체를 제공하며 하위 Scope를 인스턴스화할 수 있는 새로운 의존성 범위를 정의합니다.
class MyComponent: Component<MyDependency> {

    /// 새로운 객체인 hotChocolate을 의존성 그래프에 추가됩니다.
    /// 그런 다음 하위 Scope들에서 Dependency 프로토콜을 통해 이를 획득할 수 있습니다.
    var hotChocolate: Drink {
        return HotChocolate(dependency.chocolate, dependency.milk)
    }

    /// 자식 Scope는 항상 부모 Scope에 의해 인스턴스화됩니다.
    var myChildComponent: MyChildComponent {
        return MyChildComponent(parent: self)
    }
}
```

이것이 Needle로 DI 코드를 작성하는 거의 대부분 입니다. 보시다시피 모든 것이 현실적으로 컴파일 가능한 Swift 코드입니다. 깨지기 쉬운 주석이나 "어노테이션"이 없습니다. 빠르게 요약하자면 여기에서 세 가지 주요 개념은 dependency protocol, component 및 자식 component의 인스턴스화입니다. 자세한 설명과 고급 주제는 아래 [Needle 시작하기](#Needle-시작하기) 섹션을 참조하세요.

## Needle 시작하기

Needle을 사용하고 통합하는데 까지는 두 단계가 있습니다. 다음 각 단계에 링크된 문서에 자세한 지침과 설명이 있습니다.

1. [Needle의 코드 제네레이터를 Swift 프로젝트에 통합](./GENERATOR.md).
2. [NeedleFoundation의 API에 따라 애플리케이션 DI 코드 작성](./API.md).

## 설치

Needle은 `NeedleFoundation` 프레임워크와 실행 가능한 코드 제네레이터의 두 부분으로 구성됩니다. Needle을 DI 시스템으로 사용하려면 두 부분을 모두 Swift 프로젝트와 통합해야 합니다.

### `NeedleFoundation` framework 설치

#### [Carthage](https://github.com/Carthage/Carthage) 사용 시

표준 [카르타고 설치 절차](https://github.com/Carthage/Carthage#quick-start)를 따라 `NeedleFoundation` framework를 Swift 프로젝트에 추가 합니다.
```
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

#### [CocoaPods](https://github.com/CocoaPods/CocoaPods)  사용 시

표준 코코아 팟 의존성 설치 절차에 따라 `NeedleFoundation` pod을 추가 합니다.

### 코드 제네레이터 설치

#### [Carthage](https://github.com/Carthage/Carthage) 사용 시

만약 Carthage를 사용하여 `NeedleFoundation` 프레임워크를 통합한 경우, 해당 버전의 코드 제네레이터 실행 파일이 이미 Carthage 폴더에 다운로드되어 있습니다. `Carthage/Checkouts/needle/Generator/bin/needle`에서 찾을 수 있습니다.

#### [Homebrew](https://github.com/Homebrew/brew) 사용 시

`NeedleFoundation` 프레임워크가 프로젝트에 통합되는 방식에 관계없이 제네레이터는 항상 [Homebrew](https://github.com/Homebrew/brew)를 통해 설치할 수 있습니다.
```
brew install needle
```

## [의존성 주입을 사용하는 이유?](./WHY_DI.md)

링크된 문서는 의존성 주입 패턴과 그 이점을 설명하기 위해 다소 현실적인 예를 사용합니다.

## Related projects

만약 Needle이 마음에 들면 우리 팀의 다른 관련 오픈 소스 프로젝트를 확인하십시오.
- [Swift Concurrency](https://github.com/uber/swift-concurrency): Uber에서 사용하는 동시성 유틸리티 클래스 세트입니다. 동등한 [java.util.concurrent](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/package-summary.html) package classes에서 영감을 받았습니다.
- [Swift Abstract Class](https://github.com/uber/swift-abstract-class): Swift 프로젝트를 위한 컴파일 타임 안전한 추상 클래스 개발을 가능하게 하는 경량 라이브러리
- [Swift Common](https://github.com/uber/swift-common): Swift 오픈 소스 프로젝트에서 사용되는 공통 라이브러리 세트.

## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fuber%2Fswift-concurrency.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fuber%2Fswift-concurrency?ref=badge_large)
