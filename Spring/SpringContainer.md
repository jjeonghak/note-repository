## SpringContainer
객체(Bean)의 생성에서 소멸까지 전체 수명 주기를 관리  
개발자를 대신하여 메서드가 호출될 때 필요한 자원을 전달하는 IoC 구조  
필요한 자원을 런타임에 의존관계에 따라 전달하는 DI  
다양한 형식의 설정 정보를 모두 BeanDefinition 인터페이스로 받아들이는 유연성(Java, XML, Groovy 등)  

<br>

## 생성과정
1. 스프링 컨테이너 생성  
2. 스프링 빈 등록  
3. 스프링 빈 의존관계 주입  

<br>

## BeanFactory
스프링 컨테이너의 최상위 인터페이스  
스프링 빈을 관리하고 조회하는 역할을 담당  

<br>

## ApplicationContext

### BeanFactory기능을 모두 상속  

    ListableBeanFactory
    HierarchicalBeanFactory

<br>

### 부가적인 인터페이스도 상속  

    MessageSource : 메시지소스를 활용한 국제화 기능, input 언어에 따라 output 언어 제공
    EnvironmentCapable : 환경변수(로컬, 개발, 운영)를 구분해서 처리
    ApplicationEventPublisher : 애플리케이션 이벤트를 발행하고 구독하는 모델 지원
    ResourceLoader : 파일, 클래스패스, 외부 등에서 리소스를 편리하게 조회

<br>

### 다양한 형식의 구현체로 유연성 제공

    AnnotationConfigApplicationContext 
      AnnotateBeanDefinitionReader를 통해서 AppConfig.class 파일을 읽고 BeanDefinition 생성

    GenericXmlApplicationContext
      XmlBeanDefinitionReader를 통해서 appConfig.xml 파일을 읽고 BeanDefinition 생성

    XxxApplicationContext 
      XxxBeanDefinitionReader를 통해서 appConfig.xxx 파일을 읽고 BeanDefinition 생성

<br>
