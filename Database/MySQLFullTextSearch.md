# 전문 검색
용량이 큰 문서를 단어 수준으로 쪼개어 문서 검색을 해주는 기능  
문서의 단어를 분리해서 형태소를 인덱싱하는 기법은 서구권 언어에 적합  
한국어, 중국어, 일본어에는 적합하지 않음  
이러한 단점을 보완하기 위해 형태소나 어원에 관계없이 특정 길이 조각으로 인덱싱하는 n-gram 파서 도입  

<br>

## 전문 검색 인덱스의 생성과 검색
`ngram_tocken_size` 시스템 변수로 2 ~ 10 사이 숫자 설정 가능  
일반적으로 n-gram은 `bi-gram`, `tri-gram`이 가장 일반적으로 사용  

```
-- // my.cnf 설정 파일에 아래 설정 추가 후 재시작
-- // ngram_token_size=2;

mysql> CREATE TABLE tb_bi_gram(
         id BIGINT NOT NULL AUTO_INCREMENT,
         title VARCHAR(100),
         body TEXT,
         PRIMARY KEY(id),
         FULLTEXT INDEX fx_msg(title, body) WITH PARSER ngram
       );

mysql> INSERT INTO tb_bi_gram VALUES (NULL, 'Real MySQL', '이 책은 지금까지의 매뉴얼 번역이나
단편적인 지식 수준을 벗어나 저자와 다른 많은 MySQL 전문가의 ...');

mysql> SELECT COUNT(*) FROM tb_bi_gram
       WHERE MATCH(title, body) AGAINST ('단편' IN BOOLEAN MODE);
+----------+
| COUNT(*) |
+----------+
|        1 |
+----------+

mysql> SELECT COUNT(*) FROM tb_bi_gram
       WHERE MATCH(title, body) AGAINST ('이' IN BOOLEAN MODE);
+----------+
| COUNT(*) |
+----------+
|        0 |
+----------+
```

- 검색어 길이가 `ngram_token_size`보다 작은 경우 검색 불가능
- 검색어 길이가 `ngram_token_size`보다 큰 경우 검색 가능

<br>

전문 검색 쿼리가 오면 인덱싱할 때와 동일하게 검색어를 `ngram_token_size` 시스템 변수값에 맞게 분리  
이후 분리된 토큰들을 전문 검색 인덱스를 이용해 동등 비교 조건으로 검색  

<br>

## 전문 검색 쿼리 모드
전문 검색 쿼리는 자연어(`NATURAL LANGUAGE`) 검색 모드와 불리언(`BOOLEAN`) 검색 모드 지원  
자연어 검색 모드와 함께 사용할 수 있는 검색어 확장(`Query Expansion`) 기능도 지원  

<br>

### 자연어 검색(NATURAL LANGUAGE MODE)
```sql
TRUNCATE TABLE tb_bi_gram;
INSERT INTO tb_bi_gram VALUES
  (NULL, 'Oracle', 'Oracle is database'),
  (NULL, 'MySQL', 'MySQL is database'),
  (NULL, 'MySQL article', 'MySQL is best open source dbms'),
  (NULL, 'Oracle article', 'Oracle is best commercial dbms'),
  (NULL, 'MySQL Manual', 'MySQL manual is true guide for MySQL');
```

<br>

자연어 검색은 검색어에 제시된 단어를 많이 가지고 있는 순서대로 정렬  

```
mysql> SELECT id, title, body,
         MATCH(title, body) AGAINST ('MySQL' IN NATURAL LANGUAGE MODE) AS score
       FROM tb_bi_gram
       WHERE MATCH(title, body) AGAINST ('MySQL' IN NATURAL LANGUAGE MODE);
+----+---------------+--------------------------------------+--------------------+
| id | title         | body                                 | score              |
+----+---------------+--------------------------------------+--------------------+
|  5 | MySQL Manual  | MySQL manual is true guide for MySQL | 0.5906023979187012 |
|  2 | MySQL         | MySQL is database                    | 0.3937349319458008 |
|  3 | MySQL article | MySQL is best open source dbms       | 0.3937349319458008 |
+----+---------------+--------------------------------------+--------------------+
```

<br>

전문 검색 쿼리 검섹어에 자연어 문장 사용 가능(`Phrase Search`)  
검색어를 구분자로 분리하고 토큰 생성  
즉, 검색어에 사용된 모든 단어가 포함된 레코드뿐만 아니라 일부만 포함하는 결과도 출력  

```
mysql> SELECT id, title, body,
         MATCH(title, body) AGAINST ('MySQL manual is true guide' IN NATURAL LANGUAGE MODE) AS score
       FROM tb_bi_gram
       WHERE MATCH(title, body) AGAINST ('MySQL manual is true guide' IN NATURAL LANGUAGE MODE);
+----+---------------+--------------------------------------+--------------------+
| id | title         | body                                 | score              |
+----+---------------+--------------------------------------+--------------------+
|  5 | MySQL Manual  | MySQL manual is true guide for MySQL |    3.5219566822052 |
|  2 | MySQL         | MySQL is database                    | 0.3937349319458008 |
|  3 | MySQL article | MySQL is best open source dbms       | 0.3937349319458008 |
+----+---------------+--------------------------------------+--------------------+
```

<br>

### 불리언 검색(BOOLEAN MODE)
쿼리에 사용되는 검색어의 존재 여부에 대해 논리적 연산 가능  
`+` 표시를 가진 검색 단어는 존재해야하며, `-` 표시를 가진 검색 단어는 포함하지 않아야함  
불리언 연산자가 전혀 없는 경우 검색어에 포함된 단어 중 아무거나 하나라도 있으면 일치하는 것으로 판단  

```
mysql> SELECT id, title, body,
         MATCH(title, body) AGAINST ('+MySQL -manual' IN BOOLEAN MODE) AS score
       FROM tb_bi_gram
       WHERE MATCH(title, body) AGAINST ('+MySQL -manual' IN BOOLEAN MODE);
+----+---------------+--------------------------------+--------------------+
| id | title         | body                           | score              |
+----+---------------+--------------------------------+--------------------+
|  2 | MySQL         | MySQL is database              | 0.3937349319458008 |
|  3 | MySQL article | MySQL is best open source dbms | 0.3937349319458008 |
+----+---------------+--------------------------------+--------------------+

mysql> SELECT id, title, body,
         MATCH(title, body) AGAINST ('+MySQL +manual' IN BOOLEAN MODE) AS score
       FROM tb_bi_gram
       WHERE MATCH(title, body) AGAINST ('+MySQL +manual' IN BOOLEAN MODE);
+----+--------------+--------------------------------------+-------------------+
| id | title        | body                                 | score             |
+----+--------------+--------------------------------------+-------------------+
|  5 | MySQL Manual | MySQL manual is true guide for MySQL | 0.906023979187012 |
+----+--------------+--------------------------------------+-------------------+
```

<br>

쌍따옴표로 묶인 구는 마치 하나의 단어처럼 취급  
여기서 쌍따옴표로 묶인 구와 정확히 일치하는 것이 아닌 단어의 연결성으로 판단  

```
mysql> SELECT id, title, body,
         MATCH(title, body) AGAINST ('+"MySQL man"' IN BOOLEAN MODE) AS score
       FROM tb_bi_gram
       WHERE MATCH(title, body) AGAINST ('+"MySQL man"' IN BOOLEAN MODE);
+----+--------------+--------------------------------------+--------------------+
| id | title        | body                                 | score              |
+----+--------------+--------------------------------------+--------------------+
|  5 | MySQL Manual | MySQL manual is true guide for MySQL | 0.5906023979187012 |
+----+--------------+--------------------------------------+--------------------+
```

<br>

와일드카드 문자를 이용한 패턴 검색 적용 가능  
하지만 불리언 검색에서는 와일드카드가 아무런 효과를 가지지 않음  

```
mysql> SELECT id, title, body,
         MATCH(title, body) AGAINST ('sour*' IN BOLLEAN MODE) AS score
       FROM tb_bi_gram
       WHERE MATCH(title, body) AGAINST ('sour*' IN BOOLEAN MODE);
+----+---------------+--------------------------------+-------------------+
| id | title         | body                           | score             |
+----+---------------+--------------------------------+-------------------+
|  3 | MySQL article | MySQL is best open source dbms | 1.465677261352539 |
+----+---------------+--------------------------------+-------------------+
```

<br>

### 검색어 확장(QUERY EXPANSION)
쿼리에 사용한 검색어로 검색된 결과에서 공통으로 발견되는 단어들을 모아서 재검색 수행  
즉 검색 결과를 한번더 검색해서 결과를 만들때 사용  
`Blind query expansion` 알고리즘 사용  

```
mysql> SELECT * FROm tb_bi_gram
       WHERE MATCH(title, body) AGAINST ('database');
+----+--------+--------------------+
| id | title  | body               |
+----+--------+--------------------+
|  2 | Oracle | Oracle is database |
|  3 | MySQL  | MySQL is database  |
+----+--------+--------------------+

mysql> SELECT * FROM tb_bi_gram
       WHERE MATCH(title, body) AGAINST ('database' WITH EXPANSION);
+----+----------------+--------------------------------+
| id | title          | body                           |
+----+----------------+--------------------------------+
|  3 | MySQL          | MySQL is database              |
|  4 | MySQL article  | MySQL is best open source dbms |
|  2 | Oracle         | Oracle is database             |
|  5 | Oracle article | Oracle is best commercial dbms |
+----+----------------+--------------------------------+
```

<br>

## 전문 검색 인덱스 디버깅
여러 다양한 이유로 전문 검색 쿼리가 원하는 결과를 만들어내지 못하는 경우 발생  
전문 검색 쿼리 오류의 원인을 찾기 쉽게 전문 검색 인덱스 디버깅 기능 제공  
`innodb_ft_aux_table` 시스템 변수에 전문 검색 인덱스를 가진 테이블을 설정한 경우 해당 인덱스 관리 정보 조회 가능  

```sql
SET GLOBAL innodb_ft_aux_table = 'test/tb_bi_gram';
```

<br>

```
-- // 전문 검색 인덱스의 설정 내용 조회
mysql> SELECT * FROM information_schema.innodb_ft_config;
+---------------------------+-------+
| KEY                       | VALUE |
+---------------------------+-------+
| optimize_checkpoint_limit | 180   |
| synced_doc_id             | 7     |
| stopword_table_name       |       |
| use_stopword              | 1     |
+---------------------------+-------+

-- // 보유한 인덱스 엔트리 목록 조회
mysql> SELECT * FROM information_schema.innodb_ft_index_table;
+------+--------------+-------------+-----------+--------+----------+
| WORD | FIRST_DOC_ID | LAST_DOC_ID | DOC_COUNT | DOC_ID | POSITION |
+------+--------------+-------------+-----------+--------+----------+
| bm   |            4 |           5 |         2 |      4 |       41 |
| bm   |            4 |           5 |         2 |      5 |       42 |
| ce   |            4 |           5 |         2 |      4 |       37 |
| ce   |            4 |           5 |         2 |      5 |       19 |
| cl   |            2 |           5 |         3 |      2 |        3 |
| cl   |            2 |           5 |         3 |      2 |        7 |
| ...  |          ... |         ... |       ... |    ... |      ... |
+------+--------------+-------------+-----------+--------+----------+

-- // 기본적으로 레코드가 새롭게 삽입시 토큰을 즉시 저장하지 않고 메모리에 임시 저장
mysql> INSERT INTO tb_bi_gram VALUES (NULL, 'Oracle', 'Oracle is database');
mysql> SELECT * FROM information_schema.innodb_ft_index_cache;
+------+--------------+-------------+-----------+--------+----------+
| WORD | FIRST_DOC_ID | LAST_DOC_ID | DOC_COUNT | DOC_ID | POSITION |
+------+--------------+-------------+-----------+--------+----------+
| cl   |            8 |           8 |         1 |      8 |        3 |
| cl   |            8 |           8 |         1 |      8 |        7 |
| le   |            8 |           8 |         1 |      8 |        4 |
| le   |            8 |           8 |         1 |      8 |        7 |
| se   |            8 |           8 |         1 |      8 |       23 |
+------+--------------+-------------+-----------+--------+----------+

-- // 레코드 삭제시 삭제되는 레코드 정보 조회
mysql> DELETE FROM tb_bi_gram where id = 1;
mysql> SELECT * FROM information_schema.innodb_ft_deleted;
+--------+
| DOC_ID |
+--------+
|      2 |
+--------+
```

<br>
