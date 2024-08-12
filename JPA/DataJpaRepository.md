## 공통 인터페이스 구성
  
[ Spring Data ]
````
+--- Repository   
 
    +--- CrudRepository 
          save(S) : S
          findByID(ID) : Optional<T>
          exists(ID) : boolean
          count() : long
          delete(T)
          ...
     
        +--- PagingAndSortingRepository 
              findAll(Sort) : Iterable<T>
              findAll(Pageable) : Page<T>
         
              [ Spring Data JPA ]
             +--- JpaRepository
                    findAll() : List<T>
                    findAll(Sort) : List<T>
                    findAll(Iterable<ID>) : List<T>
                    save(Iterable<S>) : List<S>
                    flush()
                    saveAndFlush<T> : T
                    deleteInBatch(Iterable<T>)
                    deleteAllInBatch()
                    getOne(ID) : T
````

<br>

## 제네릭 타입
T : 엔티티  
ID : 엔티티의 식별자  
S : 엔티티와 자식 타입  

<br>

## 주요 메서드
save(S) : 새로운 엔티티는 저장하고 이미 존재하는 엔티티는 병합처리  
findAll(...) : 모든 엔티티 조회, 정렬이나 페이징 조건 파라미터 제공 가능  
delete(T) : EntityManager.remove() 호출  
findById : EntityManager.find() 호출  
getOne(ID) : EntityManager.getReference() 호출  
  
<br>

