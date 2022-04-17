# Needle Foundation Library

## Building and developing

먼저 의존성을 리졸브 합니다.

```
$ swift package update
```

그 다음 command-line을 사용하여 빌드 합니다.

```
$ swift build
```

또는 Xcode 프로젝트를 만들고 IDE를 사용하여 빌드 합니다.

```
$ swift package generate-xcodeproj --xcconfig-overrides foundation.xcconfig
```
참고: 지금은 xcconfig를 사용하여 iOS deployment target settings를 전달하고 있습니다.

**처음 Swift Package Manager를 사용하여 Xcode 프로젝트가 생성되면 `NeedleFoundation` 프레임워크와 `NeedleFoundationTests` 테스트 타겟 모두에 대해 Xcode 프로젝트 스킴를 다시 만들어야 합니다.** 
이는 Carthage 및 CI를 위해 필요합니다.

## 폴더 구조

다른 프로젝트가 Swift Package Manager를 통해 `NeedleFoundation`에 의존하게 하려면 foundation 프로젝트가 저장소의 루트에 있어야 합니다. 동시에 폴더 구조에 대한 SPM의 엄격한 요구 사항으로 인해 `Sources` 폴더와 같이 기본 라이브러리에 더 특정한 폴더 이름을 지정할 수 없습니다.