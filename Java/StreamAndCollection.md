## 원소 시퀀스 반환
자바 7 이전에는 이런 메서드의 반환 타입을 Collection, Set, List, Iterable, 배열 사용  
자바 8 이후에는 스트림을 사용  
Stream 인터페이스는 Iterable 인터페이스가 정의한 추상 메서드를 점부 포함  
하지만 Stream이 Iterable을 확장하지는 않음  
Collection 엔터페이스는 Iterable의 하위 타입이고 stream 메서드도 제공  
원소 시퀀스 반환 공개 API는 Collection 또는 그 하위 타입을 쓰는 게 일반적  

<br>

### 자바 타입 추론의 한계
````java
for (ProcessHandle ph : ProcessHandle.allProcesses()::iterator) {
    ...
}
````

<br>
    
### 스트림을 반복하기 위한 끔찍한 우회방식
````java
for (ProcessHandle ph : (Iterable<ProcessHandle>) ProcessHandle.allProcesses()::iterator) {
    ...
}
````

<br>

### 어댑터 사용 방식
````java
public static <E> Iterable<E> iterableOf(Stream<E> stream) {
    return stream::iterator;
}

public static <E> Stream<E> streamOf(Iterable<E> iterable) {
    return StreamSupport.stream(iterable.spliterator(), false);
}
````

<br>

## 스트림 및 컬렉션 차이
스트림의 게으른 특성 덕분에 컬렉션보다 최적화 가능  
중간 연산은 종단 연산에서 한번에 실행  
  
1. 쇼트서킷(short circuit) : limit 연산을 통해 모든 원소를 처리하지 않음  
2. 루프 퓨전(loop fusion) : filter 및 map은 서로 다른 연산이지만 한과정으로 병합해서 처리  

    ````java  
    List<String> names = menu.stream()
        .filter(dish -> {
            System.out.println("filtering:" + dish.getName());
            return disg.getCalories() > 300;
        })
        .map(dish -> {
            System.out.println("mapping:" + dish.getName());
            return disg.getName();
        })
        .limit(3)
        .collect(toList());
    ````

    ````
    filtering:pork
    mapping:pork
    filtering:beef
    mapping:beef
    filtering:chicken
    mapping:chicken
    ````

<br>

## 컬렉터
Collector 인터페이스 구현은 스트림의 요소를 어떤 식으로 도출할지 지정  
  
1. 스트림 요소를 하나의 값으로 리듀스하고 요약  
2. 요소 그룹화  
3. 요소 분할  

<br>

## 리듀싱 요약
컬렉터를 이용한 카운트, counting 컬렉터는 다른 컨렉터와 함께 사용할 때 유용  
````java
long howManyDishes = menu.stream().collect(Collectors.countimg());
long howManyDishes = menu.stream().count();
````

<br>

최댓값과 최솟값 검색  
````java
Comparator<Dish> dishCaloriesComparactor = Comparator.comparingInt(Dish::getCalories);
Optional<Dish> mostCalorieDish = menu.stream()
    .collect(maxBy(dishCaloriesComparactor));
````

<br>

컬렉터 내에 여러 숫자 관련 요약 팩토리 메서드 지원  
````
summingInt, averagingInt, summarizingInt(IntSummaryStatistics 클래스 반환, count, sum, min, max, average)
````

<br>

문자열 연결, 내부적으로 Stringbuiler 사용  
````java
String shortMenu = menu.stream().map(Dish::getName).collect(joining());
String shortMenu = menu.stream().map(Dish::getName).collect(joining(", "));
````

<br>

## 범용 리듀싱 요약 연산
위의 모든 컬렉터는 reducing 팩토리 메서드로 정의 가능  
범용 Collectors.resucing으로 구현  
프로그래밍적 편의성을 위해 특화된 컬렉터를 사용  
세개의 인수를 받아 동작(초기값, 변환함수, BinaryOperator)  

````java
int totalCalories = menu.stream()
    .collect(reducing(0, Dish::getCalories, (i, j) -> i + j));

Optional<Dish> mostCalorieDish = menu.stream()
    .collect(reducing((d1, d2) -> d1.getCalories() > d2.getCalories() ? d1 : d2));
````

<br>

## collect 및 reduce 비교
collect 메서드는 도출하려는 결과를 누적하는 컨테이너를 변경하도록 설계  
reduce는 두 값을 하나로 도출하는 불변형 연산  

````java
int totalCalories = menu.stream()
    .collect(reducing(0, Dish::getCalories, Integer::sum));
    
int totalCalories = menu.stream()
    .map(Dish::getCalories).reduce(Integer::sum).get();
    
int totalCalories = menu.stream
    .mapToInt(Dish::getCalories).sum();

public static <T> Collector<T, ?, Long> counting() {
    return reducing(0L, e -> 1L, Long::sum);
}
````

<br>

### 잘못사용한 reduce
````java
stream.reduce(
    new ArrayList<Integer>(), 
    (List<Integer> l1, Integer e) -> {
        l1.add(e);
        return l1;
    },
    (List<Integer> l2, List<Integer> l3) -> {
        l2.addAll(l3);
        return l2;
    }
);
````

<br>

## 그룹화
데이터 집합을 하나 이상의 특성으로 분류해서 그룹화하는 연산  
분류 함수(classification function)를 기준으로 스트림 그룹화  

````java
Map<Dish.Type, List<Dish>> dishesByType = menu.stream()
    .collect(groupingBy(Dish::getType));

Map<CaloricLevel, List<Dish>> dishesByCaloricLevel = menu.stream()
    .collect(groupingBy(dish -> {
        if (dish.getCalories() <= 400) return CaloricLevel.DIET;
        else if (dish.getCalories() <= 700) return CaloricLevel.NORMAL;
        else return CaloricLevel.FAT;
    }));
````

<br>

## 그룹화 요소 조작
필터를 적용해 그룹화의 요소를 필터링할 경우 모든 원소가 필터링된 키는 Map에서 제외  

````java
Map<Dish.Type, List<Dish>> caloricDishesByType = menu.stream()
    .filter(dish -> dish.getCalories() > 500)
    .collect(groupingBy(Dish::getType));
    
//groupingBy 팩토리 메서드 오버로드
Map<Dish.Type, List<Dish>> caloricDishesByType = menu.stream()
    .collect(groupingBy(Dish::getType, filtering(dish -> dish.getCalories() > 500, toList())));
    
//mapping 메서드 사용
Map<Dish.Type, List<String>> dishNamesByType = menu.stream()
    .collect(groupingBy(Dish::getType, mapping(Dish::getName, toList())));

//flatMapping
Map<Dish.Type, Set<String>> dishNamesByType = menu.stream()
    .collect(groupingBy(Dish::getType, 
        flatMapping(dish -> dishTags.get(dish.getName()).stream(), toSet())));
````

<br>

## 다수준 그룹화
Collectors.groupingBy 메서드는 일반적인 분류 함수와 컬렉터를 인수로 받음  
groupingBy 메서드에 스트림의 항목을 분류할 두 번째 기준을 정의하는 내부 groupingBy 전달  
n수준 그룹화의 결과는 n수준 트리 구조로 표현되는 n수준 맵  

````java
Map<Dish.Type, Map<CaloricLevel, List<Dish>>> dishesByTypeCaloricLevel = menu.stream()
    .collect(
        groupingBy(Dish::getType, 
            groupingBy(dish -> {
                if (dish.getCalories() <= 400)
                    return CaloricLevel.DIET;
                else if (dish.getCalories() <= 700)
                    return CaloricLevel.NORMAL;
                else
                    return CaloricLevel.FAT;
            })
        )
    );
````

<br>

## 서브그룹 데이터 수집
분류 함수 한개의 인수를 갖는 groupingBy(f)는 groupingby(f, toList())의 축약형  

````java
Map<Dish.Type, Long> typeCount = menu.stream()
    .collect(groupingBy(Dish::getType, counting()));

Map<Dish.Type, Optional<Dish>> mostCaloricByType = menu.stream()
    .collect(groupingBy(Dish::getType, maxBy(comparingInt(Dish::getCalories))));
````

<br>

## 컬렉터 결과 다른 형식으로 적용
Collectors.collectingAndThen 메서드로 컬렉터가 반환한 결과를 다른 형식으로 변경 가능  
적용할 컬렉터와 변환 함수를 인수로 받아 다른 컬렉터를 반환  
반환되는 컬렉터는 기존 컬렉터의 래퍼 역할을 하며 collect 마지막 과정에서 변환 함수로 자신이 반환하는 값을 매핑  

````java
Map<Dish.Type, Dish> mostCaloricByType = menu.stream()
    .collect(groupingBy(Dish::getType, collectingAndThen(
        maxBy(comparingInt(Dish::getCalories)), Optional::get)
    ));
````

<br>

## 분할
분할 함수(partitioning function) 프레디케이트를 분류 함수로 사용하는 특수한 그룹화 기능  
분할 함수는 boolean 값을 반환하므로 맵의 키 형식은 Boolean, 두개의 그룹으로 분류  
필터링과 다르게 참, 거짓 두가지 요소의 스트림 리스트를 모두 유지  

````java
Map<Boolean, List<Dish>> partitionedMenu = menu.stream()
    collect(partitioningBy(Dish::isVegetarian));

//그룹화까지 오버로드 가능
Map<Boolean, Map<Dish.Type, List<Dish>>> vegetarianDishesByType = menu.stream()
    .collect(partitioningBy(Dish::isVegetarian, groupingBy(Dish::getType)));

Map<Boolean, Dish> mostCaloricPartitionedByVegetarian = menu.stream()
    .collect(partitioningBy(Dish::isVegetarian, 
        collectingAndThen(maxBy(comparingInt(Dish::getCalories)), Optional::get)));
````

<br>

