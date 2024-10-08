## JPA 페이징 API 추상화
1. setFirstResult(int startPosition) : 조회 시작 위치(0부터 시작)

2. setMaxResults(int maxResult) : 조회할 데이터 수

````java
List<Member> result = em.createQuery(
        "select m from Member m order by m.age desc", Member.class)
        .setFirstResult(0)
        .setMaxResult(10)
        .getResultList();
````

<br>

## MySQL 방언
````sql
SELECT
        M.ID AS ID,
        M.AGE AS AGE,
        M.TEAM AS TEAM_ID,
        M.NAME AS NAME
FROM
        MEMBER M
ORDER BY
        M.NAME DESC LIMIT ?, ?
````

<br>

## Oracle 방언
````sql
SELECT *
FROM
    ( SELECT ROW_.*, ROWNUM ROWNUM_
      FROM
            ( SELECT
                      M.ID AS ID,
                      M.AGE AS AGE,
                      M.TEAM_ID AS TEAM_ID,
                      M.NAME AS NAME
            FROM MEMBER M
            ORDER BY M.NAME
            ) ROW_
      WHERE ROWNUM <= ? )
WHERE ROWNUM_ > ?
````

<br>
