## 연산자
업스트림의 Observable&lt;T&gt;를 취해 다운스트림으로 Observable<R>을 내보내는 함수  
연산자를 결합하고 여러 하위 스트림으로 분기 후 다시 병합 가능  
기본적으로 원본 Observable을 포장하지만 스스로 구독하지 않음  

<br>

## 매핑과 필터링
filter() : 이벤트를 계속 전달할지 버릴지 정함  
````java
//원본 업스트림에 영향을 주지 않고 새로운 Observable 객체 반환
Observable<String> strings = someFileSource.lines();
Observable<String> comments = strings.filter(s -> s.startsWith("#"));
Observable<String> instructions = strings.filter(s -> s.startWith(">"));
Observable<String> empty = strings.filter(String::isBlank);
````

<br>

map() : 이벤트를 확장하거나 포장 또는 다른 값으로 추출  
````java
Observable<Status> tweets = ...
Observable<Date> dates = tweets
    .map(Status::getCreateAt)
    .map(d -> d.toInstant());
````

flatMap() : 개별 변환한 요소를 다른 중첩된 혹은 내부의 Observable로 반환  
````java
Observable<LicensePlate> recognize(CarPhoto photo) {
    ...
}
Observable<CarPhoto> cars = cars();
Observable<Observable<LicensePlate>> plates = cars.map(this::recognize);
Observable<LicensePlate> plates2 = cars.flatMap(this::recognize);

Observable<Order> orders = customers
    .map(Customer::getOrders)
    .flatMap(Observable::from);
Observable<Order> orders = customers
    .flatMapIterable(Customer::getOrders);
````

<br>

### 이벤트, 오류, 완료 등 어떠한 알림에도 반응하는 오버로딩 버전
````java
<R> Observable<R> flatMap(
    Func1<T, Observable<R>> onNext,
    Func1<Throwable, Observable<R>> onError,
    Func0<Observable<R>> onCompleted
)

Observable.just(DayOfWeek.SUNDAY, DayOfWeek.MONDAY)
    .flatMap(this::loadRecordsFor);
Observable<String> loadRecordsFor(DayOfWeek dow) {
    switch(dow) {
        case SUNDAY:
            return Observable.interval(90, MILLISECONDS)
                .take(5)
                .map(i -> "Sun-" + i);
        case MONDAY:
            return Observable.interval(65, MILLISECONDS)
                .take(5)
                .map(i -> "MON-" + i);
        ...
    }
}
````

````
//반환하는 부속 순열을 합쳐서 동등하게 취급, 이들 모두를 즉시 구독하고 다운스트림 방출
Mon-0, Sun-0, Mon-1, Sun-1, Mon-2, Mon-3, Sun-2, Mon-4, Sun-3, Sun-4
````

<br>

## 순서 유지
다운스트림 이벤트의 순서를 업스트림 이벤트와 유지하기 위해 concatMap() 메서드 사용  
n번째 업스트림 이벤트의 다운스트림과 n + 1번째 업스트림 이벤트의 다운스트림의 순서 보장  
flatMap() 메서드는 내부적으로 merge() 메서드를 사용해서 이벤트들이 서로 꼬임  
concatMap() 메서드는 내부적으로 concat() 메서드 사용  

````java
Observable.just(DayOfWeek.SUNDAY, DayOfWeek.MONDAY)
    .concatMap(this::loadRecordsFor);
````
````
//flapMap 메서드와 다르게 업스트림 이벤트의 다운스트림 순서 보장
Sun-0, Sun-1, Sun-2, Sun-3, Sun-4, Mon-0, Mon-1, Mon-2, Mon-3, Mon-4
````

<br>

## 동시성 제어
flatMap() 메서드는 개별 업스트림 값을 동시에 계산하기 위해 고안한 연산자  

````java
//지속적으로 새로운 연결을 하는 방식, maxConcurrent 인자 필수
class User {
    Observable<Profile> loadProfile() {
        //Http 요청 등 수행
    }
}
List<User> users = ...
Observable<Profile> profiles = Observable.from(users)
    .flatMap(User::loadProfile, 10);  //내부 진행중인 Observable 갯수 10개 제한
````

<br>

## 짝 합성
zip()과 zipWith() 메서드를 통해 서로 대응하는 개별 이벤트끼리 짝을 맞춤  
두 스트림의 방출값을 함께 묶어서 사용, 하나의 스트림이 종료되면 나머지 스트림 조기 폐기  
짝 지어진 모든 업스트림에서 이벤트를 방출해야 다운스트림 이벤트 방출 가능(명백한 블록킹은 아님)  
반환형으로는 튜플과 페어가 적합하지만 내장 자료구조가 없으므로 직접 구현 또는 외부 라이브러리 사용 권장  

````java
s1.zipWith(s2, ...)  //하나의 스트림에 메서드 체인으로 다른 스트림 짝 연결
Observable.zip(s1, s2, s3, ...)  //2개 이상 9개 이하까지 스트림 짝 연결

class Weather {
    public Weather(Temperature temperature, Wind wind) {
        ...
    }
}
Observable<Temperature> temperatureMeasurements = station.temperature();
Observable<Wind> windMeasurements = station.wind();
temperatureMeasurements.zipWith(windMeasurements,
    (temperature, wind) -> new Weather(temperature, wind));

Observable<LocalDate> nextTenDay = Observable.range(1, 10)
    .map(i -> LocalDate.now().plusDays(i));
Observable<Vacation> possibleVacations = Observable.just(City.Warsw, City.London, City.Paris)
    .flatMap(city -> nextTneDays.map(date -> new Vacation(city, date)))
    .flatMap(vacation -> Observable.zip(
        vacation.weather().filter(Weather::isSunny),
        vacation.cheapFlightFrom(City.NewYork),
        vacation.cheapHotel(),
        (w, f, h) -> vacation
    ));
````

<br>

## 조화롭지 않은 짝 합성
zip()과 zipWith() 메서드는 항상 같은 주기로 비슷한 순간에 이벤트를 생성한다는 가정  
방출 속도가 다른 업스트림의 이벤트를 합치는 경우 combineLatest(), withLatestFrom(), amb() 메서드 사용  
combineLatest() 메서드는 대칭적으로 스트림의 새 값이 나올때마다 다른 스트림의 최근값과 짝으로 묶어서 방출  
withLatestFrom() 메서드는 특정 스트림의 새 값에만 방출  

<br>

### conbineLatest() 메서드 활용
````java
Observable<Long> red = Observable.interval(10, TimeUnit.MILLISECONDS);
Observable<Long> green = Observable.interval(17, TimeUnit.MILLISECONDS);
Observable.combineLatest(
    red.map(x -> "R" + x),
    green.map(x -> "G" + x),
    (r, g) -> r + ":" + g
).forEach(System.out::println);
````
````
R0:G0
R1:G0
R2:G0
R2:G1
R3:G1
R4:G1
R4:G2
R5:G2
R5:G3
...
R999:G587
R1000:G587
R1000:G588
R1001:G588
````

<br>

### withLatestFrom() 메서드 활용
````java
green.withLatestFrom(red, (g, r) -> g + ":" + r)
    .forEach(System.out::println);
````
````
G0:R1
G1:R2
G2:R4
G3:R5
G4:R7
G5:R9
G6:R11
...
````

<br>

## 고수준 연산자
1. 연산  
    scan() : 중간 계산 결과를 지속적으로 방출  
    reduce() : 최종 결과만 방출  
   
    ````java
    Observable<Long> totalProgress = progress
        .scan((total, chunk) -> total + chunk);
    Observable<BigInteger> factorials = Observable
        .range(2, 100)
        .scan(BigInteger.ONE, (big, cur) -> big.multiply(BigInteger.valueOf(cur)));  //초기값 제공

    Observable<BigDecimal> total = transfers
        .map(CashTransfer::getAmount)
        .reduce(BigDecimal.ZERO, BigDecimal::add);

    public <R> Observable<R> reduce(R initialValue, Func2<R, T, R> accumulator) {
        return scan(initialValue, accumulator).takeLast(1);
    }
    ````

<br>

2. 환산   
    collect() : 불변이 아닌 가변 누산기를 이용해 컬렉션 생성  

    ````java
    //불변 누산기
    Observable<List<Integer>> all = Observable
        .range(10, 20)
        .reduce(new ArrayList<>(), (list, item) -> {
            list.add(item);
            return list;
    });

    Observable<List<Integer>> all = Observable
        .range(10, 20)
        .collect(ArrayList::new, List::add);
    Observable<String> str = Observable
        .range(1, 10)
        .collect(StringBuilder::new, (sb, x) -> sb.append(x).append("\n"))
        .map(StringBuilder::toString);
    ````

<br>

3. 하나의 항목 보장  
    single() : 하나의 이벤트만 방출, 가정이 틀린 경우 예외 발생  

4. 중복 제거  
    distinct() : 내부적으로 해당값이 존재하는지 검토(equals(), hashCode() 사용)  
    distinctUntilChanged() : 주어진 이벤트가 직전 이벤트와 같은 경우 버림(equals() 사용)  

    ````java
    Observable<Integer> randomInts = Observable.create(subscriber -> {
        Random random = new Random();
        while (!subscriber.isUnsubscribed()) {
            subscriber.onNext(random.nextInt(1000));
        }
    });
    Observable<Integer> uniqueRandomInts = randomInts
        .distinct()
        .take(10);

    Observalbe<Weather> tempChanges = measurements
        .distinctUnitChanged(Weather::getTemperature);
    ````

<br>

5. 분해  
    take(n) : 처음 n개의 값만 업스트림에서 방출  
    takeLast(n) : 스트림 완료 이전 n개의 값만 방출  
    skip(n) : 처음 n개의 값을 버림  
    skipLast(n) : 마지막 n개의 값을 버림  
    first() : take(1).single()  
    last() : takeLast(1).single()  
    takeFirst(predicate) : filter(predicate).take(1), 일치하는 값 없는 경우 NoSuchElemntEception 발생  
    takeUntil(predicate) : 값을 방출하다가 predicate와 일치하는 첫 번째 항목을 방출한 다음 완료  
    takeWhile(predicate) : predicate를 만족하는 한 계속 방출  
    elementAt(n) : 특정 위치의 항복을 뽑아내는 경우 사용  
    ...OrDefault() : 연산 중에 예외 발생시 기본값으로 치환  
    count() : 업스트림에서 방출한 이벤트 갯수를 계산  
    all(predicate) : 모든 이벤트가 predicate와 일치하면 true 반환  
    exists(predicate) : 이벤트 중 하나라도 predicate와 일치하면 true 반환  
    contains(value) : exists 파라미터로 predicate 대신 값 또는 상수 사용하는 경우  

6. 결합  
    concat() : 정적 메서드로 두개의 업스트림을 연결, 첫번째 Observable 종료시 두번째 방출 시작  
    concatWith() : 인스턴스 메서드로 두개의 업스트림을 연결  
    switchOnNext() : Observable<Observale<T>> 형태의 여러 구독들 중 나오는 순서대로 구독 변환  

    ````java
    Observable<String> speak(String quote, long millisPerChar) {
        String[] tokens = quote.replaceAll("[:,]", "").split(" ");
        Observalbe<String> words = Observable.from(tokens);
        Observable<Long> absoluteDelay = words
            .map(String::length)
            .map(len -> len * millisPerChar)
            .scan((total, current) -> total + current);
        return words
            .zipWith(absoluteDelay.startWith(0L), Pair::of)
            .flatMap(pair -> just(pair.getLeft()))
                .delay(pair.getRight(), MILLISECONDS));
    }
    Observable<String> alice = speak("To bew, or not to be: that is the question", 110);
    Observable<String> bob = speak("Though this be madness, yet there is method in't", 90);
    Observalbe<String> jane = speak("There are more things in Heaven and Earth," +
        "Horatio, than are dreamt of in your philosophy", 100);
    
    //동시 호출 - merge
    Observale.merge(
        alice.map(w -> "Alice: " + w),
        bob.map(w -> "Bob: " + w),
        jane.map(w -> "Jane: " + w)
    ).subscribe(System.out::println);
    ````
    ````
    Alice: To
    Bob: Though
    Jane: There
    Alice: be
    Alice: or
    Jane: are
    ...

    //동시 호출 - concat
    Alice: To
    Alice: be
    ...
    Bob: Though
    Bob: this
    ...
    Jane: There
    Jane: are
    ...

    //동시 호출 - switchOnNext
    Alice: To
    Alice: be
    Bob: Though
    Bob: this
    Jane: There
    Jane: are
    Jane: more
    Jane: things
    Jane: in
    Jane : Heaven
    ...
    ````

7. 그룹  
    groupBy(): 스트림을 특정 키 기반으로 여러 개의 병렬 스트림으로 나눔  

    ````java
    Observable<ReservationEvent> facts = factStore.observe();
    Observable<GroupedObservable<UUID, ReservationEvent>> grouped = fact
        .groupBy(ReservationEvent::getReservationUuid);
    grouped.subscribe(byUuid -> {
        byUuid.subscribe(this::updateProjection);
    });
    ````

<br>

## 연산자 재사용
compose(): 연산자를 연결하여 업스트림 Observalbe을 변환하는 함수를 인자로 받음  

````java
public <T> Observable.Transformer<T, T> odd() {
    Observable<Boolean> trueFalse = just(true, false).repeat();
    return upstream -> upstream
        .zipWith(trueFalse, Pair::of)
        .filter(Pair::getRight)
        .map(Pair::getLeft);
}

Observable
    .range(0, 'Z' - 'A' + 1)
    .map(c -> (char) ('A' + c))
    .compose(odd())
    .forEach(System.out::println);
````

<br>

## 연산자 생성
lift() : 어떠한 연산이라도 구현 가능(flatMap 제외), 업스트림 이벤트의 흐름 변경 가능  

````java
Observable
    .range(1, 1000)
    .filter(x -> x % 3 == 0)
    .distinct()
    .reduce((a, x) -> a + x)
    .map(Integer::toHexString)
    .subscribe(System.out::println);

Observable
    .range(1, 1000)
    .lift(new OperatorFilter<>(x -> x % 3 == 0))
    .lift(    OperatorDistinct.<Integer>instance())
    .lift(new OperatorScan<>((Integer a, Integer x) -> a + x))
    .lift(    OperatorTakeLastOne.<Integer>instance())
    .lift(    OperatorSingle.<Integer>instance())
    .lift(new OperatorMap<>(Integer::toHexString))
    .subscribe(System.out::println);
````

<br>

## map() 내부 구현
OperatorMap 클래스는 다운스트림 Subscriber<R>을 업스트림 Subscriber&ly;T&gt;로 변환  
T와 R의 제네릭 순서가 변환  
다운스트림을 구독한 Subscriber&lt;R&gt;을 업스트림 Subscriber&lt;T&gt;로 변환하는 과정  
구독이 시작되면 call() 메서드 호출  
후자의 Subscriber가 앞선 연산자를 향해 업스트림으로 올라감  

````java
public final class OperatorMap<T, R> implements Operator<R, T> {
    private final Func1<T, R> transformer;

    public OperatorMap(Func1<T, R> transformer) {
        this.transformer = transformer;
    }

    @Override
    public Subscriber<T> call(final Subscriber<R> child) {
        return new Subscriber<T>(child) {
            @Override
            public void onCompleted() {
                child.onCompleted();
            }

            @Override
            public void onError(Throwable e) {
                child.onError(e);
            }

            @Override
            public void onNext(T t) {
                try {
                    child.onNext(transformer.call(t));
                } catch (Exception e) {
                    onError(e);
                }
            }
        };
    }
}

Observable<String> odd = Observable
    .range(1, 9)
    .buffer(1, 2)
    .concatMapIterable(x -> x)
    .map(Object::toString)

Observable<String> odd = Observable
    .range(1, 9)
    .lift(toStringOfOdd());
````

<br>

### 연산자 구현
````java
public <T> Observable.Operator<String, T> toStringOdd() {
    return new Observable.Operator<String, T>() {
        private boolean odd = true;

        @Override
        public Subsciber<? super T> call(Subscriber<? super String> child) {
            return new Subscriber<T>(child) {
                @Override
                public void onCompleted() {
                    child.onCompleted();
                }

                @Override
                public void onError(Throwable e) {
                    child.onError(e);
                }

                @Override
                public void onNext(T t) {
                    if (odd) {
                        child.onNext(t.toString());
                    } else {
                        request(1);
                    }
                    odd = !odd;
                }
            };
        }
    };
}
````

<br>
