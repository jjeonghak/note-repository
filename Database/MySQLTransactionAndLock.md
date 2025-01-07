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

## MySQL 엔진의 잠금
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
데이터베이스 객체의 이름이나 구조를 변경하는 경우에 획득하는 잠금  
명시적으로 획득/해제 불가, `RENAME TABLE tab_a TO tab_b` 같은 변경 명령에 의해 자동 획득  

```sql
## 백업 및 새로운 테이블을 서비스용으로 대체하는 경우
RENAME TABLE rank TO tank_backup, tank_new TO tank;

## 2개 쿼리로 분리하면 짧은 순간 rank 테이블이 존재하지 않는 순간 발생
RENAME TABLE rank TO rank_backup;
RENAME TABLE rank_new TO rank;
```

<br>

## InnoDB 스토리지 엔진의 잠금
MySQL에서 제공하는 잠금과는 별개로 스토리지 엔진 내부에서 레코드 기반 잠금 방식 탑재  
하지만 이원화된 잠금 처리로 인해 MySQL 명령을 이용한 접근이 어려움  
`information_schema` 데이터베이스의 `INNODB_TRX`, `INNODB_LOCKS`, `INNODB_LCOK_WAITS` 테이블을 조인해서 현황 확인  

<br>

### InnoDB 스토리지 엔진의 잠금
레코드 기반 잠금 정보는 상당히 작은 공간으로 관리  
레코드 락이 페이지 락 또는 테이블 락으로 락 에스컬레이션되지 않음  
레코드 락뿐만 아니라 레코드와 레코드 사이 간격을 잠그는 갭(`GAP`) 락도 존재  

<br>

### 레코드 락
레코드 자체만을 잠그는 것(record lock, record only lock)  
하지만 InnoDB 스토리지 엔진은 인덱스의 레코드를 잠금  
인덱스가 하나도 없더라도 클러스터링 인덱스를 이용해 잠금 설정  

<br>

### 갭 락
레코드 자체가 아닌 레코드와 바로 인접한 레코드 사이의 간격만을 잠금  
레코드와 레코드 사이의 간격에 새로운 레코드가 생성되는 것을 제어  

<br>

### 넥스트 키 락
레코드 락과 갭 락을 합쳐 놓은 형태  
`STATEMENT` 포맷의 바이너리 로그를 사용하는 서버에서는 `REPEATABLE READ` 격리 수준 사용  
`innodb_locks_unsafe_for_binlog` 시스템 변수값이 비활성화된 상태라면 변경을 위해 검색하는 레코드에는 넥스트 키 락 방식으로 잠금  
바이너리 로그에 기록된 쿼리가 레플리카 서버에서 실행될 때 소스 서버 결과와 동일한 결과를 만들어내도록 보장  
하지만 데드락이 발생하는 경우가 많아 ROW 형태의 바이너리 로그 포맷 권장  

<br>

### 자동 증가 락
자동 증가하는 숫자 값을 추출하기 위해 `AUTO_INCREMENT` 칼럼 속성 제공  
이를 위해 내부적으로 AUTO_INCREMENT 락이라는 테이블 수준 잠금 사용  
새로운 값이 추가되는 INSERT, REPLACE 쿼리 문장에만 필요  
해당 락을 명시적으로 획득하고 해제하는 방법은 없음  
- `innodb_autoinc_lock_mode`=0  
  5.0 버전과 동일한 잠금 방식으로 모든 INSERT 문장은 자동 증가 락 사용  
  
- `innodb_autoinc_lock_mode`=1  
  서버가 INSERT되는 레코드 건수를 정확히 예측 가능한 경우 자동 증가 락 사용 안함  
  훨씬 가볍고 빠른 래치(뮤텍스) 사용
  최소한 하나의 INSERT 문장으로 생성되는 레코드는 연속된 자동 증가 값 보장  
  해당 모드를 연속 모드(`consecutive mode`)라고 표현  

- `innodb_autoinc_lock_mode`=2  
  절대 자동 증가 락을 사용하지 않고 래치(뮤텍스) 사용  
  하나의 INSERT 문장으로 생성되는 레코드라도 연속된 자동 증가 값을 보장하지 않음  
  해당 모드를 인터리빙 모드(`interleaved mode`)라고 표현  

5.7 버전까지는 기본값이 1이었지만, 8.0 버전부터는 기본값이 2로 변경  
8.0 버전부터 ROW 포맷이 기본값이기 때문  

<br>

### 인덱스와 잠금
InnoDB 잠금은 레코드를 잠그는 것이 아닌 인덱스를 잠그는 방식  
변경해야 할 레코드를 찾기 위해 검색한 인덱스의 모든 레코드를 모두 잠금  
만약 이 테이블에 인덱스가 하나도 없다면 테이블 풀스캔을 하면서 모든 레코드를 잠금  

<br>

<img width="550" alt="indexLock" src="https://github.com/user-attachments/assets/00a55218-d4d8-438b-8e1b-d0a1160e890c" />

<br>

```
## first_name 칼럼에 ix_firstname 인덱스 존재
mysql> SELECT COUNT(*) FROM employees WHERE first_name='Georgi';
+-------+
| count |
+-------+
|   253 |
+-------+

mysql> SELECT COUNT(*) FROM employees WHERE first_name='Georgi' AND last_name='Klassen';
+-------+
| count |
+-------+
|     1 |
+-------+

## 253건의 레코드가 모두 잠김
mysql> UPDATE employees SET hire_date=NOW() WHERE first_name='Georgi' AND last_name='Klassen';
```

<br>

### 레코드 수준의 잠금 확인 및 해제
InnoDB 스토리지 엔진은 레코드 수준 잠금은 테이블 수준 잠금보다 복잡  
테이블 잠금은 대상이 테이블이므로 쉽게 문제 원인 분석 가능  
하지만 레코드 잠금은 자주 사용되지 않는다면 오랜 시간 동안 잠겨진 상태로 발견되지 않음  
5.1 버전부터 레코드 잠금과 잠금 대기에 대한 조회가 가능  


`information_schema` 정보들은 조금씩 제거(deprecatred)  
그 대신 `performance_schema` 데이터베이스의 `data_locks`, `data_lock_waits` 테이블로 대체  

<br>

```
mysql> SHOW PROCESSLIST;
+----+------+----------+-----------------------------------------------------------+
| Id | Time | State    | Info                                                      |
+----+------+----------+-----------------------------------------------------------+
| 17 |  607 |          | NULL                                                      |
| 18 |   22 | updating | UPDATE employees SET birth_date=NOW() WHERE emp_no=100001 |
| 19 |   21 | updating | UPDATE employees SET birth_date=NOW() WHERE emp_no=100001 |
+----+------+----------+-----------------------------------------------------------+

mysql> SELECT
          r.trx_id waiting_trx_id,
          r.trx_mysql_thread_id waiting_thread,
          r.trx_query waiting_query,
          b.trx_id blocking_trx_id,
          b.trx_mysql_thread_id blocking_thread,
          b.trx_query blocking_query,
        FROM performance_schema.data_lock_waits w
        INNER JOIN information_schema.innodb_trx b
          ON b.trx_id = w.blocking_engine_transaction_id
        INNERT JOIN information_schema.innodb_trx r
          ON r.trx_id = w.requesting_engine_transaction_id;

+---------+---------+--------------------+----------+----------+--------------------+
| waiting | waiting | waiting_query      | blocking | blocking | blocking_query     |
| _trx_id | _thread |                    |  _trx_id |  _thread |                    |
+---------+---------+--------------------+----------+----------+--------------------+
|   11990 |      19 | UPDATE employees.. |    11989 |       18 | UPDATE employees.. |
|   11990 |      19 | UPDATE employees.. |    11984 |       17 | NULL               |
|   11989 |      18 | UPDATE employees.. |    11984 |       17 | NULL               |
+---------+---------+--------------------+----------+----------+--------------------+
```

대기 중인 스레드는 18, 19번 스레드  
18번 스레드는 17번 스레드를, 19번 스레드는 17번과 18번 스레드를 대기  

<br>

```
mysql> SELECT * FROM performance_schema.data_locks\G
*************************** 1. row ***************************
               ENGINE: INNODB
       ENGINE_LOCK_ID: 4828335432:1157:140695376728800
ENFINE_TRANSACTION_ID: 11984
            THREAD_ID: 61
             EVENT_ID: 16028
        OBJECT_SCHEMA: employees
          OBJECT_NAME: employees
       PARTITION_NAME: NULL
    SUBPARTITION_NAME: NULL
           INDEX_NAME: NULL
OBJECT_INSTANCE_BEGIN: 140695376728800
            LOCK_TYPE: TABLE
            LOCK_MODE: IX
          LOCK_STATUS: GRANTED
            LOCK_DATA: NULL
*************************** 2. row ***************************
               ENGINE: INNODB
       ENGINE_LOCK_ID: 4828335432:8:298:25:140695394434080
ENFINE_TRANSACTION_ID: 11984
            THREAD_ID: 61
             EVENT_ID: 16048
        OBJECT_SCHEMA: employees
          OBJECT_NAME: employees
       PARTITION_NAME: NULL
    SUBPARTITION_NAME: NULL
           INDEX_NAME: PRIMARY
OBJECT_INSTANCE_BEGIN: 140695394434080
            LOCK_TYPE: RECORD
            LOCK_MODE: X,REC_NOT_GAP
          LOCK_STATUS: GRANTED
            LOCK_DATA: 100001
```

employees 테이블에 대한 `IX 잠금`(intentional exclusive)을 보유  
특정 레코드에 대해서 쓰기 잠금  
`REC_NOT_GAP` 표시는 갭이 포함되지 않은 순수 레코드 잠금  

<br>

## MySQL의 격리 수준
여러 트랜잭션이 동시에 처리될 때 특정 트랜잭션이 다른 트랜잭션의 변경 사항을 조회 가능한지 결정하는 것  

| | **DIRTY READ** | **NON-REPEATABLE READ** | **PHANTOM READ** |
|--|--|--|--|
| READ UNCOMMITTED | 발생 | 발생 | 발생 |
| READ COMMITTED | 없음 | 발생 | 발생 |
| REPEATABLE READ | 없음 | 없음 | 발생(InnoDB는 없음) |
| SERIALIZABLE | 없음 | 없음 | 없음 |

<br>

### READ UNCOMMITTED

<img width="550" alt="readuncommitted" src="https://github.com/user-attachments/assets/be5bd78c-4205-4dd3-9ca7-06dff6102584" />

<br>

어떤 트랜잭션에서 처리한 작업이 완료되지 않아도, 다른 트랜잭션에서 변경 사항 조회 가능  
해당 현상을 더티 리드(`dirty read`)라고 표현  
트랜잭션 격리 수준으로 인정하지 않을 정도로 정합성 문제 발생  

<br>

### READ COMMITTED

<img width="550" alt="readcommitted" src="https://github.com/user-attachments/assets/ac8b8134-680f-481d-b22b-9d0d1c5f6517" />

<br>

어떤 트랜잭션의 변경 사항이 아닌 언두 영역에 백업된 레코드를 조회  
하지만 `NON-REPEATABLE READ` 부정합 문제 발생  

<br>

<img width="550" alt="readcommittednonrepeatableread" src="https://github.com/user-attachments/assets/254d6ded-bf53-4c94-9ad0-2e65e0936d89" />

<br>

하나의 트랜잭션 내에서 똑같은 조회 쿼리를 실행한 경우 항상 동일한 결과를 가져와야 `REPEATABLE READ` 정합성  
이런 부정합 현상은 일반적인 웹 프로그램에서 크게 문제되지 않을 수 있지만 금전적인 처리와 연결되면 문제 발생  
해당 격리 수준에서는 트랜잭션 내부 조회 쿼리와 외부 조회 쿼리의 차이가 없음  

<br>

### REPEATABLE READ

<img width="550" alt="repeatableread" src="https://github.com/user-attachments/assets/a54d34bf-fdd8-4c04-a78e-1fda0007d6ee" />

<br>

MySQL의 InnoDB 스토리지 엔진에서 기본으로 사용되는 격리 수준  
`NON-REPEATABLE READ` 부정합 문제 발생하지 않음  
언두 로그를 활용한 MVCC 방식을 활용해서 보장  
READ COMMITTED 격리 수준도 MVCC 방식으로 언두 로그를 활용하지만, 어느 버전까지 탐색하느냐의 차이 존재  
모든 InnoDB 트랜잭션은 고유한 번호를 가지며, 언두 영역의 레코드에는 변경을 발생시킨 트랜잭션 번호가 포함  

<br>

<img width="550" alt="phantomread" src="https://github.com/user-attachments/assets/a9fd20e2-6200-4f86-ad8e-5817a8abb20c" />

<br>

다른 트랜잭션에서 수행한 변경 잡업에 의해 레코드가 조회되었다가 다시 조회되지 않는 현상을 `PHANTOM READ`  
`SELECT ... FOR UPDATE` 쿼리 또는 `SELECT ... LOCK IN SHARE MODE` 쿼리는 레코드에 쓰기 잠금 필수  
언두 레코드에는 잠금 불가하기 때문에 언두 레코드가 아닌 현재 레코드 값을 조회  
하지만 InnoDB 스토리지 엔진에서는 갭 락과 넥스트 키 락 덕분에 `PHANTOM READ` 발생하지 않음  

<br>

### SERIALIZABLE
가장 단순하고 엄격한 격리 수준, 동시 처리 성능이 굉장히 떨어짐  
읽기 작업도 잠금을 획득해야 가능해서 `Non-locking consistent read` 불가능  

<br>
