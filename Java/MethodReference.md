## 메서드 참조
람다와 익명 클래스보다 간결함  

````java
//람다를 사용한 merge 메서드
map.merge(key, 1, (count, incr) -> count + incr);
//merge 메서드는 키, 값, 함수를 인수로 받음
//키가 맵 안에 없다면 키와 값을 매핑
//이미 존재한다면 함수를 현재 값과 주어진 값에 적용

//정적 메서드 참조
map.merge(key, 1, Integer::sum);
````

<br>

## 람다가 좀더 직관적인 경우
주로 참조되는 메서드와 람다가 같은 클래스에 존재하는 경우

````java
service.excute(GoshThisClassNameIsHumongous::action);
service.excute(() -> action());
````

<br>

## 참조유형
1. 정적 메서드 참조  
    ````
    Integer::parseInt             //str -> Integer.parseInt(str)
    ````

2. 인스턴스 메서드 참조  
    ````
    1) 한정적 인스턴스 메서드 참조  
      수신 객체(receiving object; 참조 대상 인스턴스)를 특정  
        Instant.now()::isAfter    //Instant then = Instant.now(); t -> then.isAfter(t)

    2) 비한정적 인스턴스 메서드 참조  
      함수 객테를 적용하는 시점에서 수신 객체를 알려줌  
        String::toLowerCase       //str -> str.toLowerCase()
    ````

3. 생성자 메서드 참조  
    ````
    1) 클래스 생성자  
      TreeMap<K,V>::new           //() -> new TreeMap<K,V>()
   
    2) 배열 생성자  
      int[]::new                  //len -> new int[len]
    ````

<br>

