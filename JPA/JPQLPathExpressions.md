## 경로 표현식
점(.)을 찍어서 객체 그래프 탐색

````
select m.name          //상태 필드
from Member m
      join m.team t    //단일 값 연관 필드
      join m.orders o  //컬렉션 값 연관 필드
where t.name = "A"    
````

<br>

## 필드 종류
1. 상태 필드(state field) : 단순히 값을 저장하기 위한 필드  
      경로 탐색의 끝, 추가적인 탐색불가  
  
2. 연관 필드(association field) : 연관관계를 위한 필드, 묵시적 조인 실무사용금지  

<br>

### 단일 값 연관 필드  
묵시적 내부 조인 발생, 추가적인 탐색 가능(@ManyToOne, @OneToOne, 엔티티)

````
 /* select m.team from Member m */
 SELECT 
        TEAM_ID as id,
        TEAM_NAME as name
 FROM
        MEMBER member
 INNER JOIN
        TEAM team
 ON member.TEAM_ID = team.id
````  

<br>

### 컬렉션 값 연관 필드  
묵시적 내부 조인 발생, 추가적인 탐색불가(@OneToMany, @ManyToMany, 컬렉션)  
추가적인 탐색을 하려면 묵시적 조인이 아닌 명시적 조인으로 별칭을 얻어야 가능  

````
/* select m.name from Team t join t.members m */
/* select t.members from Team t */
SELECT
        MEMBER_ID as id,
        MEMBER_NAME as name,
        MEMBER_TEAM_ID as TEAM_ID
FROM
        TEAM team
INNER JOIN
        MEMBER member
ON team.id = member.TEAM_ID
````


