## 인터페이스 지원
QuerydslPredicateExecutor 인터페이스 제공  
조인불가, 묵시적 조인은 가능하지만 left join 불가  
클라이언트가 Querydsl에 의존관계 생성  

````java
public interface QuerydslPredicateExecutor<T> {
    Optional<T> findById(Predicate predicate);
    Iterable<T> findAll(Predicate predicate);
    long count(Predicate predicate);
    boolean exists(Predicate predicate);
    // ... more functionality omitted
}
````

<br>

## 웹 지원
단순한 조건만 가능  
조건을 커스텀하는 기능이 복잡하고 명시적이지 않음  
  
쿼리파라미터
````java
    ?firstname=Dave&lastname=Matthews
````

자동 파라미터 바인딩
````java
QMember.member.firstname.eq("Dave").and(QMember.member.lastname.eq("Matthews"))
````

````java
@Controller
class MemberController {

    @Autowired MemberRepository memberRepository;

    @RequestMapping(value = "/", method = RequestMethod.GET)
    public String index(Model model, @QuerydslPredicate(root = Member.class) Predicate predicate,    
                        Pageable pageable, @RequestParam MultiValueMap<String, String> parameters) {
        model.addAttribute("members", repository.findAll(predicate, pageable));
        return "index";
    }
}

interface MemberRepository extends CrudRepository<Member, String>, QuerydslPredicateExecutor<Member>, QuerydslBinderCustomizer<QMember> {
    @Override
    default void customize(QuerydslBindings bindings, QMember member) {
        bindings.bind(member.username)
            .first((path, value) -> path.contains(value));

        bindings.bind(String.class)
            .first((StringPath path, String value) -> path.containsIgnoreCase(value)); 

        bindings.excluding(member.password);                                           
    }
}
````

<br>

## 리포지토리 지원
QuerydslRepositorySupport 추상 클래스 지원  
자체적으로 entityManager 및 querydsl 보유  
from 절부터 시작, select 절 마지막  
페이징의 offset, limit 기능 지원, 하지만 sort 지원 불가능  

````java
public abstract class QuerydslRepositorySupport {
    private @Nullable EntityManager entityManager;
    private @Nullable Querydsl querydsl;
    // ... more functionality omitted
}

JPQLQuery<MemberTeamDto> jpaQuery = from(m)
      .leftJoin(m.team, t)
      .where(
              usernameEq(condition.getUsername()),
              teamNameEq(condition.getTeamName()),
              ageGoe(condition.getAgeGoe()),
              ageLoe(condition.getAgeLoe())
      )
      .select(new QMemberTeamDto(
              m.id.as("memberId"), m.username, m.age,
              t.id.as("teamId"), t.name.as("teamName")
      ));

JPAQuery<MemberTeamDto> query = getQuerydsl().applyPagination(pageable, jpaQuery);
query.fetch();
````

<br>

## Querydsl 지원 클래스 직접 만들기
QuerydslRepositorySupport 한계를 극복하기 위해 직접 지원 클래스 구현

1. 스프링 데이터가 제공하는 페이징을 편리하게 변환  
2. 페이징과 카운트 쿼리 분리 기능  
3. 스프링 데이터 sort 지원  
4. select, selectFrom 절로 시작 기능 제공  
5. entityManager, queryFactory 제공  

````java
@Repository
public abstract class Querydsl4RepositorySupport {

    private final Class domainClass;
    private Querydsl querydsl;
    private EntityManager entityManager;
    private JPAQueryFactory queryFactory;

    public Querydsl4RepositorySupport(Class<?> domainClass) {
        Assert.notNull(domainClass, "Domain class must not be null!");
        this.domainClass = domainClass;
    }

    @Autowired
    public void setEntityManager(EntityManager entityManager) {
        Assert.notNull(entityManager, "EntityManager must not be null!");
        JpaEntityInformation entityInformation = JpaEntityInformationSupport.getEntityInformation(domainClass, entityManager);
        SimpleEntityPathResolver resolver = SimpleEntityPathResolver.INSTANCE;
        EntityPath path = resolver.createPath(entityInformation.getJavaType());
        this.entityManager = entityManager;
        this.querydsl = new Querydsl(entityManager, new PathBuilder<>(path.getType(), path.getMetadata()));
        this.queryFactory = new JPAQueryFactory(entityManager);
    }

    @PostConstruct
    public void validate() {
        Assert.notNull(entityManager, "EntityManager must not be null!");
        Assert.notNull(querydsl, "Querydsl must not be null!");
        Assert.notNull(queryFactory, "QueryFactory must not be null!");
    }

    protected JPAQueryFactory getQueryFactory() {
        return queryFactory;
    }

    protected Querydsl getQuerydsl() {
        return querydsl;
    }

    protected EntityManager getEntityManager() {
        return entityManager;
    }

    protected <T> JPAQuery<T> select(Expression<T> expr) {
        return getQueryFactory().select(expr);
    }

    protected <T> JPAQuery<T> selectFrom(EntityPath<T> from) {
        return getQueryFactory().selectFrom(from);
    }

    protected <T> Page<T> applyPagination(Pageable pageable, Function<JPAQueryFactory, JPAQuery> contentQuery) {
        JPAQuery jpaQuery = contentQuery.apply(getQueryFactory());
        List<T> content = getQuerydsl()
            .applyPagination(pageable, jpaQuery)
            .fetch();
        return PageableExecutionUtils.getPage(content, pageable, jpaQuery::fetchCount);
    }

    protected <T> Page<T> applyPagination(Pageable pageable,
                                          Function<JPAQueryFactory, JPAQuery> contentQuery, Function<JPAQueryFactory,
                                          JPAQuery> countQuery) {
        JPAQuery jpaContentQuery = contentQuery.apply(getQueryFactory());
        List<T> content = getQuerydsl()
            .applyPagination(pageable, jpaContentQuery)
            .fetch();
        JPAQuery countResult = countQuery.apply(getQueryFactory());
        return PageableExecutionUtils.getPage(content, pageable, countResult::fetchCount);
    }
}
````  

<br>
