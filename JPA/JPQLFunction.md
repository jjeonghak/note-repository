## case식
기본 case식

    select
        case when m.age <= 10 then '학생요금'
             when m.age >= 60 then '경로요금'
             else '일반요금'
        end
    from Member m
  
단순 case식

    select
        case t.name
             when 'A' then 'ATeam'
             when 'B' then 'BTeam'
             else 'CTeam'
        end
    from Team t 

COALESCE : 하나씩 조회해서 null이 아니면 반환

    select coalesce (m.name, 'name is not null') from Member m
  
NULLIF : 두 값이 동일하면 null, 다르면 첫번째 값 반환

    select nullif(m.name, 'ADMIN') from Member m

<br>

## JPQL 함수

### JPQL 표준 함수
DB 상관없이 사용가능

CONCAT : 문자열 이어붙임

    select concat ('string 1', 'string 2') from Member m
    select 'string 1' || 'string 2' from Member m

SUBSTRING : 문자열에서 지정한 인덱스부터 지정한 갯수만큼만 반환

    select substring (m.name, 1, 3) from Member m

TRIM : 문자열 앞뒤 공백 제거

    select trim ('  delete first and last space  ') from Member m    

LENGTH : 문자열의 길이 반환

    select length ('count string length') from Member m

LOCATE : 문자열 내에서 문자열 탐색

    select locate ('target', 'return target location at string') from Member m

UPPER(LOWER) : 대소문자 변환

    select upper (m.name) from Member m

숫자 함수

    ABS, MOD, SQRT

집계 함수

    MIN, MAX, SUM, AVG, COUNT, DISTINCT

JPA 용도

    SIZE : 컬렉션 크기 반환
        select size (t.members) from Team t
        
    INDEX : @OrderColumn 어노테이션과 list 타입 컬렉션인 경우 컬렉션의 위치 반환 
        select index (t.members) from Team t

<br>

### 사용자 정의 함수
하이버네이트 사용하기 전에 방언 수정

````xml
<property name="hibernate.dialect" value="dialect.MyH2Dialect"/>
````

사용하는 DB 방언을 상속받고 사용자 정의 함수 등록(자세한 등록방법은 해당 DB 방언 참고)
````java
 public class MyH2Dialect extends H2Dialect {
    public MyDialect() {
        registerFunction(name:"group_concat", new StandardSQLFunction(name:"group_concat", StandardBasicTypes.STRING));
    }
}
````

````
select function ('group_concat', m.name) from Member m
select group_concat(m.name) from Member m
````

<br>
