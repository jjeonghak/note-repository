## jOOQ
SQL은 DSL을 광범위하게 사용하는 분야  
jOOQ는 SQL을 구현하는 내부적 DSL로 자바에 직접 내장된 형식 안전 언어  
스트림 API와 조합해서 사용가능  

````sql
# SQL
SELECT * FROM BOOK
WHERE BOOK.PUBLISHED_IN = 2016
ORDER BY BOOK.TITLE
````

<br>

````java
//jOOQ
create.selectFrom(BOOK)
    .where(BOOK.PUBLISHED_IN.eq(2016))
    .orderBy(BOOK.TITLE)

//jOOQ DSL을 이용한 데이터베이스 질의
Class.forName("org.h2.Driver");
try (Connection c = getConnection("jdbc:h2:~/database", "sa", "")) {
    DSL.using(c)
      .select(BOOK.AUTHOR, BOOK.TITLE)
      .where(BOOK.PUBLISHED_IN.eq(2016))
      .orderBy(BOOK.TITLE)
      .fetch()
      .stream()
      .collect(groupingBy(r -> r.getValue(BOOK.AUTHOR),
          LinkedHashMap::new, mapping(r -> r.getValue(BOOK.TITLE), toList())))
      .forEach((author, titles) -> System.out.println(author + " is author of " + titles));
}
````

<br>


