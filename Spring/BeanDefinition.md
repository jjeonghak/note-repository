## BeanDefinition(빈 설정 메타 정보)
BeanClassName : 생성할 빈의 클래스 명(팩토리 역할의 빈 사용시 없음)  
factoryBeanName : 팩토리 역할의 빈을 사용할 경우의 이름  
factoryMethodName : 빈을 생성할 팩토리 메서드 지정  
Scope : 싱글톤(default)  
lazyInit : 스프링 컨테이너를 생성할 때 빈을 생성하는 것이 아니라, 실제 빈을 사용할 때까지 생성 지연여부  
InitMethodName : 빈을 생성하고 의존관계를 적용한 뒤에 호출되는 초기화 메서드 명  
DestroyMerhodName : 빈 제거 직전에 호출되는 소멸자 메서드 명  
Constructor arguments, Properties : 의존관계 주입에서 사용  

````java
public class BeanDefinitionTest {

    //빈 설정 메타 정보는 ApplicationContext 인터페이스가 아닌 구현체 내에서 확인가능
    AnnotationConfigApplicationContext ac = new AnnotationConfigApplicationContext(AppConfig .class);

    @Test
    @DisplayName("check bean definition")
    void findApplicationBean() {
        String[] beanDefinitionNames = ac.getBeanDefinitionNames();
        for (String beanDefinitionName : beanDefinitionNames) {
            BeanDefinition beanDefinition = ac.getBeanDefinition(beanDefinitionName);

            if (beanDefinition.getRole() == BeanDefinition.ROLE_APPLICATION) {
                System.out.println("beanDefinitionName = " + beanDefinitionName +
                        " beanDefinition = " + beanDefinition);
            }
        }
    }
}
````

<br>

