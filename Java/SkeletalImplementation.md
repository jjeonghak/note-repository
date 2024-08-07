## 추상 골격 구현 클래스(템플릿 메서드 패턴)
인터페이스와 함께 사용함으로 인터페이스와 추상 클래스의 장점을 모두 제공  
인터페이스로 타입을 정의(필요시 디폴트 메서드까지)  
골격 구현 클래스는 나머지 메서드를 구현  
추상 클래스처럼 구현을 도와주는 동시에, 추상 클래스로 타입을 정의할 때의 제약에서 자유로움  
관례상 AbstractInterface 형태로 작명(AbstractCollection, AbstractSet, AbstractList 등)  

<br>

### 골격 구현을 사용한 구체 클래스
````java
static List<Integer> intArrayAsList(int[] a) {
    Object.requireNull(a);
    
    return new AbstractList<>() {
        //오토박싱
        @Override public Integer get(int i) { return a[i]; }
        
        @Override public Integer set(int i, Integer val) {
            int oldVal = a[i];
            a[i] = val;         //오토언박싱
            return oldVal;      //오토박싱
        }
        
        @Override public int size() { return a.length; }
    };
}
````

<br>

## 골격 구현 작성
1. 인터페이스의 기반 메서드 선정  
2. 기반 메서드를 사용해 직접 구현 가능한 메서드를 모두 디폴트 메서드로 제공(단 equals, hashCode 등 Object 메서드 제외)  
3. 만약 인터페이스의 메서드 모두 기반 메서드와 디폴트 메서드라면 골격 구현 클래스 필요없음  

````java
//Map.Entry 인터페이스의 getKey, getValue 메서드는 기반 메서드
public abstract class AbstractMapEntry<K,V> implements Map.Entry<K,V> {
    //변경 가능한 엔트리는 이 메서드 반드시 재정의
    @Override public V setValue(V value) {
        throw new UnsupportedOperationException();
    }
    
    @Override public boolean equals(Object o) {
        if (o == this)
            return true;
        if (!(o instanceof Map.Entry))
            return false;
        Map.Entry<?,?> e = (Map.Entry) o;
        return Objects.equals(e.getKey(), getKey()) && Objects.equals(e.getValue(), getValue());
    }
    
    @Override public int hashCode() {
        return Objects.hashCode(getKey()) ^ Objects.hashCode(getValue());
    }
    
    @Override public String toString() {
        return getKey() + "=" + getValue();
    }
}
````

<br>
