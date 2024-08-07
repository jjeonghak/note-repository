## 컬렉션 팩토리
파이썬이나 그루비 등을 포함한 일부 언어는 컬렉션 리터럴 지원  
자바에서는 언어 변화에 대한 비용 문제로 지원하지 않음  
대신 컬렉션 API를 개선  

<br>

## UnsupportedOperationException
List.of 팩토리 메서드는 고정된 크기의 리스트를 반환  
컬렉션이 의도치 않게 변경되는 것을 막음  
null 요소를 허용하지 않음  

````java
List<String> friends = List.of("Rapheal", "Olivia", "Thibaut");
friends.add("Chin-Chun"); //오류 발생

//오버로드된 List
static <E> List<E> of(E e1, E e2, E e3, E e4)
static <E> List<E> of(E e1, E e2, E e3, E e4, E e5)

//원소의 갯수가 10개 이상인 경우
static <E> List<E> of(E... elements)
````
  
내부적으로 가변 인수 버전은 추가 배열을 할당  
배열 할당 후 초기화에 드는 가비지 컬렉션 비용을 최소화하기 위해 10개 제한  

<br>


## 집합 팩토리
List.of 메서드와 비슷한 방식으로 Set.of 메서드 동작  
중복된 요소를 제공하면 IllegalArgumentException 오류 발생  

````java
Set<String> friends = Set.of("Raphael", "Olivia", "Olivia");
````

<br>

## 맵 팩토리
리스트나 집합에 비해 복잡  
키와 값을 번갈아 제공하는 방식 존재  

````java
//10개 이하의 원소에 대해서 유용
Map<String, Integer> ageOfFriends = Map.of("Raphael", 30, "Olivia", 25, "Thibaut", 26);

//가변 인수 사용
Map<String, Integer> ageOfFriends = Map.ofEntries(
      Map.entry("Raphael", 30), //MAp.Entry 객체를 만드는 새로운 팰토리 메서드  
      Map.entry("Olivia", 25),
      Map.entry("Thibaut", 26));
````

<br>

## removeif
프레디케이트를 만족하는 요소 제거  

````java
//ConcurrentModificationException 오류 발생
for (Transaction transaction : transactions) {
    if (Character.isDigit(transaction.getReferenceCode().charAt(0))) {
        transactions.remove(transaction);
    }
}

//내부적 동작
for (Iterator<Transaction> iterator = transactions.iterator(); iterator.hasNext(); ) {
    Transaction transaction = iterator.next();
    if (Character.isDigit(transaction.getReferenceCode().charAt(0))) {
        transactions.remove(transaction);   //별도의 두 객체를 통해 컬렉션 변경 문제 발생
    }
}
````

반복자의 상태는 컬렉션 상태와 서로 동기화되지 않음  
Iterator 객체 : next(), hasNext() 메서드를 통해 소스 질의  
Collection 객체 자체 : remove() 메서드를 통해 요소 삭제  

````java
//문제 해결
for (Iterator<Transaction> iterator = tranactions.iterator(); iterator.hasNext(); ) {
    Transaction transaction = iterator.next();
    if (Character.isDigit(transaction.getReferenceCods().charAt(0))) {
        iterator.remove();
    }
}

//새로 추가된 메서드
transactions.removeIf(transaction -> 
    Character.isDigit(transaction.getReferenceCode().charAt(0)));
````

<br>
  
## replaceAll
리스트에서 이용 가능  
UnaryOperator 함수를 이용해 요소 변경  

````java
//리스트의 요소를 새로운 요소로 변경하지만 새로운 컬렉션 생성
referenceCodes.stream()
    .map(code -> Character.toUpperCase(code.charAt(0)) + code.substring(1))
    .collect(Collectors.toList())
    .forEach(System.out::println);

//복잡하지만 기존 컬렉션 변경
for (ListIterator<String> iterator = referenceCodes.listIterator(); iterator.hasNext(); ) {
    String code = iterator.next();
    iterator.set(Character.toUpperCase(code.charAt(0)) + code.substring(1));
}

//새로 추가된 메서드
referenceCodes.replaceAll(code -> Character.toUpperCase(code.charAt(0)) + code.substring(1));
````

<br>

## Map 정렬 메서드
Map 정렬 메서드는 Entry.comparingByValue, Entry.comparingByKey 존재  
자바 8에서 HashMap 내부 구조 변경  
기존 맵은 키로 생성한 해시코드로 접근 가능한 버켓에 저장하는 형식  
해시코드의 중복이 심하면 O(n) LinkedList 버킷을 반환  
O(log(n)) 성능의 정렬된 트리를 이용해 동적 치환으로 성능 개선  
키 값이 String, Number 클래스 같은 Comparable 형태에만 정렬된 트리 지원  

````java
mapList.entrySet()
    .stream()
    .sorted(Entry.comparingByKey())
    .forEachOrdered(System.out::println);
````

<br>

## getOrDefault
기존에는 키에 맞는 값이 존재하지 않는 경우 널 반환  
요청 결과가 null인 경우 기본값 반환  
키가 null인 경우에는 null 반환  

````java
System.out.println(mapList.getOrDefault("Olivia", "Default"));
````

<br>

## 계산 패턴
computeIfAbsent : 제공된 키에 해당하는 값이 없으면 키를 이용해 새로운 값 계산 후 맵에 추가  
computeIfPresent : 제공된 키가 존재하면 새로운 값 계산 후 맵에 추가  
compute : 제공된 키로 새로운 값 계산 후 맵에 저장  

````java
Map<String, byte[]> dataToHash = new HashMap<>();
MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
//키가 존재하지 않으면 calculateDigset 메서드 동작
lines.forEach(line -> dataToHash.computeIfAbsent(line, this::calculateDigset));

private byte[] calculateDigset(String key) {
    return messageDigest.digest(key.getBytes(StandardCharsets.UTF_8));
}

//해당 키에 맞는 리스트가 초기화되지 않은 경우 처리
Map<String, List<String>> mapList = new HashMap<>();
mapList.computeIfAbsent(key, value -> new ArrayList<>())
    .add(value);
````

<br>

## 삭제 패턴
제공된 키에 해당하는 맵 항목을 지우는 remove 메서드  
자바 8에 키가 특정한 값과 연관있는 경우 항목을 제거하는 오버로드된 remove 메서드 지원  

````java
//해당 key에 해당하는 값이 value와 같은 경우 항목 삭제
mapList.remove(key, value);
````

<br>

## 교체 패턴
replaceAll : BiFunction 적용한 결과로 각 항목의 값 교체, 리스트와 동작 유사  
Replace : 키가 존재하면 맵의 값 변경, 키가 특정값으로 매핑된 경우메만 값을 교체하는 오버로드 버전도 존재  

````java
mapList.replaceAll((key, value) -> value.toUpperCase());
````

<br>

## 두개의 맵 병합
두 개의 맵을 합칠때 중복된 키값이 없는 경우 putAll 메서드 사용  
좀더 유연하게 키값이 중복된다면 merge 메서드 사용  
지정된 키와 연관된 값이 없거나 null인 경우 키를 다른 값과 연결  
또는 연결된 값을 주어진 매핑 함수의 결과값으로 대치하거나 결과가 null인 경우 항목 삭제  

````java
//중복 키값 없는 경우
Map<String, String> map1 = Map.ofEntries(
    Map.entry("key1", "value1"), Map.entry("key2", "value2"));
Map<String, String> map2 = Map.ofEntries(
    Map.entry("key3", "value3"), Map.entry("key4", "value4"));
Map<String, String> mergeMap = new HashMap<>(map1);
mergeMap.putAll(map2);

//좀더 유연한 방식
map2.forEach((k, v) -> 
    mergeMap.merge(k, v, (k1, k2) -> k1 + " & " + k2));   //중복된 키값 존재하는 경우 두 값 연결

//merge를 이용한 초기값 설정 및 변경
moviesToCount.merge(movieName, 1L, (key, count) -> count + 1L);
````

<br>

## 개선된 ConcurrentHashMap
ConcurrentHashMap 클래스는 동시성 친화적인 HashMap 버전  
내부 자료구조의 특정 부분만 락을 걸고 동시 추가, 갱신 작업을 허용  
동기화된 Hashtable 버전에 비해 읽기, 쓰기 연산 성능이 월등  
> forEach : 각 키, 값 쌍에 주어진 액션 실행  
> reduce : 모든 키, 값 쌍을 제공된 리듀스 함수를 이용해 결과로 합침  
> sarch : null이 아닌 값을 반환할 때까지 각 키, 값 쌍에 함수 적용  

<br>

해당 연산은 상태에 락을 걸지 않음  
이들 연산에 제공한 함수는 연산중 변경 가능한 객체, 값, 순서에 의존하지 않아야 함  
1. 키, 값으로 연산 : forEach, reduce, search  
2. 키로 연산 : forEachKey, reduceKeys, searchKeys  
3. 값으로 연산 : forEachValue, reduceValues, searchValues  
4. Map.Entry 객체로 연산 : forEachEntry, reduceEntries, searchEntries  


<br>
