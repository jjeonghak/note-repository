## rx.subjects.Subject
Observable 클래스와 Observer 클래스를 동시에 상속  
클라이언트 측에선 업스트림으로 서버 측에선 다운스트림으로 핸들링 가능  
내부적으로 이벤트를 추적하므로 더 이상 직접 통제할 필요 없음  
내부적으로 Subscriber 생명 주기 관리  
설계 지침에 따라 모든 onNext() 메서드는 직렬화하기 위해 toSerialized() 메서드 지원  

````java
class TwitterSubject {
    private final PublishSubject<Status> subject = PublishSubject.create();

    public TwitterSubject() {
        TwitterStream twitterStream = new TwitterStreamFactory().getInstance();
        twitterStream.addListener(new StatusListener() {
            @Override
            public void onStatus(Status status) {
                subject.onNext(status);
            }

            @Override
            public void onException(Exception e) {
                subject.onError(e);
            }
        });
        twitterStream.sample();
    }

    public Observable<Status> observe() {
        return subject;
    }
}
````

<br>

## 유형
1. AsyncSubject  
    마지막 방출값을 기억  
    onComplete() 메서드 호출시 그 값을 구족자에게 전달  
    AsyncSubject 완료되지 않은 경우 마지막 이벤트를 제외한 나머지는 무시  

2. BehaviorSubject  
    구독을 시작하면 구독 이후 방출된 모든 이벤트를 밀어냄  
    구족 직전에 발생했던 이벤트 중 가장 최근 이벤트를 처음 이벤트로 방출  
    어떤 이벤트도 아직 방출되지 않았더라도 제공될 경우 특별한 기본 이벤트 방출  

3. ReplaySubject
    밀어낸 모든 이벤트의 이력을 캐싱  
    구독 전의 이벤트들을 일괄로 받은 후 실시간으로 생성된 이벤트 전달  
    무한 스트림의 경우 제약사항으로 오버로딩된 버전 존재

    ````
    credateWithSize() : 메모리상의 이벤트 숫자 설정
    createWithTime() : 가장 최근 이벤트에 대한 시간대 설정
    createWithTimeAndSize() : 두 가지 설정 중 먼저 걸린 제한 설정 적용
    ````

 <br>
