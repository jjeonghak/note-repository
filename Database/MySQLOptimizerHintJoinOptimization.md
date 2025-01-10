# 고급 최적화
실행 계획을 수립할 때 통계 정보와 옵티마이저 옵션을 결합해서 최적의 실행 계획 수립  
조인 관련 옵티마이저 옵션과 옵티마이저 스위치로 구분 가능  

<br>

## 조인 최적화 알고리즘
조인 쿼리의 실행 계획 최적화를 Exhaustive 검색 알고리즘과 Greedy 검색 알고리즘 존재  
하나의 쿼리에서 조인되는 테이블의 개수가 많아지면 실행 계획을 수립하는데 많은 시간 소요  

<br>

### Exhaustive 검색 알고리즘

```sql
SELECT * FROM t1, t2, t3, t4 WHERE ...
```

<img width="550" alt="exhaustive" src="https://github.com/user-attachments/assets/60fbed04-ccc4-40e2-aac1-8647f205d216" />

5.0 이전 버전에서 사용되던 조인 최적화 기법  
FROM 절에 명시된 모든 테이블의 조합에 대해 실행 계획 비용을 계산해서 최적의 조합 하나를 찾는 방법  
테이블이 n개라면 가능한 조인 조합은 모두 n!  

<br>

### Greedy 검색 알고리즘

<img width="600" alt="greedy" src="https://github.com/user-attachments/assets/2f1c737f-c0cb-4381-baff-c8962dd949e1" />

Exhaustive 알고리즘의 시간 소모적인 문제점을 해결하기 위해 5.0 버전부터 도입된 조인 최적화 기법  

1. 전체 n개의 테이블 중에서 `optimizer_search_depth` 시스템 설정 변수에 정의된 개수의 테이블로 가능한 조인 조합 생성
2. 1번에서 생성된 조인 조합 중 최소 비용 실행 계획 하나 선정
3. 2번에서 선정된 실행 계획의 첫번째 테이블을 부분 실행 계획의 첫번쨰 테이블로 선정
4. 전체 n - 1개 테이블 중 `optimizer_search_depth` 시스템 설정 변수에 정의된 개수의 테이블로 가능한 조인 조합 생성
5. 4번에서 생성된 조인 조합들을 하나씩 3번에서 생성된 부분 실행 계획에 대입해 실행 비용 계산
6. 5번의 비용 계산 결과, 최적의 실행 계획에서 두번째 테이블을 3번에서 생성된 부분 실행 계획의 두번째 테이블로 선정
7. 남은 테이블이 모두 없어질 때까지 4 ~ 6번 과정을 반복 실행
8. 최종적으로 부분 실행 계획이 테이블의 조인 순서로 결정

<br>

`optimizer_search_depth` 시스템 변수에 설정된 값에 따라 조인 최적화 비용이 감소, 기본값 62  
이외에도 조인 최적화를 위해 `optimizer_prune_level` 시스템 변수 제공  

- `optimizer_search_depth` 시스템 변수는 Greedy 알고리즘과 Exhaustive 검색 알고리즘 중 어떤 알고리즘을 사용할지 결정  
  `0 ~ 62`까지 정수값을 설정가능, 설정된 개수로 한정해서 최적의 실행 계획 산출  
  0으로 설정한 경우 옵티마이저가 자동으로 결정  
  조인에 사용된 테이블의 개수가 설정값보다 크면 설정된 개수만큼의 테이블은 Exhaustive 검색이 사용, 나머지만 Greedy 처리  
  조인에 사용된 테이블의 개수가 설정값보다 작으면 Exhaustive 검색만 사용  
  만약 `optimizer_prune_level` 시스템 변수값이 0인 경우, `optimizer_search_depth` 값을 `4 ~ 5`로 설정  

- `optimizer_prune_level` 시스템 변수는 5.0 버전부터 추가된 Heuristic 검색이 작동하는 방식 제어  
  다양한 조인 순서의 비용을 계산하는 도중 이미 계산했던 조인 순서 비용보다 큰 경우 언제든지 중간에 포기 가능  
  `1`로 설정한 경우 Heuristic 최적화 적용, `0`인 경우 적용하지 않음  
  해당 값은 1로 설정하는 것을 권장  

<br>

```sql
SET SESSION optimizer_prune_level = { 0 | 1 };
SET SESSION optimizer_search_depth = { 1 | 5 | 10 | 15 | 20 | 25 | 30 | 35 | 40 | 62 };

EXPLAIN
  SELECT *
  FROM tab01, tab02, tab03, tab04, tab05, tab06, tab07, tab08, tab09, tab010,
       tab011, tab012, tab013, tab014, tab015, tab016, tab017, tab018, tab019, tab020,
       tab021, tab022, tab023, tab024, tab025, tab026, tab027, tab028, tab029, tab030
  WHERE tab01.fd1 = tab02.fd1
    AND tab02.fd1 = tab03.fd2 AND tab03.fd1 = tab04.fd2 AND tab04.fd2 = tab05.fd1
    AND tab05.fd2 = tab06.fd1 AND tab06.fd2 = tab07.fd2 AND tab07.fd1 = tab08.fd1
    AND tab08.fd2 = tab09.fd1 AND tab09.fd1 = tab10.fd2 AND tab10.fd1 = tab11.fd2
    AND tab11.fd2 = tab12.fd1 AND tab12.fd2 = tab13.fd2 AND tab13.fd1 = tab14.fd1
    AND tab14.fd2 = tab15.fd1 AND tab15.fd1 = tab16.fd2 AND tab16.fd1 = tab17.fd1
    AND tab17.fd2 = tab18.fd2 AND tab18.fd1 = tab19.fd1 AND tab19.fd2 = tab20.fd2
    AND tab20.fd1 = tab21.fd1 AND tab21.fd2 = tab22.fd2 AND tab22.fd1 = tab23.fd1
    AND tab23.fd2 = tab24.fd2 AND tab24.fd1 = tab25.fd2 AND tab25.fd1 = tab26.fd2
    AND tab26.fd1 = tab27.fd2 AND tab27.fd1 = tab28.fd1 AND tab28.fd2 = tab29.fd1
    AND tab29.fd2 = tab30.fd2;
```

- `optimizer_prune_level` 시스템 변수값이 1인 경우  
  `optimizer_search_depth` 시스템 변수값을 변화시키면서 쿼리의 실행 계획 수립 시간 확인 결과는 거의 차이없이 0.01초 이내 완료  
  
- `optimizer_prune_level` 시스템 변수값이 0인 경우  
  `optimizer_search_depth` 시스템 변수값 15 이상부터 실행 계획 수립에만 너무 많은 시간이 소요  

  <img width="450" alt="heuristic" src="https://github.com/user-attachments/assets/41f4fceb-81d1-4fdc-beed-39b88e45fea7" />

<br>
