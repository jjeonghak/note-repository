## 옵셔널
자바 8은 하스켈과 스칼라의 영향을 받아 java.util.Optional&lt;T&gt; 제공  
선택형 값을 캡슐화하는 클래스  
값이 존재하는 경우 Optional 클래스로 감쌈  
값이 존재하지 않는 경우 Optional.empty 메서드를 통해 Optional 반환  
Optional.empty 메서드는 Optional의 싱글톤 인스턴스를 반환하는 정적 팩토리 메서드  
Optional 클래스 설계자는 선택형 반환값을 지원하는 것으로 명확하게 정의  
도메인의 필드 형식으로 사용할 경우 직렬화 도구나 프레임워크에서 문제 발생  
직렬화 모델이 필요한 경우 Optional 값을 반환하는 메서드를 추가하는 방식 사용 권장  

<br>

## 옵셔널 패턴
1. Optional 객체 생성
    ````java
    Optional<Car> optCar = Optional.empty();  //빈 옵셔널 객체 생성
    Optional<Car> optCar = Optional.of(car);  //null 아닌 값으로 옵셔널 객체 생성
    Optional<Car> optCar = Optional.ofNullable(car) //어떤 값이든 옵셔널 객체 생성
    ````

2. Optional 값 추출 및 반환
    ````java
    Optional<Insurance> optInsurance = Optional.ofNullable(insurance);
    Optional<String> name = optInsurance.map(Insurance::getName);
    ````

3. Optional 객체 연결
    ````java
    Optional<String> name = person.flatMap(Person::getCar)
        .flatMap(Car::getInsurance) //map을 이용한 객체 연결의 경우 Optional이 중첩으로 래핑
        .flatMap(Insurance::getName); 
    ````

<br>

## 옵셔널 스트림
Optional.stream() 메서드를 통해 값을 가진 스트림으로 변환 가능  

````java
List<Person> person = ...
Set<String> result = persons.stream()
    .map(Person::getCar)
    .map(optCar -> optCar.flatMap(Car::getInsurance))
    .map(optIns -> optIns.flatMap(Insurance::getName))
    .flatMap(Optional::stream)  //Stream<Optional<String>> -> Stream<String>
    .collect(toSet());
    //flatMap(Optional::stream)과 같은 결과
    .filter(Optional::isPresent)
    .map(Optional::get)
````

<br>

## 디폴트 액션
1. get()  
    값을 읽는 가장 간단한 메서드  
    안전하지 않음, 값이 존재하지 않는 경우 NoSuchElementException 오류 발생  

2. orElse(T other)  
    값이 존재하지 않는 경우 기본값 제공  
  
3. orElseGet(Supplier&lt;? extends T&gt; other)  
    orElse 메서드의 게으른 버전 메서드  
    값이 존재하지 않는 경우 Supplier 실행해서 기본값 생성  

4. orElseThrow(Supplier&lt;? extends X&gt; exceptionSupplier)  
    get 메서드와 유사하지만 발생시킬 예외의 종류 선택 가능  
  
5. ifPresent(Comsumer&lt;? super T&gt; consumer)  
    값이 존재하는 경우 인수로 넘겨서 동작 실행 가능  
    값이 존재하지 않는 경우 아무 일도 발생하지 않음  

6. ifPresentOrElse(Consumer&lt;? super T&gt; action, Runnable emptyAction)  
    ifPresent 메서드와 유사하지만 값이 존재하지 않는 경우 Runnable 실행  

<br>

## 기본형 옵셔널
스트림과 유사하게 OptionalInt, OptionalLong, Optionaldouble 지원  
Optional의 최대 요소는 한개이므로 성능 개선 효과없음  
map, flapMap, filter 메서드 등 지원안함  
Optional로 생성한 다른 객체와 혼용불가  
사용하지 않는 것을 권장  
  
<br>
