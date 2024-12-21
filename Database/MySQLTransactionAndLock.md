# 트랜잭션과 잠금

트랜잭션은 작업의 완전성과 데이터의 정합성을 보장  
`partial update` 현상 방지  

잠금은 트랜잭션과 비슷한 개념같지만 동시성을 제어하기 위한 기능  
여러 커넥션에서 동시에 동일한 자원을 요청한 경우 하나의 커넥션만 사용하도록 보장  

<br>

## 트랜잭션

### MySQL에서의 트랜잭션
꼭 여러개의 변경 작업을 수행하는 쿼리가 조합된 경우에만 의미 있는 개념은 아님  

```sql
CREATE TABLE tab_myisam ( fdpk INT NOT NULL, PRIMARY KEY (fdpk) ) ENGINE=MyISAM;
INSERT INTO tab_myisam (fdpk) VALUES (3);

CREATE TABLE tab_innodb ( fdpk INT NOT NULL, PRIMARY KEY (fdpk) ) ENGINE=INNODB;
INSERT INTO tab_innodb (fdpk) VALUES (3);

SET autocommit=ON;
```

<br>

트랜잭션 유무에 따라 두 스토리지 엔진은 결과 차이 존재  

```
mysql> INSERT INTO tab_myisam (fdpk) VALUES (1), (2), (3);
ERROR 1062 (23000): Duplicate entry '3' for key 'PRIMARY'

mysql> INSERT INTO tab_innodb (fdpk) VALUES (1), (2), (3);
ERROR 1062 (23000): Duplicate entry '3' for key 'PRIMARY'

mysql> SELECT * FROM tab_myisam;
+------+
| fdpk |
+------+
|    1 |
|    2 |
|    3 |
+------+

mysql> SELECT * FROM tab_innodb;
+------+
| fdpk |
+------+
|    3 |
+------+
```

<br>

### 주의사항
트랜잭션 또한 DBMS 커넥션과 동일하게 꼭 필요한 최소의 코드에만 적용  





















