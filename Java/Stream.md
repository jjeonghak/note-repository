## 스트림
다량의 데이터 처리 작업을 돕고자 자바 8에 추가된 API  
대표적으로 컬렉션, 배열, 파일, 정규표현식 패턴 매처, 난수 생성기, 혹은 다른 스트림  
스트림 내부의 데이터 원소들은 객체 참조나 기본 타입 값  
메서드 연쇄를 지원하는 플루언트 API(fluent API)  
파이프라인 하나를 구성하는 모든 호출을 연결하는 단 하나의 표현식  

<br>

## 스트림 추상 개념
1. 스트림  
    데이터 원소의 유한 혹은 무한 시퀀스를 뜻함  
    
2. 스트림 파이프라인  
    이 원소들로 수행하는 연산 단계  

<br>

## 스트림 파이프라인
스트림 파이프라인은 지연 평가(lazy evaluation)  
평가는 종단 연산이 호출되는 시점에 실행  
종단 연산에 쓰이지 않는 데이터 원소는 제외  
종단 연산이 없는 스트림 파이프라인은 아무 일도 일어나지 않는 no-op 명령어  
기본적으로 순차 실행, 병렬 실행은 parallel 메서드 호출 필요  

1. 소스 스티림  
    스트림의 시작  
  
2. 중간 연산(intermediate operation)  
    스트림을 어떠한 방식으로 변환(transform)  
    각 원소에 함수를 적용하거나 특정 조건을 만족 못하는 원소를 필터링하는 등  
    변환된 스트림의 원소 타입은 변환 전 스트림의 원소 타입과 다를 수도 있음  
    
3. 종단 연산(terminal operation)  
    스트림의 끝  
    마지막 중간 연산의 결과 스트림에 최후의 연산 실행  
    원소 정렬, 특정 원소 선택, 모든 원소 출력 등  

<br>

## 코드 블록과 비교
스트림 파이프라인은 되풀이되는 계산을 함수 객체(주로 람다)로 표현  

````
코드 블록
1. 범위 안의 지역변수를 읽고 수정 가능
  람다에서는 final 또는 사실상 final인 변수만 읽기 가능
2. return, break, continue문을 통한 반복문 제어 가능
  또한 메서드 선언에 명시된 검사 예외 생성 가능
  
스트림
1. 원소들의 시퀀스를 일관되게 변환
2. 원소들의 시퀀스를 필터링
3. 원소들의 시퀀스를 하나의 연산을 사용해서 결합
4. 원소들의 시퀀스를 컬렉션으로 결합
5. 원소들의 시퀀스에서 특정 조건을 만족하는 원소 탐색 가능
````

<br>

## for-each 비교
외부 반복(external iteration) : for-each 루프를 이용해서 각 요소를 반복하면서 작업 수행  
내부 반복(internal iteration) : stream API와 같이 라이브러리 내부에서 모든 데이터   

<br>

## 스트림 한계
  한 데이터가 파이프라인의 여러 연산의 단계를 통과할 때 이 데이터의 각 상태의 값들에 동시에 접근하는 것 불가능
  스트림 파이프라인은 한 값을 다른 값에 매핑하면 원래의 값은 소실되는 구조


//스트림 패러다임
함수형 프로그래밍에 기초한 패러다임  
스트림 패러다임의 핵심은 계산을 일련의 변환(transformation)으로 재구성  
이때 각 변환 단계는 이전 단계의 결과를 받아 처리하는 순수 함수(입력만이 결과에 영향)  
다른 가변 상태를 참조하지 않고, 함수 스스로도 다른 상태를 변경하지 않아야 함  
연산에 건네는 함수 객체는 모두 부작용(side effect)이 없어야 함  

<br>

### 스트림 패러다임을 이해하지 못한 사용법
````java
Map<String, Long> freq = new HashMap<>();
try (Stream<String> words = new Scanner(file).tokens()) {
    words.forEach(word -> {   //forEach는 그저 스트림이 수행한 연산 결과를 출력하는 일만 권장
        freq.merge(word.toLowerCase(), 1L, Long::sum);
    });
}
````

<br>

### 올바른 사용법
````java
Map<String, Long> freq = new HashMap<>();
try(Stream<String> words = new Scanner(file).tokens()) {
    freq = words
        .collect(groupingBy(String::toLowerCase, counting()));
}
````

<br>

## 스트림 주요 기능
1. 필터링(filtering)  
2. 추출(extracting)  
3. 그룹화(grouping)  
4. 병렬화  
    멀티코어 환경에서 여러 CPU를 이용해서 리스트를 포킹(forking)  
    각각의 CPU는 자신이 맡은 구간의 리스트 데이터 처리  
    마지막으로 하나의 CPU가 여러 CPU의 결과를 정리  

    ````java
    //순차 처리 방식
    List<Apple> heavyApples = 
        inventory.stream().filter(a -> a.getWeight() > 150)
                          .collect(toList());
    //병렬 처리 방식
    List<Apple> heavyApples = 
        inventory.parallelStream().filter(a -> a.getWeight() > 150)
                                  .collect(toList());
    ````

<br>

## Collector
java.util.stream.Collectors  
축소(reduction) 전략을 갭슐화한 블랙박스 객체  

1. 수집기 : toList(), toSet(), toCollection(collectionFactory)  //리스트, 집합, 사용자 지정 컬렉션  

    ````java
    List<String> topTen = freq.keySet().stream()
        .sorted(comparing(freq::get).reversed))
        .limit(10)
        .collect(toList());
    ````

<br>

2. 맵 수집기 : toMap(keyMapper, valueMapper)  
    ````java      
    //키 중복이 없는 경우
    private static final Map<String, Operation> stringToEnum = 
        Stream.of(values()).collect(
            toMap(Object::toString, e -> e));

    //각 키와 해당 키의 특정 원소를 연관 짓는 경우
    Map<Artist, Album> topHits = albums.collect(
        toMap(Album::artist, a -> a, maxBy(comparing(Album::sales))));
    ````

<br>

3. 메서드 : groupingBy()  
    입력으로 분류 함수(classifier)를 받고 출력으로는 원소들을 카테고리별로 모아 놓은 맵 반환  
    분류 함수는 입력 받은 원소가 해당하는 카테고리 반환  
    리스트 외의 값을 반환하게 하려면 다운스트림(downstream)과 함께 사용  

    ````java
    words.collect(groupingBy(word -> alphaetize(word)));
    
    //다운 스트림 사용
    Map<String, Long> freq = words
        .collect(grouopingBy(String::toLowerCase, counting()));
    ````

<br>

4. 메서드 : joining()
      문자열 등의 CharSequence 인스턴스의 스트림에만 적용 가능  
      매개변수가 없을 시 단순 연결하는 수집기 반환  
      인수가 하나인 경우 CharSequence 타입의 구분문자(delimiter)를 받아 연결 부위에 삽입  
      인수가 세개인 경우 구분문자, 접두문자(prefix), 접미문자(suffix)

      ````java
      joining(',', '[', ']')  //[a, b, c]
      ````

<br>

## 스트림 슬라이싱
1. takeWhile : 무한 스트림을 포함한 모든 스트림에 프레디케이트를 적용해 스트림을 슬라이싱
    
    ````java
    List<Dish> slicedMenu = specialMenu.stream()      //이미 정렬된 컬렉션
        .takeWhile(dish -> dish.getCalories() < 320)  //프레디케이트 불만족시 루프 종료 및 스트림 슬라이싱
        .collect(toList());
    ````

<br>

2. dropWhile : takeWhile과 반대의 작업, 처음으로 거짓이 되는 지점까지 요소를 버림
    ````java
    List<Dish> slicedMenu = specialMenu.stream()
        .dropWhile(dish -> dish.getCalories() < 320)
        .collect(toList());
    ````

<br>

## 스트림 축소
limit : 주어진 값 이하의 크기를 갖는 새로운 스트림 반환  
filter와 함께 사용해서 프레디케이트와 일치하는 첫 요소들을 선택한 즉시 결과 반환  

<br>

## 스트림 요소 건너뛰기
skip : 처음 n개 요소를 제외한 스트림 반환  

<br>

## 스트림 매핑
map : 특정 객체에서 특정 데이터를 선택하는 작업  

<br>

## 스트림 평탄화(flattening)
중간 연산으로 flatMap 사용  
스트림의 각 원소를 하나의 스트림으로 매핑한 후 다음 그 스트림들을 다시 하나의 스트림으로 연결  

<br>

### 평탄화를 사용한 데카르트 곱 계산
````java
private static List<Card> newDeck() {
    return Stream.of(Suit.values())
        .flatMap(suit -> Stream.of(Rank.values())
            .map(rank -> new Card(suit, rank)))
        .collect(toList());
}
````

<br>

### 잘못 사용된 평탄화
````java
words.stream()
    .map(word -> word.split(""))  //Stream(String) 형태가 아닌 Stream(String[])
    .distinct()
    .collect(toList());
````

<br>

### 잘 사용된 평탄화
````java
words.stream()
    .map(word -> word.split(""))
    .flatMap(Arrays::stream)  //생성된 스트림을 하나의 스트림으로 평탄화
    .distinct()
    .collect(toList());
````

<br>

## 스트림 검색과 매칭
1. allMatch : 주어진 스트림에서 프레디케이트가 모든 요소에 일치하는지 확인  
2. anyMatch : 주어진 스트림에서 프레디케이트에 적어도 한 요소가 일치하는지 확인  
3. noneMatch : 주어진 스트림에서 프레디케이트가 모든 요소에 일치하지 않는지 확인  
4. findFirst : 논리적인 요소의 순서가 정해져 있는 스트림에서 첫번째 요소 반환  
5. findAny : 현재 스트림에서 임의의 요소를 반환, 쇼트서킷을 이용해 결과를 찾는 즉시 반환(Optional)  
> 병렬 실행에서 첫번째 요소를 찾기 어려움 -> findAny

<br>

## 리듀싱(reducing)
스트림 요소를 조합해서 더 복잡한 질의를 표현하는 방법  
함수형 프로그래밍 언어 용어로는 폴드(fold)라고 칭함  
스트림이 하나의 값으로 줄어들 때까지 각 요소를 반복해서 조합   

````java
int sum = numbers.stream().reduce(0, (a, b) -> a + b);
int sum = numbers.stream().reduce(0, Integer::sum);
Optional<Integer> sum = numbers.stream().reduce(Integer::sum);  //초기값이 없는 경우 Optional
Optional<Integer> max = numbers.stream().reduce(Integer::max);
````

<br>

## 맵 리듀스 패턴(map-reduce pattern)
map과 reduce를 연결하는 기법으로 쉬운 병렬화 가능  
구글의 웹 검색에 적용하면서 유명  
가변 누적자 패턴(mutable accumulator pattern)은 병렬화와 어울리지 않기 때문  

````java
int count = menu.stream()
    .map(d -> 1)
    .reduce(0, (a, b) -> a + b);  //병렬화하여 입력을 분할라고 결과를 합침
````

<br>

## 기본형 특화 스트림(primitive stream specialization)
기본 숫자 자료형에 대한 특화 스트림  
숫자 관련 리듀싱 연산 수행 메서드(sum, min, max, average) 제공  
다시 박싱 객체 스트림으로 복원하는 기능(boxed 메서드) 제공  

1. IntStream, OptionalInt : mapToInt 메서드로 생성, range, rangeClosed  
2. DoubleStream, OptionalDouble : mapToDouble 메서드로 생성  
3. LongStream, OptionalLong : mapToLong 메서드로 생성, range, rangeClosed  

<br>

## 함수 스트림
함수에서 스트림을 만들 수 있는 정적 메서드 iterate, generate 제공  
두 연산을 이용해서 무한 스트림(infinite stream), 언바운드 스트림(unbounded stream) 생성 가능  
요청할 때마다 주어진 함수를 이용해서 값을 생성  
보통의 경우 limit 메서드와 함께 연결해서 사용  
  
1. iterate : 이전 원소를 인자로 받아 연속적으로 계산  
    ````java
    Stream.iterate(0, n -> n + 2)
    Stream.iterate(0, n -> n < 100, n -> n + 4) //filter 메서드를 사용하는 경우 무한 루프 발생, 대신 takeWhile 메서드
    ````

<br>

2. generate : 생산된 각 원소를 연속적으로 계산하지 않고 Supplier<T> 발행자를 인수로 받아 새로운 값 생성
    ````java
    Stream.generate(Math::random)
    ````

<br>
