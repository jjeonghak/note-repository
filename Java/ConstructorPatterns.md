## 점층적 생성자 패턴
생성자를 오버로딩해서 매개변수에 따라 생성자 호출  
매개변수 갯수가 많아지면 클라이언트 코드를 작성하기 어려움  

````java
public class NutritionFacts {
    private final int servingSize;    //필수
    private final int servings;       //필수
    private final int calories;       //선택
    private final int fat;            //선탣
    private final int sodium;         //선택
    private final int carbohydrate;   //선택

    public NutritionFacts(int servingSize, int servings) {
        this(servingSize, servings, 0);
    }

    public NutritionFacts(int servingSize, int servings, int calories) {
        this(servingSize, servings, calories, 0);
    }

    ...
}
````

<br>

## 자바빈즈 패턴
매개변수가 없는 생성자  
세터 메서드를 통해 매개변수 값 설정  
객체 하나를 생성하기 위해서 많은 메서드 호출  
객체가 완성되기 전까지 일관성 미보장  

````java
public class NutritionFacts {
    private final int servingSize   = -1;  //필수; 기본값 없음
    private final int servings      = -1;  //필수; 기본값 없음
    private final int calories      = 0;
    private final int fat           = 0;
    private final int sodium        = 0;
    private final int carbohydrate  = 0;

    public NutritionFacts() {}
    public void setServingSize(int val)   { servingSize = val; }
    public void setServings(int val)      { servings = val; }
    public void setCalories(int val)      { calories = val; }
    public void setFat(int val)           { fat = val; }
    public void setSodium(int val)        { sodium = val; }
    public void setCarbohydrate(int val)  { carbohtdrate = val; }
}
````

<br>

## 빌더 패턴
필수 매개변수만으로 생성자룰 호출해서 빌더 객체를 통해 객체생성  
빌더는 자신을 반환하기 때문에 연쇄적 호출가능(fluent API, method chaining)  

````java
Nutritionfacts cocaCola = new NutritionFacts.Builder(240, 8)
          .calories(100).sodium(35).carbohydrate(27).build();

public class NutritionFacts {
    private final int servingSize;
    private final int servings;
    private final int calories;
    private final int fat;
    private final int sodium;
    private final int carbohydrate;

    public static class Builder {
        //필수 매개변수
        private final int servingSize;
        private final int servings;
        
        //선택 매개변수 - 기본값으로 초기화
        private final int calories      = 0;
        private final int fat           = 0;
        private final int sodium        = 0;
        private final int carbohydrate  = 0;
        
        public Builder(int servingSize, int servings) {
            this.servingSize = servingSize;
            this.servings    = servings;
        }
        
        public Builder calories(int val)      { this.calories = val; return this; }
        public Builder fat(int val)           { this.fat = val; return this; }
        public Builder sodium(int val)        { this.sodium = val; return this; }
        public Builder carbohydrate(int val)  { this.carbohydrate = val; return this; }
        public NutritionFacts build()         { return new NutritionFacts(this); }
    }
    
    private NutritionFacts(Builder builder) {
        servingSize    = builder.servingSize;
        servings       = builder.servings;
        calories       = builder.calories;
        fat            = builder.fat;
        sodium         = builder.sodium;
        carbohydrate   = builder.carbohydrate;
    }
}
````

<br>

## 계층적 클래스와 빌더 패턴
공변반환 타이핑(convariant return typing) : 하위 클래스가 상위 클래스가 정의한 반환타입이 아닌 하위 타입반환  
클라이언트는 형변환 고려없이 빌더 사용가능  

````java
NyPizza nyPizza = new NyPizza.Builder(SMALL)
        .addTopping(SAUSAGE).addTopping(ONION).build();
Calzone calzone = new Calzone.Builder()
        .addTopping(HAM).sauceInside().build();

public abstract class Pizza {
    public enum Topping { HAM, MUSHROOM, ONION, PEPPER, SAUSAGE }
    final Set<Topping> toppings;
    
    abstract static class Builder<T extends Builder<T>> {
        EnumSet<Topping> toppings= EnumSet.noneOf(Topping.class);
        public T addTopping(Topping topping) {
            topping.add(Objects.requireNonNull(topping));
            return self();
        }
        
        abstract Pizza build();
        
        //하위 클래스는 이 메서드를 재정의하여 this 반환
        protected abstract T self();
    }
    
    Pizza(Builder<?> builder) { toppings = builder.topping.clone(); }
}

public class NyPizza extends Pizza {
    public enum Size { SMALL, MEDIUM, LARGE }
    private final Size size;
    
    public static class Builder extends Pizza.Builder<Builder> {
        private final Size size;
        
        public Builder(Size size) { this.size = Objects.requireNonNull(size); return this; }
        
        @Override public NyPizza build() { return new NyPizza(this); }
        @Overrid protected Builder self() { return this; }
    }
    
    private NyPizza(Builder builder) {
        super(builder);
        size = builder.size;
    }
}

public class Calzone extends Pizza {
    private final boolean sauceInside;
    
    public static class Builder extends Pizza.Builder<Builder> {
        private boolean sauceInside = false; //기본값
        
        public Builder sauceInside() { sauceInside = ture; return this; }
        
        @Override public Calzone build() { return new Calzone(this); }
        @Overrid protected Builder self() { return this; }
    }
    
    private Calzone(Builder builder) {
        super(builder);
        sauceInside = builder.sauceInside;
    }
}
````

<br>

  
