## RxJava
자바로 리액티브 어플리케이션을 구현할때 사용하는 라이브러리  
RxJava는 넷플릭스의 Reactive Extensions(Rx) 프로젝트의 일부로 시작  
Flow.Publisher를 구현하는 두 클래스 제공  
리액티브 당김 기반 역압력 기능이 있는 io.reactivex.Flowable  
역압력을 지원하지 않는 기존 버전의 io.reactivex.Observable  
천 개 이하 요소의 스트림, 마우스 및 터치 등 GUI 이벤트, 발생 빈도가 낮은 이벤트에 역압력 적용 권장하지 않음  
모든 구독자는 구독 객체의 request(Long.MAX_VALUE) 메서드를 이용해서 역압력 해제 가능  
Observable 클래스는 Publisher, Observer 클래스는 Subscriber 역할 감당  
Observable 클래스는 역압력이 없는 Push 기법  

<br>

## Observable
just() 팩토리 메서드를 이용해서 생성 가능  
한 개 이상의 요소를 이용해 이를 방출하는 Observable 객체로 변환  
사용자와 실시간으로 상호작용하면서 지정된 속도로 이벤트를 방출하는 상황에선 interval 메서드  
RxJava는 플로보다 유연  
Comsuner의 onNext 메서드만 람다로 구현하고 나머지 완료, 오류 메서드는 기본 동작으로 구현 가능  
기본적으로 데몬 스레드를 이용하므로 main 스레드 종료시 같이 종료  
Emitter 인터페이스는 Disposable 설정 메서드와 시퀀스가 이미 다운스트림 폐기 여부 메서드 제공  

````java
public interface Observer<T> {
    void onSubscribe(Disposable d);
    void onNext(T t);
    void onError(Throwable t);
    void onComplete();
}

public interface Emitter<T> {
    void onNext(T t);
    void onError(Throwable t);
    void onComplete();
}

Observable<String> strings = Observable.just("first", "second");
Observable<Long> onePerSec = Observable.interval(1, TimeUnit.SECONDS);

//람다로 onNext 메서드만 구현
onePerSec.subscribe(i -> System.out.println(TempInfo.fetch("New York")));
onePerSec.blockingSubscribe(i -> System.out.println(TempInfo.fetch("New York")));

public static Observable<TmepInfo> getTemperature(String town) {
    return Observable.create(
        emitter -> Observable.interval(1, TimeUnit.SECONDS)
            .subscribe(i -> {
                if (!emitter.isDisposed()) {
                    if (i >= 5) {
                        emitter.onComplete();
                    } else {
                        try {
                            emitter.onNext(TempInfo.fetch(town));
                        } catch (Exception e) {
                            emitter.onError(e);
                        }
                    }
                }
            }));
}

public class TempObserver impelements Observer<TempInfo> {
    @Override
    public void onComplete() {
        System.out.println("Done");
    }
    
    @Override
    public void onError(Throwable throwable) {
        System.out.println("Error: " + throwable.getMessage());
    }
    
    @Override
    public void onSubscribe(Disposable disposable) {
        
    }
    
    @Override
    public void onNext(TempInfo tempInfo) {
        System.out.println(tempInfo);
    }
}

public class Main {
    public static void main(String[] args) {
        Observable<TempInfo> observable = getTemperature("New York");
        observable.blockingSubscribe(new TempObserver());
    }
}
````

<br>

## Observable 변환 및 병합
Flow.Processor 인터페이스보다 유연하고 복잡한 기능 제공  

### 변환
````java
public static Observer<TempInfo> getCelsiusTemperature(String town) {
    return getTemperature(town)
        .map(temp -> new TempInfo(temp.getTown(), (temp.getTemp() - 32) * 5 / 9);
}
````
    
### 병합
````java
public static Observable<TempInfo> getCelsiusTemperatures(String... towns) {
    return Observable.merge(Arrays.stream(towns)
        .map(TempObservable::getCelsiusTemperature)
        .collect(toList()));
}
````

<br>

