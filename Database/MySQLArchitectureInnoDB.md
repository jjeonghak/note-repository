# 아키텍처

머리를 담당하는 MySQL 엔진과 손발을 담당하는 스토리지 엔진으로 구분 가능  
스토리지 엔진은 핸들러 API를 만족하면 커스텀 스토리지 엔진 추가 사용 가능  

<br>

## InnoDB 스토리지 엔진 아키텍처

<img width="600" alt="mysqlInnoDBStorageEngine" src="https://github.com/user-attachments/assets/c82fb37f-f72d-4329-9ed5-75b7f1409b13" />

<br>

### 프라이머리키에 의한 클러스터링
기본적으로 프라이머리키를 기준으로 클러스터링되어 저장  
모든 세컨더리 인덱스는 레코드 주소 대신 프라이머리키 값을 논리적인 주소로 사용  
프라이머리키를 이용한 레인지 스캔은 굉장히 빨리 처리  
쿼리 실행 계획에서 다른 보조 인덱스보다 프라이머리키 비중이 높게 설정  

MyISAM 스토리지 엔진의 경우 클러스터링키를 지원하지 않음  
프라이머리키와 세컨더리 인덱스가 구조적으로 차이가 없음  
프라이머리키는 유니크 제약이 걸린 세컨더리 인덱스로 볼 수 있고, 모든 인덱스가 물리적인 레코드 주소값을 가짐  

<br>

### 외래키 지원
외래키 지원은 InnoDB 스토리지 엔진 레벨에서 지원(MyIASM, MEMORY 테이블에서 사용 불가)  
외래키는 부모/자식 테이블 모두에 인덱스를 생성  
변경 발생시 부모/자식 테이블에 데이터가 있는지 체크하기 위해 잠금이 여러 테이블로 전파  
그로 인한 데드락 발생 가능성 존재  
만약 수동으로 데이터 적재 또는 스키마 변경이 필요한 경우 `foreign_key_checks` 시스템 변수값을 `OFF`  

```sql
SET foreign_key_chcecks=OFF;
## 작업 실행
SET foreign_key_chcecks=ON;
```

<br>

### MVCC(Multi Version Concurrency Control)
잠금을 사용하지 않는 일관된 읽기를 제공하는 것을 목표  
InnoDB는 언두 로그를 이용해 해당 기능을 구현  
하나의 레코드에 대해 여러 개의 버전이 동시에 관리  
UPDATE 문장이 실행되면 커밋 실행 여부와 관계없이 `InnoDB 버퍼풀`은 새로운 값을 적용  
변경전 값을 `언두 로그`로 복사, 언두 영역을 필요로 하는 트랜잭션이 존재하는 경우까지만 데이터 보관  
이때 다른 커넥션이 레코드를 조회하면 `transaction_isolation` 시스템 변수값에 따라 읽는 값 상이  
- `READ_UNCOMMITTED`: InnoDB 버퍼풀이 가지고 있는 변경된 데이터 조회  
- 그외 격리수준: 언두 로그 데이터 조회  

<br>

### 잠금 없는 일관된 읽기(Non-Locking Consistent Read)
`SERIALIZABLE` 수준이 아닌 다른 격리 수준의 순수 조회 작업은 다른 트랜잭션에 관계없이 잠금을 대기하지 않고 바로 실행  
오랜 시간 활성 상태인 트랜잭션으로 인해 서버가 느려지는 것은 일관된 읽기를 위해 언두 로그를 삭제하지 못하고 유지하기 때문  
트랜잭션은 가능한 빠르게 롤백 또는 커밋하는 것을 권장  

<br>

### 자동 데드락 감지
내부적으로 잠금 대기 목록을 그래프(`Wait-for list`) 형태로 관리  
InnoDB 스토리지 엔진은 데드락 감지 스레드를 보유  
주기적으로 교착 상태에 빠진 트랜잰션을 탐색하고 그중 하나 강제 종료  
이때 강제 종료 기준은 언두 로그 양이 적은 트랜잰셕이 일반적으로 롤백의 대상  
InnoDB 스토리지 엔진은 상위 레이어인 MySQL 엔진에서 관리되는 테이블 잠금은 볼 수 없음  
`innodb_table_locks` 시스템 변수값을 활성화 권장  

데드락 감지 스레드는 잠금 테이블에 새로운 잠금을 걸고 데드락 스레드를 탐색  
이 과정에서 다른 스레드들이 작업을 진행하지 못하고 대기하면서 서비스에 악영향  
`innodb_deadlock_detect` 시스템 변수값을 통해 데드락 감지 스레드 사용 여부 설정  
`innodb_lock_awit_timeout` 시스템 변수값을 통해 일정 시간 이후 자동 요청 실패 가능  

<br>

### 자동화된 장애 복구
InnoDB 데이터 파일은 기본적으로 MySQL 서버가 시작될 때 항상 자동 복구 수행  
이 단계에서 복구될 수 없는 손상이 존재하는 경우 복구 중단 후 MySQL 서버 종료  
이 경우 `innodb_force_recovery` 시스템 변수값을 설정해서 시작해야함  
손상 여부 검사 과정을 선별적으로 진행해야함(모르겠다면 1부터 6까지 변경하면서 재시작, 값이 커질수록 심각한 손실)  
일단 서버가 실행되면 `mysqldump`를 사용해서 가능한 만큼 데이터 백업한 후 테이블을 다시 생성하는 것 권장  

- 1 (`SRV_FORCE_IGNORE_CORRUPT`)  
  테이블스페이스의 데이터나 인덱스 페이지 손상을 발견해도 무시하고 서버 시작  
  `Database page corruption on disk or a failed` 메시지가 출력되는 대부분의 경우  
  `mysqldump`를 이용한 데이터 백업후 새로운 데이터베이스 구축 권장  
  
- 2 (`SRV_FORCE_NO_BACKGROUND`)  
  백그라운드 스레드 가운데 메인 스레드를 시작하지 않고 서버 시작  
  메인 스레드가 언두 데이터를 삭제하는 과정(`undo purge`)에서 장애가 발생하는 경우  

- 3 (`SRV_FORCE_NO_TRX_UNDO`)  
  커밋되지 않은 트랜잭션 작업을 롤백하지 않고 그대로 방치한 후 서버 시작  
  `mysqldump`를 이용한 데이터 백업후 새로운 데이터베이스 구축 권장  

- 4 (`SRV_FORCE_NO_IBUF_MERGE`)  
  인서트 버퍼의 내용을 무시하고 서버 시작  
  보통 변경 작업을 인서트 버퍼는 저장해두고 나중에 처리  
  실제 데이터와 관련된 부분이 아니라 인덱스에 관련된 부분이라 덤프후 다시 데이터베이스 구축시 데이터 손실없음  

- 5 (`SRV_FORCE_NO_UNDO_LOG_SCAN`)  
  언두 로그를 무시하고 서버 시작  
  커밋되지 않은 작업도 모두 커밋된 것처럼 처리  
  `mysqldump`를 이용한 데이터 백업후 새로운 데이터베이스 구축 권장  

- 6 (`SRV_FORCE_NO_LOG_REDO`)  
  리두 로그를 무시하고 서버 시작  
  커밋되었지만 리두 로그에만 기록되고 데이터 파일에 기록되지 않은 데이터는 모두 무시  
  마지막 체크포인트 시점의 데이터만 존재  
  기존 리두 로그를 모두 삭제하고 다시 서버 재시작 권장  
  `mysqldump`를 이용한 데이터 백업후 새로운 데이터베이스 구축 권장  

<br>

### InnoDB 버퍼풀
InnoDB 스토리지 엔진의 가장 핵심적인 부분  
디스크 데이터 파일이나 인덱스 정보를 메모리에 캐시해 두는 공간  
쓰기 작업을 지연시켜 일괄 작업으로 처리 가능하도록 버퍼 역할  

<br>

### 버퍼 풀의 크기 설정
5.7 버전부터 버퍼풀 크기를 동적으로 조절 가능  
크기를 적절히 작은 값으로 설정하고 필요에 따라 증가시키는 방식 권장  
운영체제의 전체 메모리 공간이 `8GB 미만`이라면 `50%`, `50GB 이상`이라면 `20 ~ 35GB`  
`innodb_buffer_pool_size` 시스템 변수값으로 설정 가능  
버퍼풀 크기를 줄이는 작업은 하지않도록 주의  
내부적으로 `128MB` 청크 단위로 쪼개어 관리  

전통적으로 버퍼풀 전체를 관리하는 잠금(세마포어)으로 인해 내부 잠금 경합 유발  
이런 경합을 줄이기 위해 버퍼풀을 여러개로 쪼개어 관리할 수 있도록 개선  
`innodb_buffer_pool_instances` 시스템 변수값으로 설정 가능  
기본적으로 8개로 초기화, 전체 메모리 크기가 1GB 미만인 경우 1개  

<br>

### 버퍼풀의 구조
페이지 크기(`innodb_page_size`)의 조각으로 관리  
`LRU 리스트`, `flush 리스트`, `free 리스트` 3개의 자료구조로 관리  

`free 리스트`는 사용자 데이터로 채워지지 않은 비어있는 페이지 목록, 새롭게 디스크 데이터 페이지를 조회하는 경우 사용  

`LRU 리스트`는 `old 서브리스트`와 `new 서브리스트`가 결합된 형태  
디스크로부터 조회한 데이터를 최대한 유지하고, 디스크 조회를 최소화하기 위한 목록  
각 데이터 별로 `aging` 적용  
데이터를 처음 디스크에서 조회한 후 `new 서브리스트`에 적재  
처음 한번 조회된 데이터 페이지가 이후 자주 사용된다면 `old 서브리스트`로 적재  

`flush 리스트`는 디스크로 동기화되지 않은 데이터를 가진 페이지의 변경 시점 기준 페이지 목록을 관리  
변경사항이 없이 조회만 되는 경우는 해당하지 않음  
변경이 가해진 데이터를 관리하고 특정 시점이 되면 디스크로 기록  
리두 로그의 각 엔트리는 특정 데이터 페이지와 연결  
체크포인트를 발생시켜 디스크 리두 로그와 데이터 페이지 상태를 동기화  

<br>

### 버퍼풀과 리두 로그
버퍼풀은 데이터 캐시와 쓰기 버퍼링 용도  
버퍼풀은 디스크 조회 상태인 클린 페이지(`clean page`)와 변경된 데이터를 가진 더티 페이지(`dirty page`)를 보유  
변경 사항이 계속 발생하면 리두 로그 파일에 기록됐던 로그 엔트리는 언젠가 새로운 로그 엔트리로 덮어쓰기 적용  
리두 로그 중 재사용 불가능한 공간을 활성 리두 로그(`active redo log`)  

리두 로그 파일의 공간은 계속 순환되어 재사용되지만 매번 로그 포지션(`LSN, log sequence number`)을 증가  
InnoDB 스토리지 엔진은 주기적으로 체크포인트 이벤트를 발생시켜 리두 로그와 버퍼풀 더티 페이지를 디스크로 동기화  
이때 가장 최근 `LSN` 체크포인트가 시작점  
가장 최근 체크포인트와 마지막 리두 로그 엔트리의 `LSN` 차이를 체크포인트 에이지(`checkpoint age`)  
더티 페이지는 특정 리두 로그 엔트리와 관계를 가지고, 체크포인트 발생시 `LSN`보다 작은 리두 로그 엔트리와 더티 페이지를 모두 디스크로 동기화  
만약 버퍼풀 크기가 `100GB 이하`이면 리두 로그 파일의 전체 크기를 대략 `5 ~ 10GB`   

<br>

### 버퍼풀 플러시(Buffer Pool Flush)
8.0 버전부터 더티 페이지를 디스크에 동기화하는 부분에서 쓰기 폭증 현상(`disk io burst`)이 발생하지 않음  
성능상 악영향 없이 디스크에 동기화하기 위해 2개의 플러시 기능을 백그라운드로 처리  
- 플러시 리스트 플러시  
- LRU 리스트 플러시  

<br>

### 플러시 리스트 플러시
리두 로그 공간 재활용을 위해 오래된 리두 로그 엔트리의 사용 공간을 비워야함  
반드시 사전에 더티 페이지가 디스크로 동기화되는 과정 필수  
플러시 함수를 호출해서 플러시 리스트에서 오래전 변경된 페이지 순대로 디스크 동기화 수행  

- `innodb_page_cleaners`: 더티 페이지를 디스크로 동기화하는 스레드인 클리너 스레드 갯수 설정  
- `innodb_max_dirty_pages_pct_lwm`: 기본값은 10%, 더티 페이지 비율이 일정값을 넘긴 경우 디스크 쓰기 작업 실행  
- `innodb_max_dirty_pages_pct`: 기본값은 더티 페이지 비율 90%, 더티 페이지 최대 비율 설정  
- `innodb_io_capacity`: 더티 페이지 쓰기 실행 갯수  
- `innodb_io_capacity_max`: 디스크가 최대 성능을 유지할 때 디스크 읽기/쓰기 가능 갯수  
- `innodb_flush_neighbors`: 더티 페이지를 디스크에 동기화시 근접한 더티 페이지까지 묶어서 기록할지 여부 설정  
- `innodb_adaptive_flushing`: 기본값은 어댑티브 플러시 사용, 어댑티브 플러시 사용 여부 설정  
- `innodb_adaptive_flushing_lwm`: 기본값은 10%, 활성 리두 로그 비율이 일정값 이상인 경우 어댑티브 플러시 작동  

<br>

### LRU 리스트 플러시
사용 빈도가 낮은 LRU 리스트 데이터 페이지를 제거  
리스트의 끝부분부터 시작해서 최대 `innodb_lru_scan_depth` 시스템 변수값만큼 페이지 스캔  
더티 페이지는 디스크 동기화, 클린 페이지는 프리 리스트로 페이지 옮김  
결국 `innodb_buffer_pool_instances` * `innodb_lru_scan_depth` 수만큼 스캔 발생  

<br>

### 버퍼풀 상태 백업 및 복구
버퍼풀에 디스크 데이터다 적재된 상태를 워밍업(`warming up`)  
워밍업된 상태는 그렇지 않은 경우보다 쿼리 처리 속도가 몇십배 좋음  
5.6 버전부터 버퍼풀 덤프 및 적재 기능 도입  
서버 재시작시 `innodb_buffer_pool_dump_now` 시스템 변수값을 이용해 버퍼풀 상태를 백업  

```sql
## MySQL 서버 셧다운 전 버퍼풀 상태 백업
SET GLOBAL innodb_buffer_pool_dump_now=ON;

## MySQL 서버 재시작 후 버퍼풀 상태 복구
SET GLOBAL innodb_buffer_pool_dump_now=ON;
```

<br>

버퍼풀 백업은 데이터 디렉토리에 `ib_buffer_pool` 이름의 파일로 생성  
해당 파일에는 적재된 데이터 페이지 메타 정보만 저장  
백업은 빨리 끝나지만, 백업된 버퍼풀 실제 데이터를 로드하는 과정에서 오랜 시간 소요  
로드 중 백업을 중단하는 경우 `innodb_buffer_pool_load_abort` 시스템 변수값 사용  

```
mysql> SHOW STATUS LIKE 'Innodb_buffer_pool_dump_status'\G
*************************** 1. row ***************************
Variable_name: Innodb_buffer_pool_dump_status
        Value: Buffer pool(s) dump completed at 200712 23:38:58

mysql> SET GLOBAL innodb_buffer_pool_load_abort=ON
```

<br>

자동으로 버퍼풀 복구 기능 제공  
설정 파일에 `innodb_buffer_pool_dump_at_shutdown` 및 `innodb_buffer_pool_load_at_startup` 설정을 미리 추가  

<br>

### 버퍼풀의 적재 내용 확인
5.6 버전부터 `information_schema` 데이터베이스의 `innodb_buffer_page` 테이블을 통해 확인 가능  
하지만 버퍼풀이 큰 경우 상당히 큰 부하 발생  
8.0 버전부터 `information_schema` 데이터베이스의 `innodb_cached_indexes` 테이블을 통해 확인 가능  

```
mysql> SELECT it.name table_name, ii.name index_name, ici.n_cached_pages n_cached_pages
        FROM information_schema.innodb_tables it
          INNER JOIN information_schema.innodb_indexes ii ON ii.table_id = it.table_id
          INNER JOIN information_schema.innodb_cached_indexes ici ON ici.index_id = ii.index_id
        WHERE it.name=CONCAT('employees', '/', 'employees');
+---------------------+---------------------+----------------+
| table_name          | index_name          | n_cached_pages |
+---------------------+---------------------+----------------+
| employees/employees | PRIMARY             |            299 |
| employees/employees | ix_hiredate         |              8 |
| employees/employees | ix_gender_birthdate |              8 |
| employees/employees | ix_firstname        |              8 |
+---------------------+---------------------+----------------+

mysql> SELECT
        (SELECT SUM(ici.n_cached_pages) n_cached_pages
          FROM information_schema.innodb_tables it
            INNER JOIN information_schema.innodb_indexes ii ON ii.table_id = it.table_id
            INNER JOIN information_schema.innodb_cached_indexes ici ON ici.index_id = ii.index_id
          WHERE it.name=CONCAT('employees', '/', 'employees')) as total_cached_pages,
        ((t.data_length + t.index_length - t.data_free)/@@innodb_page_size) as total_pages
      FROM information_schema.tables t
      WHERE t.table_schema='employees' AND t.table_name='employees';
+--------------------+-------------+
| total_cached_pages | total_pages |
+--------------------+-------------+
|                323 |   1668.0000 |
+--------------------+-------------+
```

<br>

### Double Write Buffer
리두 로그는 공간 낭비를 방지하기 위해 페이지의 변경된 내용만 기록  
플러시할때 일부만 기록되는 현상을 파셜 페이지(`partial-page`) 또는 톤 페이지(`torn-page`)라고 표현  
디스크 쓰기 작업 전에 더티 페이지를 모아 시스템 테이블스페이스의 `DoubleWrite 버퍼`에 기록  
실제 데이터 파일의 쓰기가 중간에 실패할 때만 원래 목적으로 사용되는 버퍼  
`innodb_duublewrite` 시스템 변수값으로 사용 여부 설정  
만약 리두 로그 동기화 설정(`innodb_flush_log_at_trx_commit`)을 1이 아닌 값으로 설정했다면, `DoubleWrite 버퍼` 비활성화 권장  

<br>

### 언두 로그
트랜잭션 격리 수준을 보장하기 위해 변경전 데이터를 별도로 백업  
트랜잭션 롤백시 변경된 데이터를 이전 데이터로 복구  

<br>

### 언두 로그 모니터링
5.5 이전 버전에서는 한번 증가한 언두 로그 공간은 다시 줄지 않음  
8.0 버전부터 서버가 필요한 시점에 사용 공간을 자동으로 줄임  

```sql
SELECT count FROM information_schema.innodb_metrics
WHERE SUBSYSTEM='transaction' AND NAME='trx_rseg_history_len';
```

<br>

### 언두 테이블스페이스 관리
언두 로그가 저장되는 공간을 언두 테이블스페이스(`undo tablespace`)  
하나의 언두 테이블스페이스는 1 ~ 128개의 롤백 세그먼트를 보유, 롤백 세그먼트는 1개 이상의 언두 슬롯(`undo slot`) 보유  
페이지 크기를 16byte로 나눈 값의 갯수만큼 언두 슬롯 보유  
하나의 트랜잭션은 특성에 따라 대략 2개에서 최대 4개까지 언두 슬롯 사용  
8.0 버전부터 새로운 언두 테이블스페이스 동적 추가/삭제 가능  

```
mysql> SELECT TABLESPACE_NAME, FILE_NAME
        FROM INFORMATION_SCHEMA.FILES
        WHERE FILE_TYPE LIKE 'UNDO LOG';
+-----------------+------------+
| TABLESPACE_NAME | FILE_NAME  |
+-----------------+------------+
| innodb_undo_001 | ./undo_001 |
| innodb_undo_002 | ./undo_002 |
+-----------------+------------+

-- // 언두 테이블스페이스 생성
mysql> CREATE UNDO TABLESPACE extra_undo_003 ADD DATAFILE '/data/undo_dir/undo_003.ibu';

mysql> SELECT TABLESPACE_NAME, FILE_NAME
        FROM INFORMATION_SCHEMA.FILES
        WHERE FILE_TYPE LIKE 'UNDO LOG';
+-----------------+-----------------------------+
| TABLESPACE_NAME | FILE_NAME                   |
+-----------------+-----------------------------+
| innodb_undo_001 | ./undo_001                  |
| innodb_undo_002 | ./undo_002                  |
| innodb_undo_003 | /data/undo_dir/undo_003.ibu |
+-----------------+-----------------------------+

-- // 언두 테이블스페이스 비활성화
mysql> ALTER UNDO TABLESPACE extra_undo_003 SET INACTIVE;

-- // 비활성화된 언두 테이블스페이스 삭제
mysql> DROP UNDO TABLESPACE extra_undo_003;
```

<br>

언두 테이블스페이스 공간을 필요한 만큼만 남기고 공간을 운영체제에 반납하는 것을 `undo tablespace truncate`  
- 자동 모드  
  퍼지 스레드(`purge thread`)는 주기적으로 언두 로그 공간의 불필요한 언두 로그 삭제(`undo purge`)  
  `innodb_undo_log_truncate` 시스템 변수값이 ON인 경우  
  `innodb_purge_rseg_truncate_frequency` 시스템 변수값으로 발생 빈도 설정  
  
- 수동 모드  
  `innodb_undo_log_truncate` 시스템 변수값이 OFF인 경우  
  언두 테이블스페이스가 최소 3개 이상일 때만 작동  

<br>

### 체인지 버퍼
데이터 변경이 발생할때 데이터 파일뿐만 아니라 인덱스 업데이트도 필수  
인덱스 업데이트 작업은 랜덤하게 디스크를 읽는 작업 필요  
변경해야할 인덱스 페이지가 버퍼풀에 존재하면 바로 업데이트 수행  
없다면 임시 공간 체인지 버퍼(`change buffer`)에 저장하고 사용  

반드시 중복 여부를 체크해야하는 유니크 인덱스는 체인지 버퍼 사용 불가  
체인지 버퍼에 임시로 저장된 인덱스 레코드 조각은 이후 백그라운드에 의해 병합  
체인지 버퍼 머지 스레드(`merge thread`)에 의해 해당 작업 수행  
`innodb_change_buffering` 시스템 변수값을 통해 설정  
- `all`: 모든 인덱스 관련 작업 버퍼링  
- `none`: 버퍼링 사용 안함  
- `inserts`: 인덱스에 새로운 아이템 추가시 버퍼링  
- `deletes`: 인덱스에 기존 아이템 삭제시 버퍼링  
- `changes`: 인덱스에 추가/삭제시 버퍼링  
- `purges`: 인덱스 아이템을 영구적으로 삭제시 버퍼링  

체인지 버퍼는 버퍼풀의 메모리 공간의 `25 ~ 50%`까지 사용 가능  
`innodb_change_buffer_max_size` 시스템 변수값으로 비율 설정  

```
mysql> SELECT EVENT_NAME, CURRENT_NUMBBER_OF_BYTES_USED
        FROM performance_schema.memory_summary_global_by_event_name
        WHERE EVENT_NAME='memory/innodb/ibuf0ibuf';
+-------------------------+-------------------------------+
| EVENT_NAME              | CURRENT_NUMBBER_OF_BYTES_USED |
+-------------------------+-------------------------------+
| memory/innodb/ibuf0ibuf |                           144 |
+-------------------------+-------------------------------+
```

<br>

### 리두 로그 및 로그 버퍼
리두 로그는 트랜잭션 ACID 중 D(`durable`)에 해당하는 영속성과 가장 밀접  
서버가 비정상 종료시 데이터 파일에 기록되지 못한 데이터를 잃지 않게 해주는 안전장치  
데이터 변경 내용을 로그로 가장 먼저 기록  
데이터베이스는 읽기 성능을 고려한 자료구조를 사용하기 때문에 쓰기 작업은 디스크 랜덤 엑세스 필요  
리두 로그는 쓰기 비용이 낮은 자료구조를 사용  

1. 커밋됐지만 데이터 파일에 기록되지 않은 데이터 - 리두 로그 활용  
2. 롤백됐지만 데이터 파일에 이미 기록된 데이터 - 언두 로그 활용  

리두 로그는 트랜잭션이 커밋되면 즉시 디스크로 기록되도록 시스템 변수를 설정하는 것을 권장  
`innodb_flush_log_at_trx_commit` 시스템 변수값으로 설정  
- 0: 1초에 한번씩 리두 로그를 디스크로 기록 및 동기화  
- 1: 매번 트랜잭션이 커밋될 때마다 디스크로 기록 및 동기화  
- 2: 매번 트랜잭션이 커밋될 때마다 디스크로 기록, 실질적인 동기화는 1초에 한번씩  

리두 로그 파일의 크기는 `innodb_log_file_size` 시스템 변수값으로 설정  
리두 로그 파일의 갯수는 `innodb_log_files_in_group` 시스템 변수값으로 설정  
로그 버퍼 크기는 기본값 16MB 수준에서 설정하는 것이 적합(BLOB, TEXT 같은 큰 데이터의 경우 더 크게 설정)  

<br>

### 리두 로그 아카이빙
8.0 버전부터 리두 로그 아카이빙 기능 추가  
데이터 변경이 많아서 리두 로그를 덮어쓴다고 하더라도 백업에 실패하지 않음  
아카이빙된 리두 로그가 저장될 디렉토리는 `innodb_redo_log_archive_dirs` 시스템 변수값으로 설정  

```
linux> mkdir /var/log/mysql_redo_archive
linux> mkdir /var/log/mysql_redo_archive/20200722
linux> chmod 700 /var/log/mysql_redo_archive/20200722

mysql> SET GLOBAL innodb_redo_log_archive_dirs='backup:/var/log/mysql_redo_archive';
```

<br>

디렉토리 준비 후 `innodb_redo_log_archive_start` UDF(`user defined function`) 실행  
1번째 파라미터는 리두 로그 아카이빙 디렉토리에 대한 레이블  
2번째 파라미터는 서브디렉토리 이름, 필수 아님  

```sql
## 리두 로그 아카이빙 활성화
DO innodb_redo_log_archive_start('backup', '20200722');
CREATE TABLE test (id bigint auto_increment, data mediumtext, PRIMARY KEY(id));
INSERT INTO test (data)
SELECT repeat(`123456789`, 10000) FROM employees.salaries LIMIT 100;
```

```
linux> ls -alh /var/log/mysql_redo_archive/20200722
-r--r-----  1 matt.lee 991M  7 22 11:12 archive.5b30884e-726c-11ea-951c-f91ea9f6d340.000001.log
```

```sql
## 리두 로그 아카이빙 비활성화
DO innodb_redo_log_archive_stop();
```

해당 방법으로 아카이빙을 실행한 세션을 끊지않는다면 비정상 종료로 간주하고 쓸모 없어진 리두 로그를 삭제  

<br>

### 리두 로그 활성화 및 비활성화
8.0 버전부터 데이터를 복구하거나 대용량 데이터를 한번에 적재하는 경우 리두 로그를 비활성화 가능  

```
mysql> ALTER INSTANCE DISABLE REDO_LOG;
mysql> SHOW GLOBAL STATUS LIKE 'Innodb_redo_log_enabled';
+-------------------------+-------+
| Variable_name           | Value |
+-------------------------+-------+
| Innodb_redo_log_enabled | OFF   |
+-------------------------+-------+

-- // 데이터 적재 작업 이후

mysql> ALTER INSTANCE ENABLE INNODB REDO_LOG;
mysql> SHOW GLOBAL STATUS LIKE 'Innodb_redo_log_enabled';
+-------------------------+-------+
| Variable_name           | Value |
+-------------------------+-------+
| Innodb_redo_log_enabled | ON    |
+-------------------------+-------+

```

<br>

### 어댑티브 해시 인덱스
일반적으로 인덱스는 사용자가 생성해준 B-Tree 인덱스를 의미  
어댑티브 해시 인덱스는 사용자가 수동으로 생성하는 인덱스가 아닌 InnoDB 스토리지 엔진에서 사용자가 자주 요청하는 데이터를 자동으로 생성하는 인덱스  
`innodb_adaptive_hash_index` 시스템 변수값으로 활성화 가능  

어댑티브 해시 인덱스는 B-Tree 검색 시간을 줄이려는 목적으로 도입된 기능  
자주 조회되는 데이터 페이지를 키 값으로 해시 인덱스를 생성하고 즉시 조회 가능  
B-Tree 루트 노드부터 리프 노드까지 탐색하는 비용 제거  

해시 인덱스 키 값은 B-Tree 인덱스 고유 번호와 B-Tree 인덱스 실제 키 값의 조합으로 생성  
B-Tree 인덱스 고유 번호가 포함되는 이유는 어댑티브 해시 인덱스는 서버에 단 하나 존재하기 때문  
또한 버퍼풀에 존재하는 데이터 페이지만 관리  

이전에는 서버에 하나뿐인 어댑티브 해시 인덱스에 대한 경합이 상당히 빈번  
8.0 버전부터 어댑티브 해시 인덱스 파티션 기능을 기본 8개로 제공  
`innodb_adaptive_hash_index_parts` 시스템 변수값으로 파티션 갯수 설정  

어댑티브 해시 인덱스는 테이블 삭제 또는 변경 작업에 매우 치명적  
어댑티브 해시 인덱스를 효율적으로 사용중인지 확인 필수  

```
mysql> SHOW ENGINE INNODB STATUS\G
...
-------------------------------------
INSERT BUFFER AND ADAPTIVE HASH INDEX
-------------------------------------
...
Hash table size 8747, node heap has 1 buffer(s)
Hash table size 8747, node heap has 0 buffer(s)
Hash table size 8747, node heap has 0 buffer(s)
Hash table size 8747, node heap has 0 buffer(s)
Hash table size 8747, node heap has 0 buffer(s)
Hash table size 8747, node heap has 0 buffer(s)
Hash table size 8747, node heap has 0 buffer(s)
Hash table size 8747, node heap has 0 buffer(s)
1.03 hash searches/s, 2.64 non-hash searches/s
...

mysql> SELECT EVENT_NAME, CURRENT_NUMBER_OF_BYTES_USED
        FROM performance_schema.memory_summary_global_by_event_name
        WHERE EVENT_NAME='memory/innodb/adaptive hash index';
+-----------------------------------+------------------------------+
| EVENT_NAME                        | CURRENT_NUMBER_OF_BYTES_USED |
+-----------------------------------+------------------------------+
| memory/innodb/adaptive hash index |                         1512 |
+-----------------------------------+------------------------------+
```

해당 결과에서 초당 3.67(= 1.03 + 2.64)번의 검색 실행, 그중 1.03번은 어댑티브 해시 인덱스 사용  
해시 인덱스 히트율, 해시 인덱스 메모리 사용륭, CPU 사용량을 종합해서 판단  

<br>
