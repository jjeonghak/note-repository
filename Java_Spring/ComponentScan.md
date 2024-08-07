## @ComponentScan
컴포넌트 스캔 기본 대상  

      @Component : 컴포넌트 스캔에 사용
      @Controller : 스프링 MVC 컨트롤러로 인식
      @Service : 스프링 비즈니스 로직에서 사용, 특별한 처리를 하지 않지만 개발자들에게 핵심 비즈니스 로직위치로 인지
      @Repository : 스프링 데이터 접근 계층으로 인식, 데이터 계층의 예외를 스프링 예외로 변환
      @Configuration : 스프링 설정 정보에서 사용, 싱글톤 유지
    
@Component 어노테이션이 붙은 모든 클래스를 스프링 빈으로 등록  
스프링 빈의 등록 이름은 클래스명을 사용하지만 맨 앞글자를 소문자로 변경  

      MemberServiceImpl(클래스명) -> memberServiceImpl(빈 등록명)

직접 빈 이름 지정가능 @Component("memberServiceImpl")  
@Autowired 어노테이션이 붙은 생성자에 한해 의존관계 자동 주입  
기본 조회 전략은 같은 타입의 빈을 찾아서 주입  
  
    basePackages : 탐색할 패키지 시작 위치 지정, 이 패키지를 포함하여 하위 패키지까지 탐색
    basePackageClasses : 지정한 클래스의 패키지를 탐색 시작 위치로 지정
                        지정하지 않을 경우 @ComponentScan 어노테이션이 붙은 설정 정보 클래스의 패키지
    includeFilters : 컴포넌트 스캔 대상을 추가로 지정
    excludeFilters : 컴포넌트 스캔에서 제외할 대상 지정
    
    @ComponentScan.Filter 타입
            type = FilterType.ANNOTATION : default 값, 어노테이션을 인식해서 동작
            type = FilterType.ASSIGNABLE_TYPE : 지정한 타입과 자식 타입을 인식해서 동작
            type = FilterType.ASPECYJ : AspectJ 패턴 사용
            type = FilterType.REGEX : 정규 표현식
            type = FilterType.CUSTOM : TypeFilter 인터페이스를 구현해서 처리

<br>
    
## 스프링 빈 중복 등록과 충돌
자동과 자동 빈 등록 충돌 : 같은 이름의 스프링 빈이 등록된 경우 스프링 오류발생  

      ConflictingBeanDefinitionException 예외발생

수동과 자동 빈 등록 충돌 : 수동 빈 등록이 우선순위가 높음, 최근 스프링 부트는 오류발생  

      Overriding bean definition
      spring.main.allow-bean-definition-overriding=true 설정시 스프링 부트 오류발생안함

<br>
