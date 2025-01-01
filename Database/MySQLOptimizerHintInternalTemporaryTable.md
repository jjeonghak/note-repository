# 옵티마이저와 힌트
MySQL 서버로 요청된 쿼리 결과가 동일해도 내부적으로 처리 과정은 매우 다양  
쿼리를 최적으로 실행하기 위해 각 테이블의 데이터가 어떤 분포로 저장돼 있는지 통계 정보를 참조  
이런 기본 데이터를 비교해 최적 실행 계획을 수립하는 작업 필수  

<br>

## 내부 임시 테이블 활용
MySQL 엔진이 스토리지 엔진으로부터 받아온 레코드를 정렬하거나 그루핑할 때는 내부적인 임시 테이블을 사용  
`CREATE TEMPORARY TABLE` 명령으로 만든 임시 테이블과 다른 테이블  
일반적으로 임시 테이블은 초기에 메모리에 생성한 뒤 크기가 커지면 디스크로 옮겨짐  
하지만 내부적인 가공을 위해 생성하는 내부 임시 테이블은 다른 세션이나 다른 쿼리에서는 조회/사용 불가  
쿼리가 처리된 경우 자동 삭제  

<br>

### 메모리 임시 테이블과 디스크 임시 테이블
8.0 버전 이전에는 메모리 임시 테이블은 MEMORY, 디스크 임시 테이블은 MyISAM 스토리지 엔진 사용  
8.0 버전부터 메모리는 TempTable, 디스크는 InnoDB 스토리지 엔진 사용  
기존 MEMORY 스토리지 엔진은 `VARBINARY`, `VARCHAR` 같은 가변 길이 타입 지원 안함  
기존 MyISAM 스토리지 엔진은 트랜잭션 지원 안함  

<br>

`internal_tmp_mem_storage_engine` 시스템 변수값으로 메모리 임시 테이블 스토리지 엔진 설정  
`temptable_max_ram` 시스템 변수값으로 메모리 임시 테이블 허용 크기 설정, 기본값 `1GB` 이상 커지면 디스크로 기록  
만약 메모리 임시 테이블로 MEMORY 스토리지 엔진을 사용한다면 `tmp_table_size`, `max_heap_table_size` 시스템 변수값으로 설정  

<br>

임시 테이블 디스크 저장 방식
- MMAP 파일로 디스크에 기록
- InnoDB 테이블로 기록

디스크 저장 방식은 `temptable_use_mmap` 시스템 변수값으로 설정, 기본값 `ON`  
즉 메모리의 TempTable 크기가 1GB 초과된 경우 MMAP 파일로 전환해서 디스크 저장  
바로 디스크 테이블로 저장되면 `internal_tmp_disk_storage_engine` 시스템 변수값으로 설정된 스토리지 엔진 사용, 기본값 InnoDB  


<br>

### 임시 테이블이 필요한 쿼리
별도의 데이터 가공 작업을 필요로 하는 쿼리
- `ORDER BY` 또는 `GROUP BY` 칼럼들이 서로 상이한 경우
- `ORDER BY` 또는 `GROUP BY` 칼럼들이 조인의 순서상 첫번째 테이블이 아닌 경우
- `DISTINCT`, `ORDER BY` 동시 존재하는 경우
- `DISTINCT` 처리를 인덱스로 하지 못하는 경우
- `UNION` 또는 `UNION DISTINCT` 사용된 경우(`UNION ALL` 제외)
- 쿼리 실행 계획에서 `select_type`이 `DERIVED`인 경우

실행 계획에서 Extra 칼럼에 `Using temporary` 메시지 표시 여부로 판단 가능  
하지만 메시지 표시 없이도 임시 테이블을 사용하는 경우 존재  

<br>

### 임시 테이블이 디스크에 생성되는 경우
아래의 경우 메모리 임시 테이블 사용 불가
- `UNION` 또는 `UNION ALL` 칼럼 중에서 길이가 `512byte` 이상인 칼럼이 존재하는 경우
- `GROUP BY` 또는 `DISTINCT` 칼럼 중에서 길이가 `512byte` 이상인 칼럼이 존재하는 경우
- MEMORY 스토리지 엔진 사용중에 메모리 임시 테이블 크기가 `tmp_table_size`, `max_heap_table_size` 시스템 변수값보다 큰 경우
- TempTable 스토리지 엔진 사용중에 메모리 임시 테이블 크기가 `temptable_max_ram` 시스템 변수값보다 큰 경우

<br>

### 임시 테이블 관련 상태 변수
임시 테이블 상세 정보를 확인 가능

```
mysql> FLUSH STATUS;
mysql> SELECT first_name, last_name FROM employees GROUP BY first_name, last_name
mysql> SHOW SESSION STATUS LIKE 'Created_tmp%';
+-------------------------+-------+
| Variable name           | Value |
+-------------------------+-------+
| Created_tmp_disk_tables |     1 |
| Created_tmp_tables      |     1 |
+-------------------------+-------+
```
- `Created_tmp_tables`: 생성된 임시 테이블 누적값
- `Created_tmp_disk_tables`: 디스크에 생성된 임시 테이블 누적값

<br>
