## AppConfig
DI 컨테이너, IoC 컨테이너, 어셈블러, 오브젝트 팩토리  

<br>

## @Configuration
바이트 코드를 조작하는 CGLIB 기술 사용  
컨테이너는 일반적인 class AppConfig 파일이 아닌 AppConfig@CGLIB 파일을 빈으로 등록  
인스턴스 객체는 AppConfig@CGLIB, 클래스는 AppConfig 상속  
AppConfig@CGLIB 빈이 싱글톤 보장  
@Bean 어노테이션만 사용해도 빈 등록은 되지만 @Configuration 어노테이션이 있어야 싱글톤 보장  

````java
public class AppConfig@CGLIB implements AppConfig {

    @Bean
    public ClassType beanClass() {

        if (스프링 컨테이너에 beanClass 등록여부) {
            //스프링 컨테이너에서 찾은 후 반환;
            return beanClass 
        } else {
            //기본 생성자 호출
            //스프링 컨테이너에 등록
            return beanClass
        }
    }
}
````

<br>

## 수동 빈 등록
애플리케이션은 크게 업무로직과 지원로직으로 분류  

    업무 로직 빈 : 웹을 지원하는 컨트롤러, 핵심 비지니스 로직이 있는 서비스, 데이터 계층의 로직 모두 업무 로직  
                빈의 갯수도 많고 정형화된 패턴 존재하므로 자동 등록 기능 사용  
    
    기술 지원 빈 : 기술적인 문제나 공통 관심사(AOP)를 처리할 때 주로 사용  
                업무 로직과 비교해서 갯수가 적고 영향력이 광범위하므로 가급적 수동 등록으로 명확하게 사용  

<br>


## AppConfig.class
````java
//팩토리 메서드 방식, 외부에서 메소드를 호출하여 객체를 생성하는 방식
@Configuration
public class AppConfig {

    @Bean
    public MemoryMemberRepository memberRepository() {
        return new MemoryMemberRepository();
    }

    @Bean
    public DiscountPolicy discountPolicy() {
        return new RateDiscountPolicy();
    }

    @Bean
    public MemberService memberService() {
        return new MemberServiceImpl(memberRepository());
    }

    @Bean
    public OrderService orderService() {
        return new OrderServiceImpl(memberRepository(), discountPolicy());
    }
}
````

<br>

## appConfig.xml
````xml
<?xml version="1.0" encoding="UTF-8" ?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd" >
       
    <bean id="memberService" class="com.example.core.member.MemberServiceImpl">
        <constructor-arg name="memberRepository" ref="memberRepository" />
    </bean>

    <bean id="memberRepository" class="com.example.core.member.MemoryMemberRepository"/>

    <bean id="orderService" class="com.example.core.order.OrderServiceImpl" >
        <constructor-arg name="memberRepository" ref="memberRepository" />
        <constructor-arg name="discountPolicy" ref="discountPolicy" />
    </bean>

    <bean id="discountPolicy" class="com.example.core.discount.RateDiscountPolicy"/>
    
</beans>
````

<br>
