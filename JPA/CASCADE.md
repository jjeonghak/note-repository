## 영속성 전이
특정 엔티티를 영속상태로 만들 떄 연관된 엔티티도 함께 영속상태로 만듬  
영속성 전이는 연관관계 매핑과 관련없음  
관리하는 부모 클래스가 하나(단일 종속, 단인 소유)인 경우 사용, 여러 부모클래스가 있는 경우 사용금지  

        ALL : 모두 적용
        PERSIST : 영속
        REMOVE : 삭제
        MERGE : 병합
        REFRESH : refresh 
        DETACH : detach

````java
@OneToMany(mappedBy = "parent", cascade = CascadeType.ALL)
````
<br>

## 고아 객체
부모 엔티티와 연관관계가 끊어진 자식 엔티티  
참조하는 곳이 하나일때 사용, 특정 엔티티가 개인 소유인 경우  
콜렉션에서 제거된 자식 엔티티 자동 delete
````java
@OneToMany(mappedBy = "parent", orphanRemoval = true)
private List<Child> childList = new ArrayList<>();
````
부모가 제거되면 자식도 고아, CascadeType.REMOVE처럼 동작

<br>

## 영속성 전이 및 고아 객체
자식 엔티티의 생명주기를 부모 엔티티를 통해서 관리가능  
도메인 주도 설계(DDD)의 Aggregate Root 개념을 구현할 때 유용  

````java
@OneToMany(mappedBy = "parent", cascade = CascadeType.ALL, orphanRemoval = true)
````

<br>
