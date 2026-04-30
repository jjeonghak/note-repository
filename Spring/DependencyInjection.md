## 의존관계 자동 주입
스프링 컨테이너가 관리하는 스프링 빈이어야 동작  
  
생성자 주입  

      생성자를 통해서 의존 관계 주입
      다른 의존관계 주입과 달리 빈 생성(생성자 호출)시점에 한번만 호출되는 것 보장
      불변, 필수 의존관계에 사용
      생성자가 하나인 경우 @Autowired 어노테이션 생략가능
      
수정자 주입(setter 주입)  

      필드의 값 변경하는 set 메서드를 통해서 의존관계 주입
      자바빈 프로퍼티 규약에 맞게 필드의 값을 직접 변경하지 않고 메서드 이용
      선태, 변경 가능성이 있는 의존관계에 사용
      @Autowired(required = false) 어노테이션으로 선택적으로 사용(주입할 대상이 없어도 동작)
      
필드 주입

      필드에 바로 주입
      @Autowired 어노테이션과 함께 필드 변수 선언
          Field injection is not recommended
      DI 프레임워크가 없는 경우 동작불가
      
일반 메서드 주입  

      생성자 및 수정자 메서드가 아닌 일반 메서드에 @Autowired 어노테이션을 붙여서 사용
      한번에 여러 필드를 주입받을 수 있음
  
  
## @Autowired 옵션
````java
//결과 : noBean1 메서드 자체가 호출되지않음
@Autowired(required = false)
public void setNoBean1(NoBeanData noBean1) {
    System.out.println("noBean1 = " + noBean1);
}

//결과 : noBean2 = null
@Autowired
public void setNoBean2(@Nullable NoBeanData noBean2) {
    System.out.println("noBean2 = " + noBean2);
}

//결과 : noBean3 = Optional.empty
@Autowired
public void setNoBean3(Optional<NoBeanData> noBean1) {
    System.out.println("noBean3 = " + noBean3);
}
````

<br>
  
## 조회 대상 빈이 2개 이상  
1. @Autowired 필드명, 파라미터명  
      먼저 타입 매칭, 매칭 결과가 2개 이상일 경우 필드명과 파라미터명으로 빈 이름 매칭
      
2. @Qualifier 추가 구분자  

        @Qualifier("qualifierName") 어노테이션끼리 같으면 매칭
        qualifierName 구분자도 못찾은 경우 qualifierName 이름의 빈 탐색
      
3. @Primary  

       우선순위 지정, 여러 빈이 매칭된 경우에 우선권 획득
        @Qualifier 추가 구분자보단 우선수위 낮음(디테일이 높은 것부터)
  
  <br>
  
  
  
