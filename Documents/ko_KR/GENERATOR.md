# Needle code generator

이 문서는 Needle 코드 제네레이터가 무엇이며 어떻게 작동하는지 대략적으로 설명합니다. 더 중요한 것은 이 문서는 제네레이터를 사용하는 방법과 DI 코드의 컴파일 시간 안전성을 보장하기 위해 제네레이터를 Xcode 프로젝트와 통합하는 방법을 자세히 설명합니다.

## Overview

Needle 코드 제네레이터는 개발자가 작성한 Swift DI 코드를 구문 분석하여 Swift 소스 코드를 생성하는 command-line 유틸리티입니다. 생성된 코드는 개발자가 작성하는 다양한 `Component` 하위 클래스를 "연결"합니다. DI 그래프 구조의 관점에서 제네레이터는 개별 `Component` 노드 사이에 가장자리를 생성합니다. 생성된 코드는 애플리케이션으로 컴파일되어 완전한 DI 그래프를 제공합니다.

## Compile-time safety

다른 DI 프레임워크에 비해 Needle의 가장 큰 장점 중 하나는 컴파일 시간 안전성 보장입니다. `Component`에 필요한 의존성을 도달 가능한 상위 `Component`로 충족할 수 없는 경우 생성된 Swift 코드는 컴파일에 실패합니다. 이 경우 Needle의 제네레이터는 특정 불만족 의존성을 설명하는 오류를 반환합니다. (예시: `Could not find a provider for (scoreStream: MyScoreStream) which was required by ScoreSheetDependency, along the DI branch of RootComponent->LoggedInComponent->ScoreSheetComponent.`)

아래에 설명된 것처럼 Xcode와 통합되면 의존성을 충족할 수 없는 경우 Xcode 빌드가 실패합니다. 이것은 기능을 개발할 때 빠른 피드백과 반복 주기를 허용합니다. 앱을 실행하지 않고 개발자는 DI 그래프가 올바르지 않을 수 있는 부분을 디버그할 수 있습니다. 이러한 보장을 통해 개발자는 자신 있게 DI 코드를 작성하고 수정할 수 있습니다. Xcode 빌드가 성공하면 DI 코드에 대한 변경 사항이 올바른 것입니다.

## High-level algorithm overview

대략적으로 제네레이터는 5단계로 실행됩니다. 

1. 제네레이터는 [SourceKittenFramework](https://github.com/jpsim/SourceKitten)를 통해 SourceKit을 사용하여 개발자가 작성한 모든 소스 Swift 파일을 구문 분석합니다. 이를 통해 제네레이터는 모든 `Component` 노드의 메모리 내 캐시와 DI 그래프의 정점을 나타내는 `Dependency` 프로토콜을 생성할 수 있습니다.

2. 제너레이터는 모든 `Component` 노드의 부모-자식 관계를 서로 연결합니다. 이 작업은 어떤 `Component`가 다른 `Component`를 인스턴스화하는지 살펴봄으로써 수행됩니다.
    ```swift
    class LoggedInComponent: Component<LoggedInDependency> {
        var gameComponent: GameComponent {
            return GameComponent(parent: self)
        }
    }
    ```
    Needle의 제네레이터는 위의 Swift 코드를 구문 분석하여 `LoggedInComponent`가 `GameComponent`의 부모임을 추론합니다.

3. `Dependency` 프로토콜에 선언된 각 `Component`의 의존성에 대해, 제네레이터는 해당 `Component`에서 시작하여 위쪽으로 이동하며 의존성 객체를 찾기 위해 모든 상위 `Component`를 방문합니다. 의존성 객체는 속성의 변수 이름 및 유형이 **모두** 일치하는 경우에만 발견됩니다. 제네레이터는 위쪽으로 이동하기 때문에 맨 위에 있는 DI 그래프의 루트에서 볼 때 가장 낮은 수준과 가장 가까운 의존성 객체가 항상 사용됩니다. 이 단계에서 의존성을 충족하는 객체를 찾을 수 없는 경우, 제네레이터는 위 섹션에서 설명한 것과 같은 형태의 오류를 반환합니다. 의존성을 충족하는 객체가 발견되면 제네레이터는 다음 단계에서 사용할 경로를 메모리에 저장합니다.

4. 제네레이터는 `Component`의 `Dependency` 프로토콜을 준수하는 `DependencyProvider` 클래스를 생성하여 이전 단계에서 찾은 경로를 통해 의존성을 제공합니다. 이렇게 생성된 클래스는 두 번째 수준의 컴파일 시간 안전성도 제공합니다. 어떤 이유로든 이전 단계에서 경로가 잘못 생성된 경우, 생성된 `DependencyProvider`클래스는 `Dependency` 프로토콜 따르지 않기 때문에 컴파일되지 않습니다. 생성된 각 `DependencyProvider`에 대해 provider가 제공하는 `Component`로 연결되는 DI 그래프 경로에 대한 provider 등록 코드도 생성됩니다. 이것은 우리가 Needle의 [API](./API.md)에서 이야기하는 `registerProviderFactories` 메소드의 출처입니다.

5. 생성된 모든 `DependencyProvider` 클래스는 등록 코드와 함께 Swift 파일로 생성 됩니다. 이 Swift 파일은 다른 소스 파일과 마찬가지로 Xcode 프로젝트에 포함되어야 합니다.

## 설치

제네레이터는 [Carthage](https://github.com/Carthage/Carthage) 또는 [Homebrew](https://github.com/Homebrew/brew)로 설치 할 수 있습니다.

#### [Carthage](https://github.com/Carthage/Carthage) 사용 시

표준 [카르타고 설치 절차](https://github.com/Carthage/Carthage#quick-start)를 따릅니다.
```
github "https://github.com/uber/needle.git" ~> VERSION_OF_NEEDLE
```

카르타고 빌드가 완료되면, 제네레이터 바이너리는 `Carthage/Checkouts/needle/Generator/bin/needle`에 위치합니다.

#### [Homebrew](https://github.com/Homebrew/brew) 사용 시

```
brew install needle
```

설치가 된 완료 제네레이터 바이너리는 `$ needle version`와 같이 사용할 수 있습니다.

## Xcode 통합

Needle의 제네레이터는 명령줄에서 호출할 수 있지만 빌드 시스템과 직접 통합될 때 가장 편리합니다. Uber에서는 CI 빌드에 [BUCK](https://buckbuild.com/)를 사용하고 로컬 개발에 Xcode를 사용합니다. 따라서 우리에게 Needle은 BUCK와 통합됩니다. 그런 다음 Xcode가 코드 생성을 위해 BUCK Needle 대상을 호출하도록 합니다. 대부분의 Swift 애플리케이션이 Xcode를 빌드 시스템으로 사용하기 때문에 여기서는 이를 다룰 것입니다.

1. [Releases page](https://github.com/uber/needle/releases)에서 수동으로 다운로드 혹은 [Carthage](https://github.com/Carthage/Carthage) 또는 [Homebrew](https://github.com/Homebrew/brew)를 사용하여 최신 제네레이터 바이너리를 다운로드 하십시오.
2. Xcode에서 앱의 executable target's의 "Build Phases" 섹션의 "Run Script"를 추가합니다. ![](Images/build_phases.jpeg)
3. "Shell"의 값이 `/bin/sh`으로 되어 있는지 확인합니다.
4. 스크립트 입력란에 제네레이터를 호출하는 shell script를 추가합니다. 예를 들어 샘플 TicTacToe 앱은 다음 스크립트를 사용합니다.  
 `export SOURCEKIT_LOGGING=0 && ../Carthage/Checkouts/needle/Generator/bin/needle generate Sources/NeedleGenerated.swift Sources/ --header-doc ../../copyright_header.txt`.
    * 만약 Carthage를 통해 설치한 경우 Xcode 프로젝트 파일이 있는 위치를 기준으로 Carthage Checkouts 디렉토리에 있는 바이너리를 호출할 수 있습니다. 샘플에서 이 경로는 `../Carthage/Checkouts/needle/Generator/bin/needle generate`입니다.
    * 만약 Homebrew를 통해 설치된 경우 `needle generate`를 직접 호출하여 바이너리를 실행할 수 있습니다.

스크립트의 첫번째 명령어인 `export SOURCEKIT_LOGGING=0`는 SourceKit 로깅이 보이지 않도록 설정합니다. 만약 해당 명령어를 실행하지 않으면 Xcode는 로그를 오류 메시지로 표시합니다. 이것은 단순히 Xcode에서 노이즈를 줄이기 위한 것입니다. 꼭 필요한 것은 아닙니다. 나머지 스크립트는 몇 가지 인수와 함께 제네레이터 실행 파일을 호출합니다.

만약 제네레이터가 Carthage를 통해 설치된 경우 제네레이터 실행 바이너리의 경로는 Xcode 프로젝트의 위치에 상대적이라는 점을 명심하십시오.  
샘플 앱에서 경로는 `../Carthage/Checkouts/needle/Generator/bin/needle`입니다.
 이는 프로젝트의 폴더 구조에 따라 다를 수 있습니다.

- 첫 번째 인수 `generate`는 코드 생성 명령을 실행하도록 실행 파일에 지시합니다.
- 두 번째 인수 `Sources/NeedleGenerated.swift`는 생성자에게 생성된 코드를 해당 경로에 파일로 생성하도록 지시합니다.
- 세 번째 인수 `Sources/`는 모든 애플리케이션 소스 코드가 구문 분석을 위한 위치를 제네레이터에 알려줍니다.
- 마지막 선택적 인수인 `--header-doc`은 생성된 코드가 포함된 내보낸 파일의 헤더 문서로 지정된 파일의 텍스트를 사용하도록 제네레이터에 지시합니다.

  *가능한 모든 매개변수는 아래 섹션을 참조하십시오.*

이것이 Xcode에 통합하기 위한 전부 입니다. 이제 Xcode가 애플리케이션을 빌드할 때마다 Needle의 제네레이터가 실행되어 필요한 DI 코드를 생성하고 출력합니다.

## Generator parameters

### 사용 가능한 명령어

`generate`: 제네레이터에 Swift 소스 파일을 구문 분석하고, DI 코드를 생성하고, 지정된 대상 파일로 내보내도록 지시합니다.
`version` 제네레이터의 현재 버전을 보여줍니다.

### `generate` command

#### 필수 위치 경로 파라미터(Required positional parameters)

1. 생성된 Swift DI 코드의 대상 파일 경로입니다. (예시: `Sources/NeedleGenerated.swift`)
    - 해당 경로는 Xcode 프로젝트의 상대 경로를 기준으로 합니다.
2. Swift 소스 파일의 루트 폴더에 대한 경로 또는 지정된 형식의 Swift 소스 파일 경로가 포함된 텍스트 파일입니다. 경로의 개수는 얼마든지 지정할 수 있습니다. 모든 소스 목록 파일은 동일한 형식이어야 합니다. 소스 목록 파일에 대한 자세한 내용은 아래를 참조하십시오. 예를 들어, `Sources/sources_list_file.txt`는 "Sources" 디렉토리 내의 모든 Swift 소스 파일과 "sources_list_file.txt" 파일에 포함된 소스 경로를 재귀적으로 구문 분석하도록 제네레이터에 지시합니다.

#### 소스 파일 목록(Sources list file)

제네레이터는 디렉토리와 파일 둘다 분석할 수 있습니다. 디렉토리로 지정된 경우, 하위 디렉터리에 있는 파일을 포함하여 디렉터리 내의 모든 Swift 파일을 구문 분석할 수 있습니다. 또는 파일이 지정된 경우, 제네레이터는 해당 파일이 Swift 소스 파일 경로 목록을 포함하는 텍스트 파일이라고 가정합니다. 이 파일을 소스 목록 파일(sources list file)이라고 합니다.

이 파일에는 `newline`과 `minescaping`의 두 가지 형식이 지원됩니다.
- `newline` 형식을 사용하면 제네레이터는 소스 목록 파일의 각 행이 구문 분석할 Swift 소스 파일에 대한 단일 경로라고 가정합니다.
- `minescaping` 형식은 이스케이프가 필요한 경우 경로가 작은 따옴표로 이스케이프되도록 지정하고 이스케이프가 필요하지 않은 경로는 따옴표로 묶지 않습니다. 모든 경로는 단일 공백 문자로 구분됩니다.

필요한 경우 `--sources-list-format` 옵션 매개변수를 사용하여 형식을 지정합니다.
```shell
--sources-list-format minescaping # or newline
```

만약 여러개의 소스 목록 파일이 `generate`명령에 제공되는 경우 모두 동일한 형식을 가져야 합니다.

#### Optional parameters

`--sources-list-format`: Swift 소스 목록 파일의 형식입니다. 이 매개변수를 지정하지 않으면 모든 소스 목록 파일이 `newline` 형식을 사용하는 것으로 가정합니다. 자세한 내용은 위의 [소스 목록 파일](#소스-파일-목록sources-list-file) 섹션을 참조하세요.

`--exclude-suffixes`: 구문 분석을 위해 무시할 파일 이름 접미사 목록입니다. 예를 들어 `--exclude-suffixes Tests Mocks`를 사용하면 제네레이터는 파일 확장자를 제외한 이름이 "Test" 또는 "Mocks"로 끝나는 모든 파일을 무시합니다.

`--exclude-paths`: 구문 분석을 위해 무시할 경로 문자열 목록입니다. 예를 들어 `--exclude-paths /sample /tests`를 사용하면 제네레이터는 경로에 "/sample" 또는 "/tests"가 포함된 파일을 무시합니다.

`--header-doc`: 콘텐츠가 생성된 DI 코드 파일의 헤더 문서로 사용되는 텍스트 파일의 경로입니다. TicTacToe 샘플에서는 `--header-doc ../../copyright_header.txt`를 지정하여 생성된 파일에 저작권 헤더를 추가합니다.

`--additional-imports`: 생성된 DI 코드에 포함할 추가적인 import 문. Needle의 제네레이터는 생성된 코드에서 `Component` 및 `Dependency` 구성을 포함하는 Swift 소스 파일의 모든 import 문을 자동으로 구문 분석하고 포함합니다. Uber에서 내부적으로 사용되는 것과 같은 특정 모듈 구조에서는 최상위 모듈을 직접 가져오지 않습니다. 따라서 이 매개변수를 사용하면 생성된 파일이 최상위 모듈을 올바르게 가져올 수 있습니다. 예를 들어, Uber의 Rider 앱의 경우 `import Rider`가 지정됩니다.

`--pluginized`: 만약 지정된 경우 제네레이터는 플러그인 기반 DI 그래프를 구문 분석하고 생성합니다. 이것은 일반적으로 유용하지 않습니다. Uber의 플러그인 아키텍처는 이것을 사용합니다.

`--collect-parsing-info`: 실행 시간 초과 오류를 구문 분석하기 위해 정보를 수집해야 하는지 여부를 나타내는 부울 값입니다. 기본값은 `false`입니다.

`--timeout`: 작업 구문 분석 및 생성 대기 시 사용할 시간 초과 값(초)입니다. 기본값은 30초입니다.

`--concurrency-limit`: 동시에 실행할 최대 작업 수입니다. 기본값 하드웨어에서 허용하는 최대 동시성 입니다.

## 생성된 코드 통합

### 생성된 파일로 포함

생성된 DI 코드를 앱의 바이너리에 포함하려면 생성된 파일이 Xcode 프로젝트에 포함되어야 합니다. Uber에서 사용하는 BUCK에서는 단순히 Needle의 제네레이터 타겟을 `srcs` 매개변수에 포함하기만 하면 됩니다.
```swift
srcs = glob([
    "Sources/**/*.swift",
]) + [":Needle"],
```

Xcode 프로젝트의 경우 처음 한번은 설정을 수행해야 합니다. Needle 제네레이터 명령이 실행되면 위에서 설명한 Xcode 빌드 단계 통합 또는 명령줄을 통해 생성된 파일을 바이너리 대상으로 끌어다 놓기만 하면 됩니다. TicTacToe 샘플에서는 `NeedleGenerated.swift` 파일을 `TicTacToe` 타겟에 포함하고 있습니다.

### 생성된 코드 실행

Needle이 생성한 DI 코드는 애플리케이션이 사용할 수 있는 간단한 단일 진입점을 제공합니다. 생성된 파일은 애플리케이션이 시작 시 첫 번째 단계로 호출해야 하는 단일 메서드 `public registerProviderFactories`를 노출합니다.
일반적인 iOS 애플리케이션에서 이것은 단순히 `AppDelegate`에서 이 메소드를 호출하는 것을 의미합니다. 예를 들어 포함된 TicTacToe 샘플 앱에서는 이를 다음과 같이 호출합니다.
```swift
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        registerProviderFactories()
        /// Other logic below.
        ...
    }
```

Uber가 사용하는 것과 같은 더 복잡한 애플리케이션 구조의 경우 별도의 `main.swift` 파일이 사용됩니다. 이 경우에도 동일하게 적용됩니다. `main.swift` 파일에서 가장 먼저 `registerProviderFactories()`를 호출합니다.
