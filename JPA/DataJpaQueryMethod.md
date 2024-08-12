## 메서드 이름으로 쿼리 생성
메서드 이름을 분석해서 JPQL 쿼리문 생성  
엔티티의 필드명이 변경되면 인터페이스에 정의한 메서드 이름도 변경필수  

### Distinct, And
    findDistinctByLastnameAndFirstname
    select distinct ... where x.lastname = ?1 and x.firstname = ?2
### Or
    findByLastnameOrFirstname
    ... where x.lastname = ?1 or x.firstname = ?2
### Is, Equals
    findByFirstnameIs, findByFirstnameEquals
    ... where x.firstname = ?1
### Between
    findByStartDateBetween
    ... where x.startDate between ?1 and ?2
### GreaterThan(Equal)
    findByAgeGreaterThan(Equal)
    ... where x.age >(=) ?1
### After
    findByStartDateAfter
    ... where x.startDate > ?1
### Like
    findByFirstnameLike
    ... where x.firstname like ?1
### StartingWith
    findByFirstnameStartingWith
    ... where x.firstname like ?1
    (parameter bound with prepended %)
### Containing
    findByFirstnameContaining
    ... where x.firstname like ?1
    (parameter bound wrapped in %)
### OrderBy
    findByAgeOrderByLastnameDesc
    ... where x.age = ?1 order by x.lastname desc
### Not
    findByLastnameNot
    ... where x.lastname <> ?1
### In
    findByAgeIn(Collection<Age> ages)
    ... where x.age in ?1
### True
    findByActiveTrue()
    ... where x.active = true
### Top
    findTop10ByLastname
    ... where x.lastname = ?1 limit 10
### First
    findFirst10ByLastname
    ... where x.lastname = ?1 offset 10

<br>
