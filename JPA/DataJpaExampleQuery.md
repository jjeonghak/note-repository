## example query
쿼리 조건으로 객체를 넘기는 방식
내부 조인 가능(나머지 조인 불가)

    Probe : 필드에 데이터가 있는 실제 도메인 객체
    ExampleMatcher : 특정 필드를 일치시키는 상세한 정보 제공, 재사용 가능
    Example : Probe와 ExampleMatcher로 구성, 쿼리 생성에 사용

````java
public interface JpaRepository<T, ID> extends QueryByExampleExecutor<T> {
    @Override
    <S extends T> List<S> findAll(Example<S> example);

    @Override
    <S extends T> List<S> findAll(Example<S> example, Sort sort);
}

//when
//probe
Member member = new Member();
Example<Member> example = Example.of(member);
ExampleMatcher matcher = ExampleMatcher.matching().withIgnorePaths("age");
List<Member> result = memberRepository.findAll(example, matcher);
````
  
<br>
