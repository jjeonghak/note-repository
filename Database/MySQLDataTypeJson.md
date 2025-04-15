# 데이터 타입
칼럼의 데이터 타입과 길이를 선정할 때 아래 사항을 주의  
- 저장되는 값의 성격에 맞는 최적의 타입 선정
- 가변 길이 칼럼은 최적의 길이를 지정
- 조인 조건으로 사용되는 칼럼은 똑같은 데이터 타입으로 선정

<br>

## JSON 타입
TEXT 칼럼이나 BLOB 칼럼에 JSON 저장 가능  
문자열로 저장하는 것이 아닌 바이너리 포맷의 `BSON(Binary JSON)`으로 변환해서 저장  

<br>

### 저장 방식
MySQL 서버는 내부적으로 `BLOB` 타입에 `BSON` 타입으로 변환해서 저장  

```
mysql> CREATE TABLE tb_json (id INT, fd JSON);
mysql> INSERT INTO tb_json VALUES (1, '{"user_id":1234567890}'), (2, '{"user_id":"1234567890"}');
mysql> SELECT id, fd,
         JSON_TYPE(fd->"$.user_id") AS field_type,
         JSON_STORAGE_SIZE(fd) AS byte_size
       FROM tb_json;
+----+--------------------------+------------+-----------+
| id | fd                       | field_type | byte_size |
+----+--------------------------+------------+-----------+
|  1 | {"user_id":1234567890}   |    INTEGER |        23 |
|  2 | {"user_id":"1234567890"} |     STRING |        30 |
+----+--------------------------+------------+-----------+
```

<br>

```
mysql> SELECT JSON_STORAGE_SIZE('{"a":"x", "b":"y", "c":"z"}') AS binary_length;
+---------------+
| binary_length |
+---------------+
|            35 |
+---------------+
```

| 필드 순서 | 바이트 수 | 주소(Offset) | 이진값 | 문자열 | 십진 숫자값 | 설명 |
|--|--|--|--|--|--|--|
| 1 | 1 |  | 00 |  | 0 | type(JSONB_TYPE_SMALL_OBJECT) |
| 2 | 2 | 0 | 03 00 |  | 3 | JSON 어트리뷰트 개수 |
| 3 | 2 | 2 | 22 00 |  | 34 | JSON 도큐멘트 길이(바이트 수) |
| 4 | 2 | 4 | 19 00 |  | 25 | 첫번째 키 주소(Offset) |
| 5 | 2 | 6 | 01 00 |  | 1 | 첫번쨰 키 길이(바이트 수) |
| 6 | 2 | 8 | 1A 00 |  | 26 | 두번쨰 키 주소(Offset) |
| 7 | 2 | 10 | 01 00 |  | 1 | 두번쨰 키 길이(바이트 수) |
| 8 | 2 | 12 | 1B 00 |  | 27 | 세번째 키 주소(Offset) |
| 9 | 2 | 14 | 01 00 |  | 1 | 세번째 키 길이(바이트 수) |
| 10 | 1 | 16 | 0C |  | 12 | 첫번째 값 타입(JSON_TYPE_STRING) |
| 11 | 2 | 17 | 1C 00 |  | 28 | 첫번째 값 주소(Offset) |
| 12 | 1 | 19 | 0C |  | 12 | 두번째 값 타입(JSON_TYPE_STRING) |
| 13 | 2 | 20 | 1E 00 |  | 30 | 두번째 값 주소(Offset) |
| 14 | 1 | 22 | 0C |  | 12 | 세번째 값 타입(JSON_TYPE_STRING) |
| 15 | 2 | 23 | 20 00 |  | 32 | 세번째 값 주소(Offset) |
| 16 | 1 | 25 | 61 | a |  | 첫번째 키 |
| 17 | 1 | 26 | 62 | b |  | 두번쨰 키 |
| 18 | 1 | 27 | 63 | c |  | 세번째 키 |
| 19 | 1 | 28 | 01 |  | 1 | 첫번쨰 값 길이(바이트 수) |
| 20 | 1 | 29 | 78 | x |  | 첫번쨰 값 |
| 21 | 1 | 30 | 01 |  | 1 | 두번쨰 값 길이(바이트 수) |
| 22 | 1 | 31 | 79 | y |  | 두번쨰 값 |
| 23 | 1 | 32 | 01 |  | 1 | 세번쨰 값 길이(바이트 수) |
| 24 | 1 | 33 | 7A | z |  | 세번째 값 |

이진값으로 표시된 항목이 실제 바이너리 필드값  
JSON 도큐먼트를 구성하는 모든 키의 위치와 키의 이름이 필드값보다 먼저 나열  
특정 필드만 참조하거나 특정 필드 값만 업데이트하는 경우 즉시 변경 가능  

<br>

### 부분 업데이트 성능
8.0 버전부터 JSON 타입에 대해 부분 업데이트(`Partial Update`) 기능을 제공  
`JSON_SET()`, `JSON_REPLACE()`, `JSON_REMOVE()` 함수를 이용해 특정 필드값을 변경하거나 삭제하는 경우에만 동작  

<br>

```
mysql> UPDATE tb_json SET fd = JSON_SET(fd, '$.user_id', "12345") WHERE id = 2;
mysql> SELECT id, fd, JSON_STORAGE_SIZE(fd), JSON_STORAGE_FREE(fd) FROM tb_json;
+----+-------------------------+-----------------------+-----------------------+
| id | fd                      | JSON_STORAGE_SIZE(fd) | JSON_STORAGE_FREE(fd) |
+----+-------------------------+-----------------------+-----------------------+
|  1 | {"user_id": 1234567890} |                    23 |                     0 |
|  2 | {"user_id": "12345"}    |                    30 |                     5 |
+----+-------------------------+-----------------------+-----------------------+

mysql> UPDATE tb_json SET fd = JSON_SET(fd, '$.user_id', "12345678901") WHERE id = 2;
mysql> SELECT id, fd, JSON_STORAGE_SIZE(fd), JSON_STORAGE_FREE(fd) FROM tb_json;
+----+----------------------------+-----------------------+-----------------------+
| id | fd                         | JSON_STORAGE_SIZE(fd) | JSON_STORAGE_FREE(fd) |
+----+----------------------------+-----------------------+-----------------------+
|  1 | {"user_id": 1234567890}    |                    23 |                     0 |
|  2 | {"user_id": "12345678901"} |                    31 |                     0 |
+----+----------------------------+-----------------------+-----------------------+
```

부분 업데이트로 처리됐는지 명확하게 아는 방법은 없음  
다만 필드의 값이 변경되고 저장공간에 사용되는 바이트와 사용되지 않은 바이트를 비교해서 예측 가능  
일반적으로 복제를 위해서 JSON 변경 내용을 바이너리 로그에 기록, 해당 작업은 여전히 데이터 모두를 기록  
`binlog_row_value_options`, `binlog_row_image` 시스템 변수값을 변경하면 부분 업데이트 성능을 빠르게 개선 가능  
해당 시스템 변수값 설정도 중요하지만 복제에 프라이머리 키 여부가 더 중요  

```
-- // ROW 또는 STATEMENT
mysql> SET binlog_format = ROW;
mysql> SET binlog_row_value_options = PARTIAL_JSON;
mysql> SET binlog_row_image = MINIMAL;

mysql> UPDATE tb_json SET fd = JSON_SET(fd, '$.name', "Matt Lee");
Query OK, 16 rows affected (2.30 sec)

mysql> UPDATE tb_json SET fd = JSON_SET(fd, '$.name', "Kit");
Query OK, 16 rows affected (0.18 sec)
```

<br>

### JSON 타입 콜레이션과 비교
JSON 칼럼에 저장되는 데이터와 가공되어 나온 결과값은 모두 `utf8mb4` 문자 집합과 `utf8mb4_bin` 콜레이션을 보유  
바이너리 콜레이션이기 때문에 대소문자 구분과 액센트 문자 등도 구분해서 비교  

```
mysql> SET @user1 = JSON_OBJECT('name', 'Matt');
mysql> SELECT CHARSET(@user1), COLLATION(@user1);
+-----------------+-------------------+
| CHARSET(@user1) | COLLATION(@user1) |
+-----------------+-------------------+
| utf8mb4         | utf8mb4_bin       |
+-----------------+-------------------+

mysql> SET @user2 = JSON_OBJECT('name', 'matt');
mysql> SELECT @user1 = @user2;
+-----------------+
| @user1 = @user2 |
+-----------------+
|               0 |
+-----------------+
```

<br>

### JSON 칼럼 선택
`BLOB`, `TEXT` 타입에 `JSON` 문자열을 저장하는 경우 아무런 변환 없이 입력된 값을 그대로 디스크에 저장  
이진 포맷으로 컴팩션해서 저장할 뿐만 아니라 부분 업데이트를 통한 빠른 변경 기능 제공  

```sql
CREATE TABLE tb_json (
  doc JSON NOT NULL,
  id BIGINT AS (doc->>'$.id') STORED NOT NULL,
  PRIMARY KEY(id)
);

CREATE TABLE tb_column (
  id BIGINT NOT NULL,
  name VARCHAR(50) NOT NULL,
  PRIMARY KEY(id)
);

INSERT INTO tb_json (doc) VALUES ('{"id":1, "name":"Matt"}'), ('{"id":2, "name":"Esther"}');
INSERT INTO tb_column VALUES (1, 'Matt'), (2, 'Esther');
```

<br>

JSON 칼럼은 각 레코드가 가지는 속성들이 너무 상이하고 다양하지만 선택적으로 값을 가지는 경우 유리  
속성들이 중요도와 검색 조건으로 사용될 가능성이 낮고 자주 접근하지 않는 경우 유리  

```
mysql> CREATE TABLE test (id INT NOT NULL PRIMARY KEY, value JSON);

mysql> SELECT id, value FROM test WHERE id = 1;
1 row in set (0.16 sec)

mysql> SELECT id FROM test WHERE id = 1;
1 row in set (0.01 sec)
```

<br>
