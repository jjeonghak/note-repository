## 연관성
Observable&lt;T&gt;를 반환하는 Observable.from(Future&lt;T&gt;) 팩토리 메서드 존재  
Future&lt;T&gt; API는 내부적으로 블로킹(Future.get())  
고전적인 방식이므로 리액티브에선 필요 없음  
하지만 CompletableFuture는 Observable 같이 처리 가능  

````
1. 뜨거운 성질
  thenApply() 메서드와 같은 콜백을 등록했는지 여부에 관계없이 조급한 연산 시작

2. 캐시
  백그라운드 연산을 조급하게 수행하면 등록된 모든 콜백으로 결과를 전달
  수행 완료된 루 콜백을 등록해도 완료된 값으로 즉시 호출

3. 하나의 값 보장
  원칙적으로 Future<T>는 T형 값 또는 예외를 한번만 수행하고 완료
````

<br>

## Observable 변환
CompletableFuture&lt;T&gt;를 받아 Observable&lt;T&gt;로 변환 가능  
CompletableFuture는 즉시 연산을 시작하고 결과 캐시  

````java
class Util {
    static <T> Observable<T> observe(CompletableFuture<T> future) {
        return Observable.create(subscriber -> {
            future.whenComplete((value, exception) -> {  //exception이 null이 아니면 실패
                if (excetpion != null) {
                    subscriber.onError(exception);
                } else {
                    subscriber.onNext(value);
                    subscriber.onCompleted();
                }
            });
        });
    }
}

//잘못된 구독 해지 핸들러 등록
subscriber.add(Subscriptions.create(() -> future.cancel(true)));
````

<br>

## CompletableFuture 변환
1. Observable&lt;T&gt; -&gt; CompletableFuture&lt;T&gt;  
    스트림에서 단일 항목만 방출할때 사용  

    ````java
    static <T> CompletableFuture<T> toFuture(Observable<T> observable) {
        CompletableFuture<T> promise = new CompletableFuture<>();
        observable
            .single()
            .subscribe(
                promise::complete,
                promise::completeExcetpionally
            );
        return promise;
    }
    ````

<br>

2. Observable&lt;T&gt; -&gt; CompletableFuture&lt;List&lt;T&gt;&gt;  
    업스트림 Observable의 모든 이벤트를 방출하고 스트림을 완료하면 CompletableFuture 완료  

    ````java
    static <T> CompletableFuture<List<T>> toFutureList(Observable<T> observable) {
        return toFuture(observable.toList());
    }
    ````

<br>
