## Singleton
전역변수를 사용하지 않고 객체를 하나만 생성하도록 관리  
생성된 객체는 어디서나 참조가능  
한 클래스에 한 객체만 존재하도록 제한  
상태를 유지(stateful)하지않고 무상태(stateless)로 설계  

<br>

### 싱글톤 객체 구현  
````java
public class SingletonService {

    private static final SingletonService instance = new SingletonService();

    public static SingletonService getInstance() {
        return instance;
    }

    //외부에서 새롭게 메모리 할당하는 것을 방지
    private SingletonService() {
    }
}
````

<br>

### 싱글톤 객체 테스트
````java
public class Singletontest {

    @Test
    @DisplayName("DI container without spring")
    void pureContainer() {

        AppConfig appConfig = new AppConfig();
        //호출할 때마다 객체 생성
        MemberService memberService1 = appConfig.memberService();
        MemberService memberService2 = appConfig.memberService();
        //참조값이 다름
        Assertions.assertThat(memberService1).isNotSameAs(memberService2);
    }

    @Test
    @DisplayName("singleton container")
    void singletonContainer() {

        SingletonService singletonService1 = SingletonService.getInstance();
        SingletonService singletonService2 = SingletonService.getInstance();

        //equal : 값 비교
        //same : 참조 주소 비교(==)
        Assertions.assertThat(singletonService1).isSameAs(singletonService2);
    }

    @Test
    @DisplayName("spring container and singleton")
    void springContainer() {
        ApplicationContext ac = new AnnotationConfigApplicationContext(AppConfig.class);
        
        MemberService memberService1 = ac.getBean("memberService", MemberService.class);
        MemberService memberService2 = ac.getBean("memberService", MemberService.class);
        
        Assertions.assertThat(memberService1).isSameAs(memberService2);
    }
}
````

<br>
