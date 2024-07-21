## null과 빈 컬렉션
반환값이 없는 경우 흔히 null 또는 빈 컬렉션 사용  
null을 반환하는 경우 클라이언트는 null 가드 코드를 필수로 사용  
null이 아닌, 빈 배열이나 컬렉션 반환을 권장  

````java
//null 반환 - 권장하지 않음
private final List<Cheese> cheesesInStock = ...;
public List<Cheese> getCheese() {
    return cheesesInStock.isEmpty() ? null
        : new ArrayList<>(cheesesInStock);
}

List<Cheese> cheeses = shop.getCheeses();
if (cheese != null && cheeses.contains(Cheese.STILTON))  //null 가드 추가
    System.out.println("good");
````

<br>

## 빈 컬렉션 반환
````java
public List<Cheese> getCheeses() {
    return new ArrayList<>(cheesesInStock); //불변 컬렉션 공유
}
````

<br>

## 컬렉션 최적화
````java
public List<Cheese> getCheeses() {
    return cheesesInStock.isEmpty() ? Collections.emptyList()   //매번 새로운 빈 컬렉션 할당할 필요없음
        : new ArraryList<>(cheesesInStock);
}
````

<br>

## 빈 배열 반환
````java
public Cheese[] getCheeses() {
    return cheesesInStock.toArray(new Cheese[0]);   //길이 0짜리 반환 타입 배열 사용
}
````

<br>

## 배열 최적화
````java
private static final Cheese[] EMPTY_CHEESE_ARRAY = new Cheese[0];
public Cheese[] getCheeses() {
    return cheesesInStock.toArray(EMPTY_CHEESE_ARRAY);    //매번 새로운 빈 배열 할당할 필요없음
}
````
    
<br>

