# 실행 계획

대부분의 DBMS는 많은 데이터를 안전하게 저장하고 빠르게 조회하는 것이 목적  
옵티마이저가 항상 최적의 실행 계획을 수립하지 못하기 때문에 사용자가 보완 가능하도록 `EXPLAIN` 명령 지원  

<br>

## 통계 정보
5.7 버전까지 테이블과 인덱스에 대한 개괄적인 정보를 가지고 실행 계획 수립  
8.0 버전부터 인덱싱되지 않은 칼럼들에 대해서도 데이터 분포도 수집하는 히스토그램 정보 도입  

<br>

### 테이블 및 인덱스 통계 정보
비용 기반 최적화에서 가장 중요한 것은 통계 정보  
MySQL 서버는 쿼리 실행 계획 수립할때 실제 테이블 데이터 일부를 분석해서 통계 정보 보완  

<br>

### MySQL 서버의 통계 정보
5.6 버전부터 InnoDB 스토리지 엔진을 사용하는 테이블 통계 정보는 영구적으로 관리 가능  
이전까지는 메모리에만 보관했기 때문에 재시작시 통계 정보 상실  

```
mysql> SHOW TABLES LIKE '%_stats';
+---------------------------+
| Tables_in_mysql (%_stats) |
+---------------------------+
| innodb_index_stats        |
| innodb_table_stats        |
+---------------------------+
```

<br>

테이블을 생성할 때 `STATS_PERSISTENT` 옵셜 설정 가능  
설정값에 따라 통계 정보를 영구적으로 관리할지 결정  
테이블 통계 정보를 조회할때 영구적 통계 정보만 조회 가능  

```
mysql> CREATE TABLE tab_persistent (fd1 INT, fd2 VARCHAR(20), PRIMARY KEY(fd1))
         ENGINE=InnoDB STATS_PERSISTENT=1;
mysql> CREATE TABLE tab_transient (fd1 INT, fd2 VARCHAR(20), PRIMARY KEY(fd1))
         ENGINE=InnoDB STATS_PERSISTENT=0;

mysql> SELECT * FROM mysql.innodb_table_stats
         WHERE table_name IN ('tab_persistent', 'tab_transient') \G
*************************** 1. row ***************************
           database_name: test
              table_name: tab_persistent
             last_update: 2013-12-28 17:11:30
                  n_rows: 0
    clustered_index_size: 1
sum_of_other_index_sizes: 0
```

<br>

테이블이 이미 생성된 이후에도 통계정보를 영구적 또는 단기적으로 변경 가능  

```
mysql> ALTER TABLE employees.employees STATS_PERSISTENT=1;
mysql> SELECT *
         FROM innodb_index_stats
         WHERE database_name = 'employees'
           AND TABLE_NAME = 'employees';
+--------------+--------------+------------+-------------+-----------------------------------+
| index_name   | stat_name    | stat_value | sample_size | stat_description                  |
+--------------+--------------+------------+-------------+-----------------------------------+
| PRIMARY      | n_diff_pfx01 |     299202 |          20 | emp_no                            |
| PRIMARY      | n_leaf_pages |        886 |        NULL | Number of leaf pages in the index |
| PRIMARY      | size         |        929 |        NULL | Number of pages in the index      |
| ix_firstname | n_diff_pfx01 |       1313 |          20 | first_name                        |
| ix_firstname | n_diff_pfx02 |     294090 |          20 | first_name, emp_no                |
| ix_firstname | n_leaf_pages |        309 |        NULL | Number of leaf pages in the index |
| ix_firstname | size         |        353 |        NULL | Number of pages in the index      |
| ix_hiredate  | n_diff_pfx01 |       5128 |          20 | hire_date                         |
| ix_hiredate  | n_diff_pfx02 |     300069 |          20 | hire_date, emp_no                 |
| ix_hiredate  | n_leaf_pages |        231 |        NULL | Number of leaf pages in the index |
| ix_hiredate  | size         |        289 |        NULL | Number of pages in the index      |
+--------------+--------------+------------+-------------+-----------------------------------+

mysql> SELECT *
         FROM innodb_table_stats
         WHERE database_name = 'employees'
           AND TABLE_NAME = 'employees';
+--------+----------------------+--------------------------+
| n_rows | clustered_index_size | sum_of_other_index_sizes |
+--------+----------------------+--------------------------+
| 299202 |                  929 |                      642 |
+--------+----------------------+--------------------------+
```

통계 정보의 각 칼럼은 아래와 같은 정보  
- `innodb_index_stats.stat_name = 'n_diff_pfx%'`: 인덱스가 가진 유니크한 값의 개수
- `innodb_index_stats.stat_name = 'n_leaf_pages'`: 인덱스의 리프 노드 페이지 개수
- `innodb_index_stats.stat_name = 'size'`: 인덱스 트리의 전체 페이지 개수
- `innodb_index_stats.n_rows`: 테이블 전체 레코드 건수
- `innodb_index_stats.clustered_index_size`: 프라이머리 키 크기
- `innodb_index_stats.sum_of_other_index_sizes`: 프라이머리 키를 제외한 인덱스 크기

<br>

또한 `innodb_stats_auto_recalc` 시스템 설정 변수 값을 OFF로 설정해서 통계 정보 자동 갱신 방지 가능  
기본값은 ON이므로 영구적인 통계 정보를 원한다면 변경 필수  
- `STATS_AUTO_RECALC=1`: 테이블 통계 정보를 5.5 이전 방식대로 자동 수집  
- `STATS_AUTO_RECALC=0`: 테이블 통계 정보는 `ANALYZE TABLE` 명령을 실행할 때만 수집  

<br>

테이블 통계 정보를 수집할 때 몇 개의 테이블 블록 샘플링할지 결정 가능
- `innodb_stats_transient_sample_pages`  
  기본값은 8  
  자동으로 통계 정보 수집이 실행될 때 8개 페이지만 임의로 샘플링해서 분석  

- `innodb_stats_persistent_sample_pages`  
  기본값은 20  
  `ANALYZE TABLE` 명령이 실행될 때 임의로 20개 페이지만 샘플링해서 분석  
  그 결과를 영구적인 통계 정보 테이블에 저장  

<br>

### 히스토그램
























