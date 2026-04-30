## 의무 체인 패턴
작업 처리 객체의 체인을 만드는 경우 사용  
한 객체가 어떤 작업을 처리한 후 다른 객체로 결과를 반환  

````java
public abstract class ProcessingObject<T> {
    protected ProcessingObject<T> successor;
    
    public void setSuccessor(ProcessingObject<T> successor) {
        this.successor = successor;
    }
    
    public T handle(T input) {
        T r = handleWork(input);
        if (successor != null) {
            return successor.handle(r);
        }
        return r;
    }
    
    abstract protected T handleWork(T input);
}
````

<br>

### 체인 구현
````java
public class HeaderTextProcessing extends ProcessingObject<String> {
    public String handleWork(String text) {
        return "From Raoul, Mario and Alan: " + text;
    }
}

public class SpellCheckerProcessing extends ProcessingObject<String> {
    public String handleWork(String text) {
        return text.replaceAll("labda", "lambda");
    }
}
````

<br>

### 작업 처리 객체를 연결해서 작업 체인 생성
````java
ProcessingObject<String> p1 = new HeaderTextProcessing();
ProcessingObject<String> p2 = new SpellCheckerProcessing();
p1.setSucessor(p2); //두 작업 처리 객체 연결
String result = p1.handle("Aren't labdas really sexy?");
System.out.println(result);
````

<br>
    
## 람다 사용
람다 표현식을 조합하여 구현 가능  

````java
UnaryOperator<String> headerProcessing = 
    (String text) -> "From Raoul, Mario and Alan: " + text;
UnaryOperator<String> spellCheckerProcessing = 
    (String text) -> text.replaceAll("labda", "lambda");
Function<String, String> pipeline = 
    headerProcessing.andThen(spellCheckerProcessing);
String result = pipeline.apply("Aren't labdas really sexy?");
````

<br>

