## 영속성 컨텍스트
엔티티를 영구 저장하는 환경  
1차 캐시와 쓰기 지연 SQL 저장소 포함  
엔티티 수정 및 변경 감지(dirty checking)  
엔티티를 데이터베이스에 저장하는 것이 아닌 영속성 컨텍스트를 통해 영속화  

````java
EntityManager.persist(entity);
````

영속성 컨텍스트는 논리적인 개념

    J2SE 환경 : 엔티티 매니저와 영속성 컨텍스트 1:1 대응
    J2EE 환경 : 엔티티 매니저와 영속성 컨텍스트 n:1 대응(스프링 프레임워크 컨테이너 환경)
  
<br>

## 엔티티 생명주기
비영속(new/transient) : 영속성 컨텍스트와 관계없는 새로운 상태

````java
Member member = new Member();
member.setId();
member.setName();
````

영속(managed) : 영속성 컨텍스트에 관리되는 상태

````java
em.persist(member);
````

준영속(detached) : 영속성 컨텍스트에 저장되었다가 분리된 상태
````java
em.detach(member);
````

삭제(removed) : 삭제된 상태, 데이터 베이스에서 삭제
````java
em.remove(member);
````

<br>

## 1차 캐시
영속성 컨텍스트 내에 존재  
em.persist를 통해 1차 캐시 내에 key, value, 초기스냅샷으로 저장  
em.find 호출시 먼저 1차 캐시 탐색 후 존재하지 않으면 데이터 베이스 조회  
데이터 베이스 조회 결과 1차 캐시에 저장  
커밋 시점에 초기 스냅샷과 엔티티를 비교해서 update 쿼리문 생성  
트랜잭션 단위로 생성 및 소멸  

````java
em.find(member1);  // 1차 캐시에 저장된 값없으므로 데이터베이스 조회
em.find(member1);  // 1차 캐시 데이터 반환
````

<br>

## 영속 엔티티 동일성 보장
1차 캐시로 반복가능한 읽기(REPEATABLE READ)등금의 트랜잭션 격리 수준을 제공

````java
Member a = em.find(Member.class, 1L);
Member b = em.find(Member.class, 1L);
Assertion.assertThat(a).isSameAs(b);
````

<br>

## 쓰기 지연 SQL 저장소
발생한 sql 쿼리문을 따로 저장  
트랜잭션 커밋과 함께 sql 쿼리문이 데이터베이스에 플러시(flush), 이후 데이터베이스 커밋  

<br>

## 플러쉬(flush) 발생
변경 감지  
수정된 엔티티 쓰기 지연 sql 저장소에 등록  
쓰기 지연 sql 저장소 쿼리를 데이터베이스에 전송  

````java
em.flush()      // 직접호출
tx.commit()     // 자동호출
JPQL 쿼리 실행    // 자동호출
````

<br>

## 플러시 모드 옵션
커밋이나 쿼리를 실행할 때 플러시, default
````java
em.setFlushMode(FlushModeType.AUTO);
````

커밋할 때만 플러시
````java
em.setFlushMode(FlushModeType.COMMIT);
````

<br>

## 준영속
특정 엔티티만 준영속 상태로 전환
````java
em.detach(entity);
````

영속성 컨텍스트를 완전히 초기화
````java
em.clear();
````

영속성 컨텍스트 종료
````java
em.close();
````

<br>
