## Buffer

````java
import java.io.*;

BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(System.out));
StringBuilder sb = new StringBuilder();
````

<br>

## Array
고정 크기의 데이터 구조  
같은 타입의 데이터 저장

````java
arr.length;              // 배열 길이 반환
Arrays.toString(arr);    // 배열 요소를 문자열로 출력
Arrays.sort(arr);        // 배열 오름차순 정렬
Arrays.fill(arr, 1);     // 배열 초기화
Arrays.stream(arr);      // 배열 스트림 변환
````

````java
Arrays.sort(arr);                               // 오름차순 정렬
Arrays.sort(arr, Comparator.reverseOrder());    // 내림차순 정렬
````

```java
Sting[] list = Arrays.stream(arr).toArray(String[]::new);    // 리스트로 변환
```

<br>

## ArrayList
동적 배열로 크기를 유동적으로 조정 가능  

````java
list.add(e);          // 리스트의 끝에 요소 추가
list.get(i);          // 주어진 인덱스 요소 반환
list.set(i, e);       // 주어진 인덱스 요소 변경
list.remove(i);       // 주어진 인덱스 요소 제거
list.size();          // 리스트 크기 반환
list.contains(o);     // 리스트 특정 요소 존재 여부 확인
````

````java
Collections.sort(list);                               // 오름차순 정렬
Collections.sort(list, Comparator.reverseOrder());    // 내림차순 정렬

list.sort(Comparator.naturalOrder());                 // 오름차순 정렬
list.sort(Comparator.reverseOrder());                 // 내림차순 정렬
````

````java
import java.util.stream.Collectors;

List<Integer> sortedList = list.stream().sorted().collect(Collectors.toList());    // 스트림 정렬
````

<br>

## LinkedList
연결 리스트로 노드들이 링크로 연결된 형태  
양방향 연결 리스트 제공  

````java
link.add(e);         // 리스트 끝에 요소 추가
link.addFirst(e);    // 리스트 처음에 요소 추가
link.remove(i);      // 주어진 인덱스 요소 제거
link.getFirest();    // 처음 요소 반환
link.getLast();      // 마지막 요소 반환
link.size();         // 리스트 크기 반환
````

<br>

## HashMap
키-값 쌍을 저장하는 해시맵

````java
map.put(k, v);                                             // 주어진 키에 값 저장
map.get(k);                                                // 주어진 키에 해당하는 값 반환
map.remove(k);                                             // 주어진 키와 값 제거
map.containsKey(k);                                        // 키 존재 여부 확인
map.containsValue(v);                                      // 값 존재 여부 확인
map.size();                                                // 엔트리 갯수 반환
map.computeIfAbsent(k, k -> new ArrayList<>()).add(v));    // 키 값이 있는지 조회, 키 없는 경우 콜백 실행
````

````java
for (String key : map.keySet()) { ... }                            // 키 순회
for (Integer value : map.values()) { ... }                         // 값 순회
for (Map.Entry<String, Integer> entry : map.entrySet()) { ... }    // 키-값 엔트리 순회
````
<br>

## HashSet
중복을 허용하지 않는 집합  

````java
set.add(e);         // 요소 추가
set.remove(o);      // 주어진 요소 제거
set.contains(o);    // 특정 요소 존재 여부 확인
set.size();         // 요소 갯수 반환
````

````java
for (String element : set) { ... }    // 값 순회
````

<br>

## Stack
후입선출(LIFO) 자료구조  

````java
stack.push(e);      // 맨 위에 요소 추가
stack.pop();        // 맨 위에 요소 제거 및 반환
stack.peek();       // 맨 위에 요소 반환
stack.isEmpty();    // 요소 존재 여부 확인
````

<br>

## Queue
선입선출(FIFO) 자료구조  

````java
queue.offer(e);     // 끝에 요소 추가
queue.poll();       // 맨 앞에 요소 제거 및 반환
queue.peek();       // 맨 앞에 요소 반환
queue.isEmpty();    // 요소 존재 여부 확인
````

<br>

## PriorityQueue
우선순위가 존재하는 큐  

````java
pq.offer(e);    // 요소 추가
pq.poll();      // 최상위 우선순위 요소 제거 및 반환
pq.peek();      // 최상위 우선순위 요소 반환
````

````java
// 기본 오름차순 정렬
PriorityQueue<Integer> pq = new PriorityQueue<>();

// Comparator 내림차순 정렬
PriorityQueue<Integer> pq = new PriorityQueue<>(Comparator.reverseOrder());

// 커스텀 Comparator 내림차순 정렬
PriorityQueue<Integer> pq = new PriorityQueue<>((a, b) -> b - a);

// 객체에 Comparator 적용, 복합 기준 정렬
PriorityQueue<Person> pq = new PriorityQueue<>(
    Comparator.comparingInt(Person::getAge)                           // 첫 번째 기준: 나이 오름차순
        .thenComparing(Person::getName)                               // 두 번째 기준: 이름 오름차순
);

PriorityQueue<Person> pq = new PriorityQueue<>(
    Comparator.comparingInt(Person::getAge).reversed()                // 첫 번째 기준: 나이 내림차순
        .thenComparing(Person::getName, Comparator.reverseOrder())    // 두 번째 기준: 이름 내림차순
);
````

<br>

## Deque(ArrayDeque)
양방향 삽입 및 삭제 가능 큐  

````java
deque.addFirst(e);      // 맨 앞에 요소 추가
deque.addLast(e);       // 끝에 요소 추가
deque.removeFirst();    // 처음 요소 제거
deque.removeLast();     // 마지막 요소 제거
deque.peekFirst();      // 맨 앞에 요소 반환
deque.peekLast();       // 끝에 요소 반환
````

<br>

## TreeMap
정렬된 키-값 쌍을 저장하는 맵

````java
map.put(k, v);     // 주어진 키에 값 저장
map.get(k);        // 주어진 키에 해당하는 값 반환
map.remove(k);     // 주어진 키에 해당하는 값 제거
map.firstKey();    // 처음 키 반환
map.lastKey();     // 마지막 키 반환
````

<br>

## String
````java
// 문자열 길이 반환
s.length();

// 주어진 인덱스에 해당하는 문자 반환
s.charAt(index);

// 주어진 시작 인덱스부터 끝 인덱스 전까지의 부분 문자열 반환
s.substring(beginIndex);
s.substring(beginIndex, endIndex);

// 주어진 문자열이 처음 또는 마지막으로 등장하는 인덱스 반환. 없는 경우 -1 반환
s.indexOf(str);
s.lastIndexOf(str);

// 문자열이 주어진 문자열을 포함하는지 여부 반환
s.contains(charSequence);

// 문자열의 접두사 또는 접미사 확인
s.startsWith(prefix);
s.endsWith(suffix);

// 문자열 내에서 주저진 문자 또는 정규식에 맞는 부분을 모두 대체
s.replace(target, replacement);
s.replaceAll(regex, replacement);

// 문자열을 소문자 또는 대문자로 변환한 결과 반환
s.toLowerCase();
s.toUpperCase();

// 문자열을 주어진 정규식으로 분리하여 문자열 배열로 반환
s.split(regex);

// 문자열의 앞뒤 공백 제거한 결과 반환
s.trim();

// 두 문자열이 동일한지 비교(대소문자 구분 또는 무시)
s.equals(anotherString);
s.equalsIgnoreCase(anotherString);

// 문자열이 비어 있는지 확인
s.isEmpty();

// 문자열이 주어진 정규식과 일치하는지 확인
s.matches(regex);

// 문자열을 문자 배열로 변환한 결과 반환
s.toCharArray();
````

<br>

## Pair

````java
private static class Pair implements Comparable<Pair> {
    private int x;
    private int y;

    private Pair(int x, int y) {
        this.x = x;
        this.y = y;
    }

    @Override
    public int compareTo(Pair o) {
        if (this.x != o.x) {
            return Integer.compare(this.x, o.x);
        }
        return Integer.compare(this.y, o.y);
    }
}
````

<br>
