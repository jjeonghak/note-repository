## 페치 조인

    FETCH JOIN ::= [LEFT [OUTER] | INNER ] JOIN FETCH joinPath

sql 조인 종류가 아닌 JPQL 성능 최적화를 위한 조인  
연관된 엔티티나 컬렉션을 sql 쿼리문 한개로 함께 조회(N + 1 문제 해결, 즉시 로딩과 유사)  
다쪽 데이터 크기만큼 데이터 뻥튀기 되어 조회  

### 일대다 
````
select m from Member m join fetch m.team
````
````sql
SELECT M.*, T.* FROM MEMBER M
INNER JOIN TEAM T ON M.TEAM_ID = T.ID
````

### 컬렉션
````
select t from Team t join fetch t.members where t.name  = "teamA"
````
````sql
SELECT T.*, M.* FROM TEAM T
INNER JOIN MEMBER M ON T.ID = M.TEAM_ID
WHERE T.NAME = 'teamA'
````

<br>

## 중복제거
JPQL에서의 distinct

1. sql에 DISTINCT 추가  
      튜플의 모든 속성값이 같아야 중복제거, 한개의 속성만 달라도 제거안됨  
      
2. 애플리케이션에서 엔티티 중복 제거  
      중복 식별자를 가진 엔티티 제거  

<br>

## 일반 조인 비교
일반 조인 실행시 연관된 엔티티를 함께 조회하지 않음    
페치 조인 사용할 때만 연관된 엔티티도 함께 조회(즉시 로딩)    
페치 조인은 객체 그래프를 sql 한번에 조회하는 개념    

````
select t from Team t join t.members
````
````sql
SELECT T.* FROM TEAM T
INNER JOIN MEMBER M ON T.ID = M.TEAM_ID
````

<br>

## 페치 조인 한계
페치 조인 대상에는 별칭 사용 불가   
둘 이상의 컬렉션은 페치 조인 사용 불가(일대 다대다)    
컬렉션 페치 조인 사용시 페이징 API 사용 불가    

    하이버네이트 경고로그 출력후 모든 데이터를 가져와서 메모리에서 페이징(매우 위험)
    WARN: firstResult/maxResilts specified with collection fetch; applying in memory!
  
지연로딩을 할때 연관된 엔티티를 한번에 조회할 크기 선택(N + 1 해결)

    @BatchSize(size = 100)
    
    <property name="hibernate.default_batch_fetch_size" value="100"/>
  
<br>
