# 옵티마이저와 힌트
MySQL 서버로 요청된 쿼리 결과가 동일해도 내부적으로 처리 과정은 매우 다양  
쿼리를 최적으로 실행하기 위해 각 테이블의 데이터가 어떤 분포로 저장돼 있는지 통계 정보를 참조  
이런 기본 데이터를 비교해 최적 실행 계획을 수립하는 작업 필수  

<br>

## 개요

### 쿼리 실행 절차
쿼리가 실행되는 과정은 아래와 같이 분류 가능  
1.  사용자로부터 요청된 SQL 문장을 분리(파스 트리)  
2.  파스 트리를 확인하면서 어떤 테이블로부터 어떤 인덱스를 읽을지 선택  
3.  결정된 읽기 순서와 인덱스를 이용해 스토리지 엔진으로부터 데이터 조회  

<br>

첫번째 단계를 `SQL 파싱`이라고 하며 `SQL 파서`라는 모듈로 처리  
해당 과정으로 `SQL 파스 트리`가 생성되고 문법적 오류를 검사  
MySQL 서버는 SQL 문장이 아닌 파스 트리로 쿼리를 실행  

<br>

두번쨰 단계에서 파스 트리를 이용해 아래 내용 처리
- 불필요한 조건 제거 및 복잡한 연산 단순화  
- 여러 테이블의 조인이 있는 경우 어떤 순서로 테이블을 읽을지 결정  
- 각 테이블에 사용된 조건과 인덱스 통계 정보를 이용해 사용할 인덱스를 결정  
- 가져온 레코드들을 임시 테이블에 넣고 다시 한번 가공해야 하는지 결정  

해당 단계를 `최적화 및 실행 계획 수립`이라고 하며 `옵티마이저`에서 처리  
해당 과정으로 `실행 계획`이 생성  

<br>

세번째 단계는 수립된 실행 계획대로 스토리지 엔진에 레코드를 읽어오도록 요청  
MySQL 엔진은 스토리지 엔진을 통해 받아온 레코드를 조인하거나 정렬하는 작업을 추가로 수행  
해당 단계는 MySQL과 스토리지 엔진이 동시에 참여해서 처리  

<br>

### 옵티마이저의 종류
비용 기반 최적화(`CBO, Cost-based optimizer`) 방식과 규칙 기반 최적화(`RBP, Rule-based optimizer`) 방식으로 분류  
현재는 대부분의 RDBMS가 비용 기반 옵티마이저를 채택  
- 규칙 기반 최적화  
  기본적으로 대상 테이블의 레코드 건수나 선택도 등을 고려하지 않고 옵티마이저에 내장된 우선순위에 따라 실행 계획 수립  
  통계 정보를 조사하지 않고 실행 계획이 수립되어 같은 쿼리에 대해서 거의 항상 같은 실행 계획 생성  
  하지만 사용자의 데이터 분포도가 다양하기 때문에 이미 오래전부터 거의 사용되지 않음  
  
- 비용 기반 최적화  
  쿼리를 처리하기 위한 여러 가지 실행 계획을 수립  
  각 단위 작업의 비용 정보와 대상 테이블의 예측된 통계 정보를 이용해 실행 계획별 비용 산출  
  이 중 가장 최소로 소요되는 처리 방식을 선택해서 최종적으로 쿼리 실행  

<br>

## 기본 데이터 처리

### 풀 테이블 스캔과 풀 인덱스 스캔
MySQL 옵티마이저는 아래 조건이 일치할 때 주로 풀 테이블 스캔을 선택  
- 테이블 레코드 건수가 너무 작은 경우(일반적으로 테이블이 페이지 1개로 구성된 경우)  
- WHERE 절이나 ON 절에 인덱스를 이용할 수 있는 적절한 조건이 없는 경우  
- 인덱스 레인지 스캔 가능 쿼리라도 옵티마이저가 판단한 조건 일치 레코드 건수가 너무 많은 경우(인덱스 샘플링을 통한 통계 정보 기준)  

<br>

InnoDB 스토리지 엔진은 테이블의 연속된 데이터 페이지가 읽히면 백그라운드 스레드에 의해 리드 어헤드 작업(`read ahead`) 자동 수행  
어떤 영역의 데이터가 앞으로 필요해지리라는 것을 예측해서 요청 전에 미리 디스크에서 읽어 버퍼풀에 적재하는 것  
즉, 풀 테이블 스캔이 실행되면 처음 데이터 페이지는 포그라운드 스레드가 페이지 읽기를 실행하지만 특정 시점부터 백그라운드 스레드로 이월  
백그라운드 스레드가 읽기 작업을 넘겨받는 시점부터 4개 또는 8개씩 페이지를 읽으면서 그 수를 계속 증가  
이때 한번에 64개 데이터 페이지까지 읽어서 버퍼풀에 적재  

<br>

`innodb_read_ahead_threshold` 시스템 변수값을 통해 리드 어헤드 시작 임계값 설정  
해당 값만큼 연속된 데이터 페이지가 포그라운드 스레드로 읽히면, 백그라운드 스레드를 이용해 대량으로 그 다음 페이지들을 읽어서 버퍼풀로 적재  
일반적으로 디폴트 설정으로 충분하지만 웨어하우스용으로 사용한다면 이 값을 낮게 설정해서 더 빨리 리드 어헤드 시작을 유도 가능  
리드 어헤드는 풀 테이블 스캔이 아닌 풀 인덱스 스캔에서도 동일하게 사용  

<br>

```sql
SELECT COUNT(*) FROM employees;
```

해당 쿼리는 풀 테이블 스캔할 것처럼 예상되지만 실제 실행 계획은 풀 인덱스 스캔을 하게 될 가능성이 높음  
단순히 레코드 건수만 필요로 하는 쿼리라면 용량이 작은 인덱스를 선택  

<br>

```sql
SELECT * FROM employeees;
```

해당 쿼리는 레코드에만 있는 칼럼이 필요해서 풀 인덱스 스캔을 활용하지 못하고 풀 테이블 스캔을 수행  

<br>

### 병렬 처리
8.0 버전부터 용도가 한정돼 있지만 처음으로 쿼리 병렬 처리 기능 지원  
하나의 쿼리를 여러 스레드가 작업을 분할해서 동시 처리하는 것을 의미  
`innodb_parallel_read_threads` 시스템 변수값을 통해 최대 몇 개의 스레드로 처리할지 설정  
아직 병렬로 처리하게 하는 힌트나 옵션은 존재하지 않고, 단순히 조건절 없이 테이블의 전체 건수를 가져오는 쿼리만 병렬 처리 가능  
하지만 병렬 처리용 스레드가 증가해도 서버에 장착된 CPU 코어 갯수를 넘어서는 경우 오히려 성능이 떨어질 가능성 존재  

```
mysql> SET SESSION innodb_parallel_read_threads = 1;
mysql> SELECT COUNT(*) FROM salaries;
1 row in set (0.32 sec)

mysql> SET SESSION innodb_parallel_read_threads = 2;
mysql> SELECT COUNT(*) FROM salaries;
1 row in set (0.29 sec)

mysql> SET SESSION innodb_parallel_read_threads = 4;
mysql> SELECT COUNT(*) FROM salaries;
1 row in set (0.18 sec)

mysql> SET SESSION innodb_parallel_read_threads = 8;
mysql> SELECT COUNT(*) FROM salaries;
1 row in set (0.13 sec)
```

<br>
