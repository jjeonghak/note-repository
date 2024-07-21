## Single
RxJava의 Observable은 스트림이고 잠재적으로 무한 가능  
하나의 요소를 지닌 List&lt;T&gt;와 유사하게 Observable&lt;T&gt;도 하나의 요소만 가질 수 있음  
CompletableFuture와 가장 유사한 Observable  
정확히 하나의 요소를 방출하는 특별한 추상화 rx.Single&lt;T&gt;  
기본적으로 T 또는 Exception 값을 담는 자료형  

````java
//API 혼동 발생
Observable<Float> temperature() {
    ...  //하나의 값인지 무한한 값인지 알 수 없음
}

//예상 반환값이 분명
Single<Float> temperature() {
    ...
}
````

<br>
  
## 생성 방법
Observable 지원 연산자와 상당히 유사  
filter 연산자는 지원하지 않음, 아무것도 없는 Single 객체 생성 가능성 존재  

1. just(), error()  
      subscribe() 메서드는 3개가 아닌 2개의 인수를 받음  
      하나의 값 또는 예외로 완료되므로 onComplete() 메서드 콜백은 필요없음  

      ````java
      Single<String> single = Single.just("single element");
      single.subscribe(System.out::println);

      Single<Instant> error = Single.error(new RuntimeException("error element"));
      error
          .observeOn(Schedulers.io())
          .subscribe(
              System.out::println,
              Throwable::printStackTrace
          );
      ````

<br>

2. create(), fromCallable()  
      onSuccess() 또는 onError() 메서드를 필수로 한번 호출  
      다중 onSuccess() 메서드 호출 금지  
      Callable&lt;T&gt;를 인수로 받아 Single&lr;T&gt;를 반환하는 fromCallable() 메서드와 유사  

      ````java
      Single<String> example = fetch("https://www.example.com")
          flatMap(this::body);
      String b = example.toBlocking().value();

      Single<String> body(Response) {
          return Single.create(subscriber -> {
              try {
                  subscriber.onSuccess(response.getResponseBody());
              } catch (IOException e) {
                  subscriber.onError(e);
              }
          });
      }

      Single<String> body2(Response response) {
          return Single.fromCallabe(() -> response.getResponseBody());
      }
      ````

<br>

3. zip(), zipWith()  
    결과는 항상 정확히 하나의 페어/튜플  

    ````java
    Single<String> content(int id) {
        return Single.fromCallable(() -> jdbcTmeplate
            .queryForObject(
                "SELECT content FROM articles WHERE id = ?",
                String.class, id))
            .subscribeOn(Schedulers.io());
    }

    Single<Integer> likes(int id) {
        //소셜 미디어 웹 사이트를 향한 비동기 HTTP 요청
    }

    Single<Void> updateReadCount() {
        //그저 부수 효과일 뿐이며 Single 반환값은 없다
    }

    Single<Document> doc = Single.zip(
        content(123),
        likes(123),
        updateReadCount(),
        (con, lks, vod) -> buildHtml(con, lks)
    );
    ````

<br>

## 네티 서버
네티 기반 async-http-client은 Single 생성되는 방식과 매우 잘 맞음  

````java
AsyncHttpClient asyncHttpClient = new AsyncHttpClient();

Single<Response> fetch(String address) {
    return Single.create(subscciber -> asyncHttpClient
        .prepareGet(address)
        .execute(handler(subscriber)));
}

AsyncCompletionHandler handler(SingleSubscriber<? super Response> subscriber) {
    return new AsyncCompletionHandler() {
        public Response onCompleted(Response response) {
            subscriber.onSuccess(response);
            return response;
        }

        public void onThrowable(Throwable t) {
            subscriber.onError(t);
        }
    };
}
````

<br>

## Observable 상호변환
1. 값 하나를 방출하고 완료 알림을 보내는 Observable  
    toSingle() 메서드는 주의 필요  

    ````java
    Single<Integer> emptySingle = Observable.<Integer>empty().toSingle();
    Single<Integer> doubleSingle = Observable.just(1, 2).toSingle();

    //잘못된 사용, 중간에 이벤트 탈취
    Single<Integer> ignored = Single
        .just(1)
        .toObservable()
        .ignoreElements()  //문제 원인
        .toSingle();
    ````

<br>

2. Observable에서 사용 가능한 연산자가 Single에 없는 경우(cache() 등)  
    toObservable() 메서드는 안전  

    ````java
    Single<String> single = Single.create(subscriber -> {
        System.out.println("subscribing");
        subscriber.onSuccess("42");
    });
    
    Single<String> cachedSingle = single
        .toObservable()
        .cache()
        .toSingle();
    
    cachedSingle.subscribe(System.out.println);
    cachedSingle.subscribe(System.out.println);
    ````
    
<br>

## 선택기준
Single 사용 이유  

1. 연산을 특정 값 또는 예외로 완료해야 하는 경우  
2. 문제 영역에 스트림 형식이 없다면 Observable 사용은 오해의 소지 존재  
3. 특정 상황에 Observable은 너무 무겁고 Single 성능이 좋은 경우  

Observable 사용 이유  
  
1. 정의에 따라 여러 번 발생하거나 무한한 일종의 이벤트인 경우  
2. 값이 발생하는지 여부를 모르는 경우  

<br>


