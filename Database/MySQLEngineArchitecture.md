# 아키텍처

머리를 담당하는 MySQL 엔진과 손발을 담당하는 스토리지 엔진으로 구분 가능  
스토리지 엔진은 핸들러 API를 만족하면 커스텀 스토리지 엔진 추가 사용 가능  

<br>

## MySQL 엔진 아키텍처

### MySQL의 전체 구조

<img width="550" alt="mysqlArchitecture" src="https://github.com/user-attachments/assets/86546ceb-f825-43c2-b726-536df13a62cf" />

대부분의 프로그래밍 언어로부터 접근 지원  
MySQL 엔진과 스토리지 엔진을 합처서 MySQL 서버로 표현  

<br>

### MySQL 엔진
커넥션 핸들러와 SQL 파서 및 전처리기, 쿼리 최적화 옵티마이저가 중심  
표준 SQL(ANSI SQL) 문법을 지원하기에 다른 DBMS와 호환 가능  
하나의 서버에는 하나의 MySQL 엔진 존재  

<br>

### 스토리지 엔진
SQL 문장을 분석하거나 최적화  
실제 데이터를 디스크 스토리지에 저장/조회를 전잠  
여러 스토리지 엔진을 동시에 사용 가능  
각 테이블마다 담당 스토리지 엔진을 설정 가능  
각 스토리지 엔진은 성능 향상을 위한 기능 내장(MyISAM 키 캐시, InnoDB 버퍼 풀)

```sql
CREATE TABLE test_table (fd1 INT, fd2 INT) ENGINE=INNODB;
```

<br>

### 핸들러 API
스토리지 엔진에 쓰기/읽기 요청하는 것을 핸들러 요청이라고 칭함  

```
mysql> SHOW GLOBAL STATUS LIKE 'Handler%';
+----------------------------+-------+
| Variable_name              | Value |
+----------------------------+-------+
| Handler_commit             | 2696  |
| Handler_delete             | 184   |
| Handler_discover           | 0     |
| Handler_external_lock      | 15589 |
| Handler_mrr_init           | 0     |
| Handler_prepare            | 326   |
| Handler_read_first         | 67    |
| Handler_read_key           | 7731  |
| Handler_read_last          | 10    |
| Handler_read_next          | 8394  |
| Handler_read_prev          | 0     |
| Handler_read_rnd           | 0     |
| Handler_read_rnd_next      | 13676 |
| Handler_rollback           | 1     |
| Handler_savepoint          | 0     |
| Handler_savepoint_rollback | 0     |
| Handler_update             | 352   |
| Handler_write              | 840   |
+----------------------------+-------+
18 rows in set (0.02 sec)
```

<br>

### MySQL 스레딩 구조

<img width="550" alt="mysqlThreading" src="https://github.com/user-attachments/assets/df0daf63-9af3-47c6-8df1-6abc3a22c97d" />

서버는 프로세스 기반이 아닌 스레드 기반으로 작동  
포그라운드 스레드(Foreground)와 백그라운드(Background) 스레드로 구분  
실행 중인 스레드 목록은 `performance_schema` 데이터베이스의 `threads` 테이블을 통해 확인 가능  

<br>

```
mysql> SELECT thread_id, name, type, processlist_user, processlist_host
        FROM performance_schema.threads
        ORDER BY type, thread_id;
+-----------+------------------------------------+------------+------------------+------------------+
| thread_id | name                               | type       | processlist_user | processlist_host |
+-----------+------------------------------------+------------+------------------+------------------+
|         1 | thread/sql/main                    | BACKGROUND | NULL             | NULL             |
|         2 | thread/mysys/thread_timer_notifier | BACKGROUND | NULL             | NULL             |
|         4 | thread/innodb/io_ibuf_thread       | BACKGROUND | NULL             | NULL             |
|         5 | thread/innodb/io_log_thread        | BACKGROUND | NULL             | NULL             |
|         6 | thread/innodb/io_read_thread       | BACKGROUND | NULL             | NULL             |
|         7 | thread/innodb/io_read_thread       | BACKGROUND | NULL             | NULL             |
|         8 | thread/innodb/io_read_thread       | BACKGROUND | NULL             | NULL             |
|         9 | thread/innodb/io_read_thread       | BACKGROUND | NULL             | NULL             |
|        10 | thread/innodb/io_write_thread      | BACKGROUND | NULL             | NULL             |
|        11 | thread/innodb/io_write_thread      | BACKGROUND | NULL             | NULL             |
|       ... | ...                                | ...        | ...              | ...              |
|        56 | thread/sql/one_connection          | FOREGROUND | root             | localhost        |
+-----------+------------------------------------+------------+------------------+------------------+
```

이 중 마지막 `thread/sql/one_connection` 스레드만 실제 사용자 요청을 처리하는 포그라운드 스레드  
백그라운드 스레드의 개수는 서버 설정 내용에 따라 가변적  
동일한 이름의 스레드는 여러 스레드가 동일 작업을 병렬로 처리하는 경우  

<br>

### 포그라운드 스레드(클라이언트 스레드)
포그라운드 스레드는 접속된 클라이언트 수만큼 존재  
주로 각 클라이언트 사용자가 요청하는 쿼리 문장을 처리  
커넥션이 종료되면 해당 스레드는 다시 스레드 캐시에 보관  
이때 이미 스레드 캐시에 일정 갯수 이상의 스레드가 대기중인 경우 스레드 종료  
스레드 캐시에 유지할 수 있는 최대 스레드 갯수 `thread_cache_size`  

<br>

### 백그라운드 스레드
MyISAM 해당 사항 없음  
- 인서트 버퍼(Insert Buffer)를 병합하는 스레드
- 로그를 디스크로 기록하는 스레드
- InnoDB 버퍼 풀의 데이터를 디스크에 기록하는 스레드  
- 데이터를 버퍼로 읽어 오는 스레드
- 잠금이나 데드락을 모니터링하는 스레드  

모두 중요하지만 그중 `로그 스레드`와 `쓰기 스레드`가 가장 중요  
`innodb_read_io_threads`, `innodb_write_io_threads` 시스템 변수값으로 읽기/쓰기 스레드 갯수 설정  
읽기 작업은 주로 클라이언트 스레드에 의해 처리되기 때문에 많이 설정할 필요 없음  
쓰기는 일반적으로 내장 디스크를 사용할때는 2 ~ 4 정도  
사용자 요청 처리중 쓰기 작업은 지연 가능하지만 읽기 작업은 절대 지연 불가  
MyISAM 경우 일반적인 쿼리는 쓰기 지연 기능 사용 불가  

<br>

### 메모리 할당 및 사용 구조

<img width="500" alt="mysqlMemory" src="https://github.com/user-attachments/assets/f8309784-493a-4f15-8648-836cf54400c9" />

메모리 공간은 글로벌 메모리 영역과 로컬 메모리 영역으로 구분  
글로벌 메모리 공간은 서버 시작시 운영체제로부터 할당  

<br>

### 글로벌 메모리 영역
클라이언트 스레드의 수와 무관하게 하나의 메모리 공간만 할당  
모든 스레드에 의해 공유  
- 테이블 캐시
- InnoDB 버퍼풀
- InnoDB 어댑티브 해시 인덱스
- InnoDB 리두 로그 버퍼

<br>

### 로컬 메모리 영역
세션 메모리 영역이라고 표현  
클라이언트 스레드가 쿼리를 처리하기 위해 사용하는 메모리 영역  
각 클라이언트 스레드별로 독립적으로 할당되며 절대 공유 불가  
각 쿼리의 용도별로 필요할 때만 공간 할당, 필요하지 않은 경우 할당하지 않음  
- 정렬 버퍼(sort buffer)
- 조인 버퍼
- 바이너리 로그 캐시
- 네트워크 버퍼

<br>

### 플러그인 스토리지 엔진 모델

<img width="550" alt="mysqlPlugginStorageEngineModel" src="https://github.com/user-attachments/assets/37fc3d5c-1941-4bdd-86f8-5b14d6a54fc5" />

MySQL 독특한 구조 중 대표적인 것이 플러그인 모델  
스토리지 엔진뿐만 아니라 다른 용도의 플러그인 사용 가능  
쿼리가 실행되는 과정은 대부분 MySQL 엔진에서 처리후 마지막 읽기/쓰기 작업만 스토리지 엔진에 의해 처리  
MySQL 엔진이 각 스토리지 엔진에게 명령하려면 반드시 핸들러를 통해야 가능  

```
mysql> SHOW ENGINES;
+--------------------+---------+-------------------------+--------------+------+------------+
| Engine             | Support | Comment                 | Transactions | XA   | Savepoints |
+--------------------+---------+-------------------------+--------------+------+------------+
| ARCHIVE            | YES     | Archive storage engin   | NO           | NO   | NO         |
| BLACKHOLE          | YES     | /dev/null storage eng.. | NO           | NO   | NO         |
| MRG_MYISAM         | YES     | Collection of identic.. | NO           | NO   | NO         |
| FEDERATED          | NO      | Federated MySQL stora.. | NULL         | NULL | NULL       |
| MyISAM             | YES     | MyISAM storage engine   | NO           | NO   | NO         |
| PERFORMANCE_SCHEMA | YES     | Performance Schema      | NO           | NO   | NO         |
| InnoDB             | DEFAULT | Supports transactions.. | YES          | YES  | YES        |
| MEMORY             | YES     | Hash based, stored in.. | NO           | NO   | NO         |
| CSV                | YES     | CSV storage engine      | NO           | NO   | NO         |
+--------------------+---------+-------------------------+--------------+------+------------+

mysql> SHOW PLUGINS;
+-----------------------+----------+--------------------+---------+---------+
| Name                  | Status   | Type               | Library | Lecense |
+-----------------------+----------+--------------------+---------+---------+
| binlog                | ACTIVE   | STORAGE ENGINE     | NULL    | GPL     |
| mysql_native_password | ACTIVE   | AUTHENTICATION     | NULL    | GPL     |
| sha256_password       | ACTIVE   | AUTHENTICATION     | NULL    | GPL     |
| caching_sha2_password | ACTIVE   | AUTHENTICATION     | NULL    | GPL     |
| sha2_cache_cleaner    | ACTIVE   | AUDIT              | NULL    | GPL     |
| CSV                   | ACTIVE   | STORAGE ENGINE     | NULL    | GPL     |
| MEMORY                | ACTIVE   | STORAGE ENGINE     | NULL    | GPL     |
| InnoDB                | ACTIVE   | STORAGE ENGINE     | NULL    | GPL     |
| INNODB_TRX            | ACTIVE   | INFORMATION SCHEMA | NULL    | GPL     |
| INNODB_CMP            | ACTIVE   | INFORMATION SCHEMA | NULL    | GPL     |
| INNODB_CMP_RESET      | ACTIVE   | INFORMATION SCHEMA | NULL    | GPL     |
| MyISAM                | ACTIVE   | STORAGE ENGINE     | NULL    | GPL     |
| MRG_MYISAM            | ACTIVE   | STORAGE ENGINE     | NULL    | GPL     |
| PERFORMANCE_SCHEMA    | ACTIVE   | STORAGE ENGINE     | NULL    | GPL     |
| TempTable             | ACTIVE   | STORAGE ENGINE     | NULL    | GPL     |
| ARCHIVE               | ACTIVE   | STORAGE ENGINE     | NULL    | GPL     |
| BLACKHOLE             | ACTIVE   | STORAGE ENGINE     | NULL    | GPL     |
| FEDERATED             | DISABLED | STORAGE ENGINE     | NULL    | GPL     |
| ngram                 | ACTIVE   | FTPARSER           | NULL    | GPL     |
| mysqlx_cache_cleaner  | ACTIVE   | AUDIT              | NULL    | GPL     |
| mysqlx                | ACTIVE   | DAEMON             | NULL    | GPL     |
+-----------------------+----------+--------------------+---------+---------+
```

<br>

### 컴포넌트
8.0 버전부터 기존 플러그인 아키텍처를 대체하기 위해 컴포넌트 아키텍처 지원  
- 플러그인은 오직 MySQL 서버와 인터페이스 가능, 플러그인끼리 통신 불가
- 플러그인은 MySQL 서버 변수나 함수를 직접 호출하기 때문에 안전하지 않음(캡슐화 위반)
- 플러그인은 상호 의존 관계 설정 불가, 초기화 어려움  

<br>

### 쿼리 실행 구조

<img width="550" alt="mysqlQueryExecute" src="https://github.com/user-attachments/assets/39fdb5b6-680e-4d87-882e-7fdf3a4ae572" />

<br>

### 쿼리 파서
쿼리 문장을 토큰으로 분리해서 트리 구조로 만드는 과정  
기본 문법 오류를 이 과정에서 발견  

<br>

### 전처리기
파서 과정에서 만들어진 트리를 기반으로 쿼리 문장에 구조적인 문제점 확인  
이름 오류, 객체 존재 여부, 객체 접근 권한 등을 확인하는 과정  
존재하지 않거나 접근 권한이 없는 토큰 필터링  

<br>

### 옵티마이저
쿼리 문장을 가장 저렴한 비용으로 빠르게 처리할지 결정  
옵티마이저가 더 나은 선택을 할 수 있게 유도 가능  

<br>

### 실행 엔진
만들어진 계획대로 각 핸들러에게 요청  
여러 핸들러의 요청 결과를 병합하는 역할  

<br>

### 핸들러(스토리지 엔진)
가장 밑단에서 실행 엔진의 요청에 따라 데이터를 직접 처리하는 역할  
MyISAM 스토리지 엔진과 InnoDB 스토리지 엔진이 해당  

<br>

### 쿼리 캐시
SQL 실행 결과를 메모리에 캐시하고 동일 쿼리가 실행되는 경우 즉시 결과 반환  
데이터 변경이 발생한 경우 관련된 캐시를 모두 삭제 필수  
캐시를 삭제하는 과정에서 심각한 동시 처리 성능 저하가 유발되어 8.0 버전에서 완전히 제거  

<br>

### 스레드 풀
엔터프라이즈 스레드 풀 기능은 내장된 기능이지만 Percona Server 스레드 풀은 플러그인 형태로 동작  
커뮤니티 에디션에서도 스레드 풀 기능을 사용하려면 동일 버전 Percona Server 스레드 풀 플러그인 라이브러리(`thread_pool.so` 파일) 설치 필요  
CPU가 제한된 갯수의 스레드 처리에만 집중할 수 있게하는 것이 목적  

Percona Server 스레드 풀은 기본적으로 CPU 코어 갯수만큼 스레드 그룹 생성  
스레드 그룹 갯수는 `thread_pool_size` 시스템 변수값으로 설정  
만약 이미 스레드 풀이 작업중인 경우 `thread_pool_oversubscribe` 시스템 변수값에 설정된 갯수만큼 추가로 더 받아들여서 처리  
모든 스레드가 일을 처리하고 있다면 스레드를 추가할지 대기할지 판단  
`thread_pool_stall_limit` 시스템 변수값의 밀리초만큼 대기해보고 새로운 스레드 생성  
`thread_pool_max_threads` 시스템 변수값만큼만 스레드 갯수를 조절  
또한 선순위 큐와 후순위 큐를 이용해 특정 트랜잭션이나 쿼리의 우선순위를 할당하는 기능도 제공  

<br>

### 트랜잭션 지원 메타데이터
서버가 작동하는데 기본적으로 필요한 테이블들을 묶어서 시스템 테이블 구성  
8.0 버전부터 데이터 딕셔너리와 시스템 테이블이 모두 트랜잭션 기반의 InnoDB 스토리지 엔진에 저장되도록 개선  
데이터베이스는 통째로 `mysql.ibd` 테이블스페이스에 저장  
스키마 변경 작업 중간에 서버가 비정상적 종료되더라도 완전한 성공 또는 실패로 정리, 테이블이 깨지는 현상 개선  

<br>
