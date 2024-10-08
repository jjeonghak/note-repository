## 템플릿 메서드 패턴
트랜잭션이나 로그 트레이스 같은 반복적이고 변하지 않는 코드를 비즈니스 로직과 분리  
비즈니스 로직을 제외한 다른 부분은 대부분 어디서나 반복적이고 동일한 코드 사용  
추상 클래스를 통해 동일한 코드를 추상메서드로 선언  
템플릿을 통해 공통된 코드를 몰아두고 call 메서드를 통해 비즈니스 로직 호출  
call 메서드는 자식 클래스에서 상속과 오버라이딩을 통해 구현  
execute 메서드를 통해서 비즈니스 로직 실행  
상속을 사용하므로 컴파일 시점에 부모 클래스와 자식 클래스가 강하게 결합되는 문제 발생  
템플릿 메서드 패턴의 상속의 단점을 해결한 디자인 패턴이 전략   

````java
@Slf4j
public abstract class AbstractTemplate {
    
    //시간 측정 템플릿
    public void execute() {
        long startTime = System.currentTimeMillis();
        call(); //상속을 통해 비즈니스 로직 실행
        long endTime = System.currentTimeMillis();
        log.info("logic1 run time: {}", endTime - startTime);
    }

    protected abstract void call();
}

@Slf4j
public class SubClassLogic1 extends AbstractTemplate {
    //실제 비즈니스 로직 상속 후 구현
    @Override
    protected void call() {
        log.info("logic1 start");
    }
}

@Test
void templateMethodV1() {
    AbstractTemplate template1 = new SubClassLogic1();
    template1.execute();
}
````

<br>

## 익명 내부 클래스를 사용한 템플릿 메서드 패턴
템플릿 메서드 패턴은 자식 클래스를 계속 만들어야하는 단점 존재  
템플릿 메서드 선언과 동시에 익명 내부 클래스로 자식 클래스 구현  

````java
@Test
void templateMethodV2() {
    AbstractTemplate template1 = new AbstractTemplate() {
        @Override
        protected void call() {
            log.info("logic1 start");
        }
    };
    template1.execute();
}
````

<br>

