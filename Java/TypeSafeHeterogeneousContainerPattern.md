## 타입 안전 이종 컨테이너 패턴
컨테이너 대신 키를 매개변수화  
컨테이너에 값을 넣거나 뺄 때 매개변수화한 키를 함께 제공  
제네릭 타입 시스템이 값의 타입이 키와 같음을 보장  
    
### 타입 안전 이종 컨테이너 패턴 - API
````java
public class Favorites [
    private Map<Class<?>, Object> favorites = new HashMap<>();

    public <T> void putFavorite(Class<T> type, T instance) {
        favorites.put(Obejects.requireNull(type), instance);
    }
    
    public <T> T getFavorite(Class<T> type) {
        return type.cast(favorites.get(type));
    }
}
````

<br>

### 타입 안전 이종 컨테이너 패턴 - 클라이언트
````java
public static void main(String[] args) {
    Favorites f = new Favorites;
    
    f.putFavorite(String.class, "string");
    f.putFavortie(Integer.class, 0xcafebabe);
    f.putFavorite(Class.class, Favorites.class);
    
    String favoriteString = f.getFavorite(String.class);
    int favoriteInteger = f.getFavorite(Integer.class);
    Class<?> favoriteClass = f.getFavorite(Class.class);
}
````

<br>

## 타입 안전 이종 컨테이너 패턴 제약
1. 악의적인 클라이언트가 Class 객체가 아닌 로 타입으로 파라미터 전달시 타입 안전성 보장 불가  
2. 실체화 불가 타입에 사용 불가  
    닐 개프터가 고안한 슈퍼 타입 토큰(super type token)으로 일부 해결 가능  
    스프링 프레임워크는 ParameterizedTypeReference 클래스로 미리 구현  

    ````java
    Favorites f = new Favorites();
    List<String> pets = Arrays.asList("a", "b", "c");
    f.putFavorite(new TypeRef<List<String>>(){}, alpha);
    List<String> listofStrings = f.getFavorite(new TypeRef<Lsit<String>>(){});
    ````

<br>
