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

### MySQL 엔진의 잠금
잠금은 스토리지 엔진 레벨과 MySQL 엔진 레벨로 분류  
MySQL 엔진에서는 테이블 데이터 동기화를 위한 테이블 락, 테이블 구조를 잠그는 메타데이터 락, 사용자 필요에 맞는 네임드 락으로 분류  

<br>

### 글로벌 락
MySQL 내에서 가장 범위가 큰 잠금  
MySQL 내에 존재하는 모든 테이블을 닫고 잠금  
`FLUSH TABLES WITH READ LOCK` 명령으로 획득 가능  
한 세션에서 글로벌 락을 획득한 경우 다른 세션은 SELECT 쿼리 외에는 대기  
`mysqldump`로 일관된 백업을 할때 글로벌 락 사용  
8.0 버전부터 조금은 가벼운 백업 락 도입  

```sql
LOCK INSTANCE FOR BACKUP;
## 백업 실행
UNLOCK INSTANCE;
```

<br>

특정 세션에서 백업 락을 획득한 경우 모든 세션에서 아래와 같이 테이블 스키마 및 사용자 인증 정보 수정 불가  
- 데이터베이스 및 테이블 등 모든 객체 생성/변경/삭제
- REPAIR TABLE과 OPTIMIZE TABLE 명령
- 사용자 관리 및 비밀번호

<br>

하지만 백업 락은 일반적인 테이블 데이터 변경은 허용  
일반적으로 서버는 소스 서버와 레플리카 서버로 구성, 그중 레플리카 서버에서 백업이 실행  

<br>

### 테이블 락
개별 테이블 단위로 설정되는 잠금  
`LOCK TABLES table_name [ READ | WRITE ]` 명령으로 획득 가능  
명시적인 테이블 락도 특별한 상황이 아니면 사용할 필요 없음  

묵시적인 테이블 락은 MyISAM이나 MEMORY 테이블에 데이터를 변경하는 쿼리를 실행한 경우 발생  
InnoDB 테이블은 스토리지 엔진 차원에서 레코드 기반 잠금을 제공  
InnoDB 테이블 락은 대부분의 데이터 변경(DML) 쿼리에서는 무시되지만 스키마 변경 쿼리(DDL)에만 영향  

<br>

### 네임드 락
`GET LOCK()` 함수를 이용해 임의의 문자열에 대한 잠금 설정  
대상이 테이블이나 레코드 같은 데이터베이스 객체가 아님  
단순히 사용자가 지정한 문자열에 대해 획득하고 반납하는 잠금  

```sql
## "mylock"이라는 문자열에 대해 잠금 획득
## 이미 잠금을 사용중이라면 2초 동안만 대기(2초 이후 자동 잠금 해제)
SELECT GET_LOCK('mylock', 2);

## "mylock"이라는 문자열에 대해 잠금이 설정돼 있는지 확인
SELECT IS_FREE_LOCK('mylock');

## "mylock"이라는 문자열에 대해 획득했던 잠금 반납
SELECT RELEASE_LOCK('mylock');
```

<br>

네임드 락의 경우 많은 레코드에 복잡한 요건으로 레코드를 변경하는 트랜잭션에 유용  
8.0 버전부터 네임드 락 중첩 및 모두 해제 기능 추가  

```sql
SELECT GET_LCOK('mylock_1', 10);
SELECT GET_LOCK('mylock_2', 10);

## 네임드 락 개별 해제
SELECT RELEASE_LOCK('mylock_2');
SELECT RELEASE_LOCK('mylock_1');

## 획득한 모든 네임드 락 해제
SELECT RELEASE_ALL_LOCKS();
```

<br>

### 메타데이터 락













