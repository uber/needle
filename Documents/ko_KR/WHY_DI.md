# 의존성 주입을 사용하는 이유는 무엇입니까?

이 문서에서는 의존성 주입 패턴의 기본 사항, 무엇이며 앱 개발에 적용하기에 좋은 패턴인 이유를 설명합니다. 아래 본문에서는 DI라는 용어를 의존성 주입의 줄임말로 사용합니다.

## 설명하기 위한 다소 현실적인 예

패턴을 추상적인 용어로 설명하는 대신 간단한 뷰 컨트롤러 기반 예를 사용하여 패턴을 이해해 보겠습니다. 추상적인 설명에 관심이 있으시면 Wikipedia에는 [훌륭한 기사](https://en.wikipedia.org/wiki/Dependency_injection)가 있습니다.

서버에서 검색한 사진 세트를 표시하는 뷰 컨트롤러가 있는 사진 검색 앱을 개발 중이라고 가정해 보겠습니다. 이 매우 간단한 앱에는 사진을 표시하는 `PhotosViewController`와 서버에서 사진을 요청하는 로직를 캡슐화하는 `PhotosService`가 있습니다. `PhotosViewController`는 보기 로직을 ​​구현하고 `PhotosService`는 HTTP 요청 전송 및 응답 분석 로직을 포함합니다. DI를 사용하지 않으면 `PhotosViewController`는 `init` 또는 `viewDidLoad` 메소드에서 `PhotosService`의 새 인스턴스를 인스턴스화 합니다. 그런 다음 서비스 객체를 사용하여 적합하다고 판단될 때 사진을 요청할 수 있습니다.

이제 뒤로 물러나 코드를 분석해 보겠습니다. 현재 상태에서는 `PhotosViewController`와 `PhotosService`가 밀접하게 결합되어 있습니다. 이것은 우리에게 몇 가지 문제를 남깁니다.
1. `PhotosViewController`도 변경하지 않고는 `PhotosService`를 변경할 수 없습니다. 두 개의 클래스만 있으면 괜찮아 보일 수 있지만 수백 개의 클래스가 있는 실제 시나리오에서는 앱 반복 속도가 크게 느려집니다.
2. `PhotosViewController`를 변경하지 않고 `PhotosService` 클래스를 전환할 수 없습니다. 이제 뷰 컨트롤러에서 사용하려는 더 나은 `PhotosServiceV2` 클래스가 있다고 가정해 보겠습니다. 변경하려면 `PhotosViewController` 구현을 파헤쳐야 합니다.
3. `PhotosService` 구현을 호출하지 않고 `PhotosViewController`를 단위 테스트할 수 없습니다.
4. `PhotosViewController`를 `PhotosService`와 독립적으로 동시에 개발할 수 없습니다. 이것은 매우 단순한 앱에서는 별 문제가 아닌 것처럼 보일 수 있지만 실제 팀에서는 엔지니어의 업무가 지속적으로 중단됩니다.

DI 패턴을 앱에 적용해 보겠습니다. DI를 사용하면 Needle의 용어로 `Component` 클래스라는 세 번째 클래스가 생겨 `PhotosService`를 인스턴스화하고 프로토콜로 `PhotosViewController`에 전달합니다. 이 프로토콜을 `PhotosServicing`이라고 부르겠습니다. 이제 `PhotosViewController`는 `PhotosService`의 구체적인 구현에 대해 더 이상 알지 못합니다. 단순히 전달된 `PhotosServicing` 프로토콜을 사용하여 로직을 수행합니다.

DI가 적용된 상태에서 이전에 있었던 문제를 다시 살펴보겠습니다.
1. `PhotosViewController`에 영향을 주지 않고 `PhotosService` 구현을 자유롭게 변경할 수 있습니다.
2. 구현이 여전히 `PhotosServicing` 프로토콜을 준수하는 한 DI `Component` 클래스를 업데이트하여 `PhotosServiceV2`를 인스턴스화하고 `PhotosViewController`에 전달할 수 있습니다. 이를 통해 뷰 컨트롤러에서 아무 것도 변경하지 않고도 사진 서비스 구현을 자유롭게 전환할 수 있습니다.
3. 모의 `PhotosServicing` 객체를 주입하여 `PhotosViewController`를 적절하게 단위 테스트할 수 있습니다.
4. `PhotosServicing` 프로토콜이 정의되는 즉시 `PhotosService` 및 `PhotosViewController` 구현을 독립적으로 동시에 개발할 수 있습니다.

## 의존성 주입 용어

계속 진행하기 전에 DI 패턴과 함께 자주 사용되는 몇 가지 용어를 정의하겠습니다. 위의 예제 앱에서 `PhotoService`는 일반적으로 "의존성"이라고 합니다. 우리의 `PhotosViewController` 클래스는 때때로 "종속" 또는 "소비자"라고 합니다. `PhotosServicing`의 인스턴스를 `PhotosViewController`에 전달하는 행위를 "주입"이라고 합니다. 요약하면, 우리의 간단한 DI 설정은 `PhotosServicing` 의존성을 소비자인 `PhotosViewController`에 주입합니다.