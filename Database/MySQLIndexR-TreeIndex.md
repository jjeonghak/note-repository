# 인덱스
인덱스 특성과 치이는 물리 수준 모델링에 중요한 요소  
기존 MyISAM 스토리지 엔진에서만 제공하던 전문 검색, 위치 기반 검색 기능도 지원  
쿼리 튜닝의 기본  

<br>

## R-Tree 인덱스
공간 인덱스를 생성할때 사용하고, 2차원 데이터를 인덱싱/검색 목적  
내부 메커니즘은 B-Tree와 흡사하지만 인덱스를 구성하는 칼럼이 `1 차원 스칼라값`이 아닌 `2차원 공간 개념값`  

`GIS`와 `GPS` 기반 서비스를 구현하기 위해 공간 확장(`Spatial Extension`) 활용 가능  
- 공간 데이터를 저장할 수 있는 데이터 타입
- 공간 데이터의 검색을 위한 공간 인덱스(R-Tree 알고리즘)
- 공간 데이터의 연산 함수

<br>

### 구조 및 특성

<img width="400" alt="mbr" src="https://github.com/user-attachments/assets/1f900306-5db7-469b-a71c-bf1345190b1e" />

기하학적 도형(`Geometry`) 정보를 관리할 수 있는 데이터 타입 제공  
`MBR(Minimum Bounding Rectangle)`이란 도형을 감싸는 최소 크기의 사각형  
이 사각형들의 포함 관계를 B-Tree 형태로 구현한 인덱스가 R-Tree 인덱스  

<br>

<img width="400" alt="spatialdata" src="https://github.com/user-attachments/assets/707772b7-c487-489c-aa8d-285451612213" />

<br>

<img width="400" alt="spatialdatambr" src="https://github.com/user-attachments/assets/e87728be-67a8-4e91-bc0b-c3fa46bf74aa" />

도형들을 MBR 3개의 레벨로 분리 가능  
- 최상위 레벨: R1 ~ R2
- 차상위 레벨: R3 ~ R6
- 최하위 레벨: R7 ~ R14

<br>

<img width="600" alt="mbrrtree" src="https://github.com/user-attachments/assets/f3f3848b-0583-4f4f-b755-73fa20a04de7" />

최상위 MBR은 R-Tree의 루트 노드에 저장되는 정보  
차상위 MBR은 브랜치 노드에 저장  
최하위 MBR은 리프 노드에 저장  

<br>

### R-Tree 인덱스의 용도
일반적으로 `WGS84(GPS)` 기준의 위도, 경도 좌표 저장에 주로 사용  
포함관계를 이용해 만들어진 인덱스로 `ST_Contains()` 또는 `ST_Within()` 등과 같은 포함관계 비교 함수 검색만 인덱스 사용 가능  
지금 버전에서는 거리를 비교하는 `ST_Distance()`와 `ST_Distance_Sphere()` 함수는 효율적으로 인덱스 사용 불가  

<br>

<img width="400" alt="distancedrivensearch" src="https://github.com/user-attachments/assets/bfadb941-e4ef-4114-ac99-d4926ad780d4" />

가운데 위치한 `P`가 기준점  
기준점으로부터 반경 거리 5km 이내의 점들을 검색하려면 우선 사각 점선의 상자에 포함된 점들을 검색  
P6 같은 반경안에 없는 결과를 조회하려면 추가 비교 필요  

```sql
SELECT * FROM tb_location WHERE ST_Contains(사각 상자, px);
SELECT * FROM tb_location WHERE ST_Within(px, 사각 상자);

SELECT * FROM tb_location WHERE ST_Contains(사각 상자, px) AND ST_Distance_Sphere(p, px) <= 5 * 1000
```

<br>
