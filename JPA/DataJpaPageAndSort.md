## 페이징과 정렬 파라미터
org.springframework.data.domain.Sort : 정렬 기능  
org.springframework.data.domain.Pageable : 페이징 기능  

<br>

## 반환타입
org.springframework.data.domain.Page : 추가 count 쿼리 결과 포함하는 페이징  
org.springframework.data.domain.Slice : 추가 count 쿼리 없이 다음 페이지만 확인 가능(limit + 1)  
List : 추가 count 쿼리 없이 결과만 반환  

<br>

## 페이징
만약 left join 같이 카운트 쿼리에 영향을 미치지 않는 경우 카운트 쿼리 따로 분리  

````java
 @Query(value = "select m from Member m left join m.team t", countQuery = "select count(m) from Member m")
````

[JpaRepository]
````java
Page<Member> findPageByAge(int age, Pageable pageable);
Slice<Member> findSliceByAge(int age, Pageable pageable);

PageRequest pageRequest = PageRequest.of(page: 0, size: 3,
        Sort.by(Sort.Direction.DESC, ...properties: "username"));
Page<Member> page = memberRepository.findPageByAge(age, pageRequest);
Slice<Member> slice = memberRepository.findSliceByAge(age, pageRequest);

page.getNumber()  //현재 페이지 반환
page.getTotalElements()  //데이터 갯수 반환
page.getTotalPages()  //총 페이지 반환
page.isFirst()  //현재 페이지가 시작페이지인지
page.hasNext()  //다음 페이지가 존재하는지
page.map(member -> new MemberDto())  //map을 통해 Dto 변환가능
````

<br>

## 웹 페이징
파라미터 값을 이용해서 PageRequest 객체 자동 바인딩

[application.yml]
````yaml
data:web:pageable:default-page-size: 20
data:web:pageable:max-page-size: 1000 
````

````
GET Request
http://localhost:8080/members?page=0&size=20&sort=id,desc
````

````java
@GetMapping("/members")
public Page<Member> list(@PageableDefault(size = 5, sort = "id") Pageable pageable) {
    return memberRepository.findAll(pageable);
}
````

<br>

## 접두사
둘 이상의 페이징 정보는 접두사로 구분

````
GET Request
http://localhost:8080/member_page=0&order_page=1
````

````java
@Qualifier("member") Pageable memberPageable,
@Qualifier("order") Pageable orderPageable
````

<br>

## 1 페이지부터 시작
1. PageRequest 사용자 정의  
    Pageable과 Page를 파라미터와 응답값으로 사용하지 않고, 직접 클래스를 구현  
  
2. spring.data.web.pageable.one-indexed-parameters: true  
    web의 page 파라미터에 -1 처리만 할뿐(0은 그대로, page=0 == page=1)   
    pageable 정보들은 인덱스 0부터 시작 그대로 유지  

<br>
