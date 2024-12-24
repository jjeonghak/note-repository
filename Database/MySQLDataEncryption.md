# 데이터 암호화

5.7 버전부터 지원된 데이터 암호화는 테이블스페이스에 대해서만 기능 지원  
8.0 버전부터 리두 로그, 언두 로그, 복제를 위한 바이너리 로그 등 모두 암호화 기능 지원  

<br>

## MySQL 서버의 데이터 암호화

<img width="350" alt="distio" src="https://github.com/user-attachments/assets/d282ad9a-71d8-42c2-8e7f-1dea1c7bd103" />

서버와 디스크 사이에서 조회/쓰기 지점에서만 암호화 처리 필요  
즉 I/O 레이어에서만 데이터 암호화 및 복호화 과정 실행  
서버와 사용자는 데이터 암호화 기능 활성화 여부에 상관없이 똑같이 서비스 이용 가능  
이러한 암호화 방식을 `TDE(transparent data encryption)`이라고 표현  

<br>

### 2단계 키 관리
`TDE`에서 암호화 키는 키링(`KeyRing`) 플러그인에 의해 관리  
MySQL 커뮤니티 에디션에서는 `keyring_file` 플러그인만 사용 가능  
2단계(2-Tier) 키 관리 방식을 사용  

<br>

<img width="550" alt="2-tier" src="https://github.com/user-attachments/assets/f8ffbe2f-b127-4308-a1e0-571248f1be55" />

<br>

데이터 암호화는 마스터 키와 테이블스페이스 키 두 종류 보유, 테이블스페이스 키는 프라이빗 키로도 표현  
외부 키 관리 솔루션 또는 디스크 파일에서 마스터 키를 조회  
암호화된 테이블이 생성될 때마다 임의의 테이블스페이스 키를 발급  
서버는 마스터 키를 사용해서 테이블스페이스 키를 암호화해 각 테이블 데이터 파일 헤더에 저장  
이렇게 생성된 테이블스페이스 키는 테이블 삭제 전까지 절대 변경되지 않음  
테이블스페이스 키는 외부로 절대 노출되지 않지만, 마스터 키는 외부 파일을 이용하기 때문에 주기적으로 변경 필요  

<br>

```sql
ALTER INSTANCE ROTATE INNODB MASTER KEY;
```

마스터 키를 변경하면 모든 테이블스페이스 키를 복호화한 후 다시 새로운 마스터 키로 암호화  
마스터 키가 변경되도 테이블스페이스 키 자체와 데이터 파일의 데이터는 전혀 변경되지 않음  
2단계 암호화 방식을 이용해서 암호화 키 변경으로 인한 과도한 시스템 부하 방지  

기본적으로 `TDE` 지원 알고리즘은 `AES 256bit`, 이외의 알고리즘은 지원하지 않음  
테이블스페이스 키는 `AES-256 ECB(Electronic Code Book)` 알고리즘 사용  
실제 데이터 파일은 `AES-256 CBC(Cipher Block Chaining)` 알고리즘 사용  

<br>

### 암호화와 성능
`TDE` 방식이기 때문에 디스크로부터 한번 읽은 데이터 페이지는 복호화되어 버퍼풀에 적재  
한번 적재되면 암호화되지 않은 테이블과 동일한 성능  
하지만 버퍼풀에 없는 데이터를 디스크로부터 조회하는 경우 복호화 과정 필요, 쿼리 지연 가능성 존재  
또한 변경 사항을 디스크로 동기화할때 암호화 과정 필요, 하지만 데이터 저장은 백그라운드 스레드가 수행하기에 쿼리 지연 없음  

`AES(Advanced Encryption Standard)` 암호화 알고리즘은 평문의 길이가 짧은 경우 키의 크기에 따라 용량 증가 가능성 존재  
하지만 데이터 페이지는 암호화 키보다 훨씬 크기때문에 평문과 동일한 크기의 암호화 결과 반환  
따라서 메모리 사용 효율이 떨어지는 현상은 발생하지 않음  

테이블 압축과 암호화가 동시에 적용된 경우 우선 압축 실행  
- 일반적으로 암호화된 결과문은 랜덤한 바이트 배열을 반환하는데, 압축률 저하 유발  
- 버퍼풀은 압축된 페이지와 압축 해제된 페이지를 모두 보유하기 때문에 압축을 먼저 실행해야 매번 압축 해제시 암복호화 작업을 수행하지 않음  

<br>

```sql
## 디스크 읽기/쓰기 속도 성능 조회
SELECT (SUM(SUM_TIMER_READ) / SUM(COUNT_READ)) / 1000000000 as avg_read_latency_ms,
       (SUM()SUM_TIMER_WRITE) / SUM(COUNT_WRITE)) / 1000000000 as avg_write_latency_ms
FROM performance_schema.file_summary_by_instance
WHERE file_name LIKE '%DB_NAME/TABLE_NAME%';
```

| 암호화 여부 | 테이블 크기(GB) | Read Latency(ms) | Write Latency(ms) |
|--|--|--|--|
| 비활성화 | 1.3 | 0.56 | 0.02 |
| 비활성화 | 2.7 | 0.16 | 0.02 |
| 비활성화 | 3.7 | 0.49 | 0.02 |
| 비활성화 | 106.6 | 0.34 | 0.02 |
| 비활성화 | 141.0 | 0.25 | 0.02 |
| 활성화 | 2.0 | 1.19 | 0.11 |
| 활성화 | 4.8 | 1.50 | 0.13 |
| 활성화 | 206.5 | 1.44 | 0.12 |

<br>

### 암호화와 복제
레플리카 서버는 소스 서버의 모든 사용자 데이터를 동기화  
하지만 `TDE`를 이용한 암호화 사용시 마스터 키와 테이블스페이스 키는 서로 다르도록 설정  
마스터 키 자체가 레플리카로 복제되지 않기 때문에 테이블스페이스 키도 복제되지 않음  
`ALTER INSTANCE ROTATE INNODB MASTER KEY` 명령을 통해 소스 서버와 레플리카 서버가 각각 서로 다른 마스터 키를 새로 발급  
백업에서 키링 파일을 백업하지 않는 경우 데이터 복구 불가  

<br>

## keyring_file 플러그인 설치
`TDE` 암호화 키 관리는 플러그인 방식으로 제공  
`keyring_file` 플러그인은 마스터 키를 디스크 파일로 관리  
평문으로 디스크에 저장되기 때문에 외부로 노출되지 않도록 주의  

서버가 시작되는 단계에서 가장 빨리 초기화 필수  
설정 파일에서 `early-plugin-load` 시스템 변수값에 `keyring_file` 플러그인을 위한 `keyring_file.so` 라이브러리 명시 필수  
마스터 키 저장을 위한 파일 경로는 `keyring_file_data` 설정에 명시  

```ini
early-plugin-load = kering_file.so
keyring_file_data = /very/secure/directory/tde_master.key
```

```
mysql> SHOW PLUGINS;
+-----------------------+--------+----------------+-----------------+---------+
| Name                  | Status | Type           | Libary          | License |
+-----------------------+--------+----------------+-----------------+---------+
| keyring_file          | ACTIVE | KEYRING        | keyring_file.so | GPL     |
| binlog                | ACTIVE | STORAGE ENGINE | NULL            | GPL     |
| mysql_native_password | ACTIVE | AUTHENTICATION | NULL            | GPL     |
| ...                   | ...    | ...            | ...             | ...     |
+-----------------------+--------+----------------+-----------------+---------+
```

<br>

서버는 플러그인 초기화와 동시에 `keyring_file_data` 시스템 변수의 경로에 빈 파일 생성  
암호화 기능을 사용하는 테이블 생성하거나 마스터 로테이션 실행시 키링 파일의 마스터 키 초기화  

```
linux> ls -alh tde_master.key
-r-w-r-----  1 matt  0B  7 27 14:24 tde_master.key

mysql> ALTER INSTANCE ROTATE INNODB MASTER KEY;

linux> ls -alh tde_master.key
-r-w-r-----  1 matt 187B  7 27 14:24 tde_master.key
```

<br>

## 테이블 암호화
키링 플러그인은 마스터 키 생성 및 관리까지만 담당  
어떤 플러그인을 사용하든 암호화된 테이블 생성하고 활용하는 방법은 모두 동일  

<br>

### 테이블 생성
일반적인 테이블 생성 구문과 동일  
`ENCRPTION='Y'` 옵션만 추가  
모든 생성 테이블에 암호화를 적용하고자 한다면 `default_table_encryption` 시스템 변수값 ON 설정  

```
mysql> CREATE TABLE tab_encrypted (
         id INT,
         data VARCHAR(100),
         PRIMARY KEY(id)
       ) ENCRYPTION='Y';

mysql> INSERT INTO tab_encrypted VALURES (1, 'test-data');

mysql> SELECT * FROM tab_encrypted;
+----+-----------+
| id | data      |
+----+-----------+
|  1 | test-data |
+----+-----------+
```

<br>

암호화된 테이블만 조회가능  

```
mysql> SELECT table_schema, table_name, create_options
       FROM information_schema.tables
       WHERE create_options LIKE '%ENCRYPTION='Y'%';
+--------------+---------------+----------------+
| TABLE_SCHEMA | TABLE_NAME    | CREATE_OPTIONS |
+--------------+---------------+----------------+
| test         | tab_encrypted | ENCRYPTION='Y' |
+--------------+---------------+----------------+
```

<br>

### 테이블스페이스 이동
테이블만 이동해야하는 경우 레코드 덤프/복구 방식보다 테이블스페이스 이동 기능이 효율적  
이동 전후의 암호화 마스터 키가 다르기 때문에 주의 필요  

<br>

```sql
FLUSH TABLES source_table FOR EXPORT;
```

- 암호화되지 않은 테이블 이동  
  저장되지 않은 변경 사항을 모두 디스크로 기록하고 테이블 잠금 설정  
  동시에 테이블의 구조를 `.cfg` 파일로 기록  
  `.ibd` 파일과 `.cfg` 파일을 목적지 서버로 복사  
  복사가 완료되면 잠금 해제  

- 암호화 테이블 이동  
  임시로 사용할 마스터 키 발급 후 `.cfp` 파일로 기록  
  기존 마스터 키로 복호화 후, 임시 마스터 키로 다시 암호화해서 헤더에 임시 마스터 키 저장  
  `.ibd` 파일, `.cfg` 파일, `.cfp` 파일을 목적지 서버로 복사  

<br>

## 언두 로그 및 리두 로그 암호화
서버의 메모리에 존재하는 데이터는 복호화된 평문으로 관리  
테이블 데이터 파일 이외의 디스크 파일로 기록되는 경우 여전히 평문으로 저장  
8.0.16 버전부터 `innodb_undo_log_encrypt`, `innodb_redo_log_encrypt` 시스템 변수값을 이용해 암호화 가능  

테이블 암호화와 달리 언두 로그, 리두 로그 암호화는 암호화 적용 시점부터만 암호화 상태로 저장  
즉 암호화 비활성화 적용 후에도 테이블스페이스 키와 마스터 키가 필수  
언두 로그, 리두 로그 모두 각각의 테이블스페이스 키로 암호화, 테이블스페이스 키는 마스터 키로 암호화  

```
mysql> INSERT INTO enc VALUES (2, 'test-data1');
mysql> SET GLOBAL innodb_redo_log_encrypt=ON;
mysql> INSERT INTO enc VALUES (2, 'test-data2');

linux> grep 'test-data1' ib_logfile0 ib_logfile1
Binary file ib_logfile0 matches
linux> echo $?
0

linux> grep 'test-data2' ib_logfile0 ib_logfile1
linux> echo $?
1
```

<br>

## 바이너리 로그 암호화
테이블 암호화가 적용돼도 바이너리 로그와 릴레이 로그 파일 또한 평문으로 저장  
바이너리 로그는 상대적으로 언두 로그와 리두 로그보다 상당히 긴 시간 동안 보관  
바이너리 로그 파일의 암호화는 상황에 따라 중요도가 높음  

<br>

### 바이너리 로그 암호화 키 관리

<img width="550" alt="binarylogencription" src="https://github.com/user-attachments/assets/5524ad48-0ea1-43b7-acc6-bef437c756f0" />

바이너리 로그와 릴레이 로그 파일은 파일 키로 암호화  
파일 키는 바이너리 로그 암호화 키로 암호화해서 각 파일 헤더에 저장  

<br>

### 바이너리 로그 암호화 키 변경

```sql
ALTER INSTANCE ROTATE BINLOG MASTER KEY;
```

1. 증가된 시퀀스 번호와 함께 새로운 바이너리 로그 암호화 키 발급 후 키링 파일에 저장  
2. 바이너리 로그 파일과 릴레이 로그 파일 스위치  
3. 새로 생성된 로그 파일에 파일 키를 생성  
4. 기존 암호화된 로그 파일의 파일 키를 읽어서 새로운 바이너리 로그 암호화 키로 암호화해서 다시 저장  
5. 기존 바이너리 로그 암호화 키 제거  

```
mysql> SHOW BINARY LOGS;
+------------------+-----------+-----------+
| Log_name         | File_size | Encrypted |
+------------------+-----------+-----------+
| mysql-bin.000010 |      2853 | No        |
| mysql-bin.000011 |      1337 | Yes       |
+------------------+-----------+-----------+
```

<br>
