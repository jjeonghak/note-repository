# 데이터 압축
디스크에 저장된 데이터 파일의 크기는 쿼리 처리 성능, 백업 및 복구 시간과 밀접하게 연결  

<br>

## 페이지 압축
페이지 압축은 `yransparent page compression`이라고 표현  
서버가 디스크에 저장하는 시점에 데이터 페이지 압축되어 저장  
버퍼풀 에 데이터 페이지는 한 번 적재되면 압축 해제된 상태로만 관리  
MySQL 서버의 내부 코드에서는 압축 여부와 관계없이 투명(`tranparent`)하게 작동  
하지만 16KB 데이터 페이지를 압축한 결과 용량이 예측 불가한데, 하나의 테이블은 동일한 크기 페이지(블록)로 통일 필수  

<br>

<img width="700" alt="punchhole" src="https://github.com/user-attachments/assets/2d8407a6-f696-41ee-b6c1-fc493efe50a8" />

페이지 압축 기능은 운영체제 별로 특정 버전 파일 시스템에서만 지원되는 펀치 홀(`punch hole`) 기능 사용  
운영체제 파일 시스템의 블록 사이즈가 512byte인 경우
1. 16KB 페이지 압축, 압축 결과 7KB로 가정  
2. 디스크에 압축된 결과 7KB 기록, 이후 9KB 빈 데이터를 기록  
3. 데이터 기록 후 7KB 이후 공간 9KB에 대해 펀치 홀 생성
4. 파일 시스템은 7KB만 남기고 나머지 9KB 운영체제로 반납

<br>

```sql
## 테이블 생성
CREATE TABLE t1 (c1 INT) COMPESSION="zlib";

## 테이블 변경
ALTER TABLE t1 COMPRESSION="zlib";
OPTIMIZE TABLE t1;
```

<br>

하지만 운영체제 뿐만 아니라 하드웨어에서도 해당 기능을 지원 필수  
또한 파일 시스템 관련 명령어가 펀치 홀을 지원하지 못함(cp)  
실제 페이지 압축은 많이 사용되지 않음  

<br>

## 테이블 압축
운영체제나 하드웨어 제약 없이 사용 가능  
디스크 데이터 파일 크기 감소 가능  
하지만 버퍼풀 공간 활용률과 쿼리 처리 성능이 낮고, 빈번한 데이터 변경이 발생하는 경우 압축률이 떨어짐  

<br>

### 압축 테이블 생성
전제 조건으로 압축을 사용하려는 테이블은 별도의 테이블 스페이스 필수  
`innodb_file_per_table` 시스템 변수값이 ON인 경우  
`innodb_page_size` 시스템 변수값이 16KB인 경우 4KB 또는 8KB만 설정 가능  
페이지 크기가 32KB 또는 64KB인 경우 테이블 압축 불가  

<br>

```sql
SET GLOBAL innodb_file_per_table=ON;

## KEY_BLOCK_SIZE 옵션 필수(ROW_FORMAT 옵션은 생략가능, 기본값)
CREATE TABLE compressed_table (
  c1 INT PRIMARY KEY
)
ROW_FORMAT=COMPRESSED
KEY_BLOCK_SIZE=8;
```

<br>

<img width="500" alt="tablecompression" src="https://github.com/user-attachments/assets/645e06ef-b2cc-4ba9-9e08-53487c5ebd8b" />

`KEY_BLOCK_SIZE` 옵션은 압축된 페이지가 저장될 페이지 크기를 지정  
원본 데이터 압축 결과가 목표 크기보다 작거나 같을 때까지 반복해서 페이지를 스플릿  

1. 16KB 데이터 페이지 압축  
   압축 결과가 8KB 이하면 그래도 디스크 저장  
   압축 결과가 8KB 초과하면 원본 페이지를 스플릿해서 2개의 페이지에 8KB씩 저장  
   
2. 나뉜 페이지 각각에 대해 1번 단계 반복 실행  

<br>

### KEY_BLOCK_SIZE 결정
테이블 압축에서 가장 중요한 것은 압축된 결과를 예측해서 `KEY_BLOCK_SIZE` 설정하는 것  
샘플로 4KB 또는 8KB 테이블을 생성해보고 판단하는 것 권장  
최소 테이블 데이터 페이지가 10개 정도는 되도록 생성 테스트  

```sql
USE employees;

## 샘플 테이블 생성
CREATE TABLE employees_comp4k (
  emp_no int NOT NULL,
  birth_date date NOT NULL,
  first_name varchar(14) NOT NULL,
  last_name varchar(16) NOT NULL,
  gender enum('M', 'F') NOT NULL,
  hire_date date NOT NULL,
  PRIMARY KEY (emp_no),
  KEY ix_firstname (first_name),
  KEY ix_hiredate (hire_date)
)
ROW_FORMAT=COMPRESSED
KEY_BLOCK_SIZE=4;

## 인덱스 별로 압축 실행 획수와 성공 횟수 기록
SET GLOBAL innodb_cmp_per_index_enabled=ON;

INSERT INTO employees_comp4k SELECT * FROM employees;
```

<br>

인덱스 별로 압축 횟수와 성공 횟수, 압축 실패율 조회  
일반적으로 압축 실패율은 `3 ~ 5%` 미만으로 유지  

```
-- // 4KB 설정
mysql> SELECT
          table_name, index_name, compress_ops, compress_ops_ok
          (compress_ops - compress_ops_ok) / compress_ops * 100 as compression_failure_pct
        FROM information_schema.INNODB_CMP_PER_INDEX;
+------------------+--------------+--------------+-----------------+-------------------------+
| table_name       | index_name   | compress_ops | compress_ops_ok | compression_failure_pct |
+------------------+--------------+--------------+-----------------+-------------------------+
| employees_comp4k | PRIMARY      |        18635 |           13478 |                 27.6737 |
| employees_comp4k | ix_firstname |         8320 |            7653 |                  8.0168 |
| employees_comp4k | ix_hiredate  |         7766 |            6721 |                 13.4561 |
+------------------+--------------+--------------+-----------------+-------------------------+

-- // 8KB 설정
mysql> SELECT
          table_name, index_name, compress_ops, compress_ops_ok
          (compress_ops - compress_ops_ok) / compress_ops * 100 as compression_failure_pct
        FROM information_schema.INNODB_CMP_PER_INDEX;
+------------------+--------------+--------------+-----------------+-------------------------+
| table_name       | index_name   | compress_ops | compress_ops_ok | compression_failure_pct |
+------------------+--------------+--------------+-----------------+-------------------------+
| employees_comp4k | PRIMARY      |         8092 |            6593 |                 18.5245 |
| employees_comp4k | ix_firstname |         1996 |            1996 |                  0.0000 |
| employees_comp4k | ix_hiredate  |         1391 |            1381 |                  0.7189 |
+------------------+--------------+--------------+-----------------+-------------------------+
```

<br>

테스트 후 실제 생성된 테이블 크기를 확인  
압축 실패율과 실제 생성된 테이블 크기를 고려해서 판단  

```
linux> ls -alh data/employees/employees*.ibd
-rw-r-----  1 matt  dba    30M  7 26 15:44 employees.ibd
-rw-r-----  1 matt  dba    20M  7 26 21:54 employees_comp4k.ibd
-rw-r-----  1 matt  dba    21M  7 26 22:05 employees_comp8k.ibd
```

<br>

### 압축된 페이지의 버퍼풀 적재 및 사용
InnoDB 스토리지 엔진은 압축된 테이블의 데이터 페이지를 버퍼풀에 적재하면 압축된 상태와 압축 해제된 상태 2개 버전을 관리  
디스크에서 읽은 상태 그대로 적재한 페이지 목록은 `LRU 리스트`가 관리  
압축된 페이지의 압축 해제한 목록은 `Unzip_LRU 리스트`가 관리  

결국 버퍼풀 공간을 이중으로 사용함으로써 메모리 낭비 및 압축으로 인한 CPU 리소스 소모  
이런 단점을 보완하기 위해 요청 패턴에 따라 적절히(`Adaptive`) 처리  
- 버퍼풀 공간이 필요한 경우 `LRU 리스트` 데이터만 유지하고 `Unzip_LRU 리스트` 데이터 제거  
- 압축된 데이터 페이지가 자주 사용되는 경우 `Unzip_LRU 리스트`에 압축 해제된 페이지를 계속 유지  
- 사용되지 않아서 `LRU 리스트`에서 제거된 경우 `Unzip_LRU 리스트`에서도 제거  

압축 해제된 데이터 페이지를 적절한 수준으로 유지하기 위해서 어댑티브 알고리즘 사용  
- CPU 사용량이 높은 서버는 `Unzip_LRU 리스트` 비율 증가  
- Disk IO 사용량이 높은 서버는 `Unzip_LRU 리스트` 비율 감소  

<br>

### 테이블 압축 관련 설정
페이지 압축 실패율을 낮추기 위해 필요한 튜닝 포인트 제공  
- `innodb_cmp_per_index_enabled`  
  테이블 압축이 사용된 테이블의 모든 인덱스 별로 압축 성공 및 실행 횟수를 수집  
  해당 옵션이 비활성화된 경우 테이블 단위만 수집  
  테이블 단위는 `information_schema.INNODB_CMP` 테이블, 인덱스 단위는 `information_schema.INNODB_CMP_INDEX` 테이블에 기록  
  
- `innocb_compression_level`  
  기본적으로 `zlib` 압축 알고리즘만 지원, 이때 압축률 설정
  `0 ~ 9` 범위 중 선택 가능, 값이 작을수록 압축 속도는 빠르지만 저장 공간이 증가
  기본값은 6이며 압축 속도와 압축률 모두 중간 정도
  
- `innodb_compression_failure_threshold_pct`, `innodb_compression_pad_pct_max`  
  테이블 단위로 압축 실패율이 일정 값보다 커지면 압축 실행하기 전 원본 데이터 페이지 끝에 의도적으로 일정 크기 빈 공간 추가
  압축 실패율 기준은 `innodb_compression_failure_threshold_pct` 시스템 변수값으로 설정  
  빈 공간은 패딩(`padding`)이라고 하며, 패딩 공간은 압축 실패율이 높아질수록 증가  
  최대 크기는 `innodb_compression_pad_pct_max` 시스템 변수값을 넘을 수 없음  

- `innodb_log_compressed_pages`  
  비정상종료 후 재시동시 압축 알고리즘의 버전 차이가 있어도 복구되도록 압축된 데이터 페이지를 리두 로그에 기록  
  압축 알고리즘 업그레이드시 유용하지만 데이터 페이지를 통째로 리두 로그에 저장하는 것은 용량 문제 발생 가능  
  
<br>
