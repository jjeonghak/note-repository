## List
1. ArrayList

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(1) |
| remove | O(n) |
| get | O(1) |
| contains | O(n) |
| iterator.remove | O(n) |

데이터 추가, 삭제를 위해 임시 배열 생성, 성능 저하  
데이터 인덱스 보유, 검색시 빠름  

<br>

2. LinkedList

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(1) |
| remove | O(1) |
| get | O(n) |
| contains | O(n) |
| iterator.remove | O(1) |

데이터 저장하는 각 노드가 이전 노드, 다음 노드만 알고 있음  
데이터 추가/삭제 빠름  
데이터 검색은 순차 검색  

<br>

3. CopyOnWriteArrayList

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(n) |
| remove | O(n) |
| get | O(1) |
| contains | O(n) |
| iterator.remove | O(n) |

처리에 오버로드 발생  
순회 작업의 수에 비해 수정 횟수가 최소일때 효과적  
get 최적화(ArrayList보다는 느림)  

<br>

## Set
1. HashSet

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(1) |
| contains | O(1) |
| next | O(h/n) //h는 테이블 용량 |

순서없이 저장 및 중복 허용 안함
null 허용
thread-safe 보장 안함

<br>

2. LinkedHashSet

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(1) |
| contains | O(1) |
| next | O(1) |

HashSet보다 느리지만 좋은 성능 보장
등록한 순으로 정렬
null 허용
thread-safe 보장 안함

<br>

3. CopyOnWriteArraySet

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(1) |
| contains | O(1) |
| next | O(1) |

적은 메모리 사용  
null 허용 안함  

<br>

4. TreeSet

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(log n) |
| contains | O(log n) |
| next | O(log n) |

객체 기준으로 정렬  
느린 성능  
null 허용 안함  
thread-safe 보장 안함  

<br>

5. ConcurrentSkipListSet

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(log n) |
| contains | O(log n) |
| next | O(1) |

객체 기준으로 정렬  
null 허용 안함  
thread-safe 보장, 병렬 보장  

<br>

## Map
1. HashMap

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(1) |
| containsKeys | O(1) |
| next | O(h/n) //h는 테이블 용량 |

순서없이 저장  
null 허용  
thread-safe 보장 안함  

<br>

2. LinkedHashMap

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(1) |
| containsKeys | O(1) |
| next | O(1) |

순서대로 등록  
null 허용  
thread-safe 보장 안함  

<br>

3. IdentityHashMap

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(1) |
| containsKeys | O(1) |
| next | O(h/n) //h는 테이블 용량 |

Map 형식에 부합되지 않음  

<br>

4. EnumMap

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(1) |
| containsKeys | O(1) |
| next | O(1) |

<br>

5. TreeMap

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(log n) |
| containsKeys | O(log n) |
| next | O(log n) |

정렬하면서 추가  
null 허용 안함  
thread-safe 보장 안함  

<br>

6. ConcurrentHashMap

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(1) |
| containsKeys | O(1) |
| next | O(h/n) //h는 테이블 용량 |

thread-safe 보장, SynchronizedMap보다 빠름  
null 허용 안함  

<br>

7. ConcurrentSkipListMap

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| add | O(log n) |
| containsKeys | O(log n) |
| next | O(1) |

thread-safe 보장, SynchronizedMap보다 빠름  
메모리를 사용하고 병렬 처리에 용의  

<br>

## Queue
1. PriorityQueue

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| offer | O(log n) |
| peek | O(n) |
| poll | O(log n) |
| size | O(1) |
| natural order | ASCII 순으로 정렬 |

natural order 순으로 정렬  
null 허용 안함  

<br>

2. ConcurrentLinkedQueue

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| offer | O(1) |
| peek | O(1) |
| poll | O(1) |
| size | O(n) |

데이터 추가/삭제 빠름  
크기 계산에 시간 소요  
null 허용 안함  

<br>

3. ArrayBlockingQueue

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| offer | O(1) |
| peek | O(1) |
| poll | O(1) |
| size | O(1) |

고정 배열에 일반적인 큐  
배열이 고정된 사이즈로 생성 후 변경 불가  

<br>

4. LinkedBlockingQueue

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| offer | O(1) |
| peek | O(1) |
| poll | O(1) |
| size | O(1) |

크기 지정하지 않은 경우 Integer.MAX_VALUE  
삽입이 동적으로 동작  

<br>

5. PriorityBlockingQueue

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| offer | O(log n) |
| peek | O(1) |
| poll | O(log n) |
| size | O(1) |

PriorityQueue와 같은 방식으로 정렬  
자원 고갈시 오류 발생  

<br>

6. DelayQueue

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| offer | O(log n) |
| peek | O(1) |
| poll | O(log n) |
| size | O(1) |

지연이 만료된 경우 요소를 조회 가능  

<br>

7. ArrayDeque

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| offer | O(1) |
| peek | O(1) |
| poll | O(1) |
| size | O(1) |

양 측면에서 요소를 추가하거나 제거 가능  
확장 가능한 배열의 특별한 종류  

<br>

8. LinkedBlockingDeque

| 메서드 | 시간 복잡도 |
| ---- | ---- |
| offer | O(1) |
| peek | O(1) |
| poll | O(1) |
| size | O(1) |

무제한으로 인스턴스화 가능  

<br>
