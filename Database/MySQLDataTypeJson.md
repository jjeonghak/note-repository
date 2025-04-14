# 데이터 타입
칼럼의 데이터 타입과 길이를 선정할 때 아래 사항을 주의  
- 저장되는 값의 성격에 맞는 최적의 타입 선정
- 가변 길이 칼럼은 최적의 길이를 지정
- 조인 조건으로 사용되는 칼럼은 똑같은 데이터 타입으로 선정

<br>

## JSON 타입
TEXT 칼럼이나 BLOB 칼럼에 `JSON` 저장 가능  
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































