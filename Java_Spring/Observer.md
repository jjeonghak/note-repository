## 옵저버 패턴
어떤 이벤트가 발생한 경우 주제(subject)가 다른 객체 리스트(observer)에 자동으로 알림 전송  
GUI 어플리케이션에 자주 사용  

````java
interface Observer {
    void notify(String tweet);
}

interface Subject {
    void registerObserver(Observer o);
    void notifyObserver(String tweet);
}
````

<br>

### 트윗에 포함된 다양한 키워드에 다른 동작을 하는 여러 옵저버
````java
class NYTimes implements Observer {
    public void notify(String tweet) {
        if (tweet != null && tweet.contains("keyword1")) {
            System.out.println("Breaking news in NY! " + tweet);
        }
    }
}

class Guardian implements Observer {
    public void notify(String tweet) {
        if (tweet != null && tweet.contains("keyword2")) {
            System.out.println("Yet more news from London... " + tweet);
        }
    }
}

class LeMonde implements Observer {
    public void notify(String tweet) {
        if (tweet != null && tweet) {
            System.out.println("Today cheese, wine and news! " + tweet);
        }
    }
}
````

<br>

### 주제
````java
class Feed implements Subject {
    private final List<Observer> observers = new ArrayList<>();
    
    public void registerObserver(Observer o) {
        this.observers.add(o);
    }
    
    public void notifyObserver(String tweet) {
        observers.forEach(o 0> o.notify(tweet));
    }
}

Feed f = new Feed();
f.registerObserver(new NYTimes());
f.registerObserver(new Guardian());
f.registerObserver(new LeMonde());
f.notifyObservers("This feed has keyword1, keyword2 and keyword3");
````

<br>

## 람다 사용
Observer 인터페이스 구현하는 모든 클래스는 notify 메서드만 구현  
옵저버를 명시적으로 인스턴스화하지 않고 람다 표현식 사용  
옵저버가 상태를 가지고 여러 메서드를 정의한다면 기존의 클래스 구현 방식을 고수  

````java
f.registerObserver((String tweet) -> {
    if (tweet != null && tweet.contains("keyword")) {
        System.out.println("Breaking news in NY! " + tweet);
    }
});
````

<br>
