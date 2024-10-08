## 전략 패턴
템플릿 메서드 패턴의 상속의 단점을 보완한 디자인 패턴  
변하지 않는 부분은 Context, 변하는 부분을 Strategy 인터페이스로 선언  
상속이 아닌 위임으로 문제 해결  
알고리즘 제품군을 정의하고 각각을 캡슐화하여 상호 교환 가능하게 설계  
문맥(context)은 변하지 않지만 그 안에서 위임받은 전략(strategy)이 변함  

<br>

### 전략 인터페이스
````java
    public interface Strategy {
        void call();
    }
````

<br>

### 필드 저장 방식
````java
public class ContextV1 {

private Strategy strategy;

public ContextV1(Strategy strategy) {
    this.strategy = strategy;
}

public void execute() {
    long startTime = System.currentTimeMillis();
    strategy.call(); //위임
    long endTime = System.currentTimeMillis();
    log.info("logic1 run time: {}", endTime - startTime);
}
}
````

<br>

### 파라미터 주입 방식
````java
public class ContextV2 {
public void execute(Strategy strategy) {
    long startTime = System.currentTimeMillis();
    strategy.call(); //위임
    long endTime = System.currentTimeMillis();
    log.info("logic run time: {}", endTime - startTime);
}
}
````

<br>

## 익명 내부 클래스
인터페이스 구현을 익명 내부 클래스로 구현

````java
Strategy strategyLogic = new Strategy() {
@Override
public void call() {
    log.info("logic start");
}
};
ContextV1 context = new ContextV1(strategyLogic);
context.execute();
````

<br>

## 람다
익명 내부 클래스를 변수로 사용하기보단 람다로 간결하게 사용가능  
람다로 변경시 인터페이스의 메서드가 하나만 존재해야 가능  

````java
ContextV1 context = new ContextV1(() -> log.info("logic start"));
context.execute();
````

<br>

