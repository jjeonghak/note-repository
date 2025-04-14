# 데이터 타입
칼럼의 데이터 타입과 길이를 선정할 때 아래 사항을 주의  
- 저장되는 값의 성격에 맞는 최적의 타입 선정
- 가변 길이 칼럼은 최적의 길이를 지정
- 조인 조건으로 사용되는 칼럼은 똑같은 데이터 타입으로 선정

<br>

## 공간 데이터 타입
MySQL 서버는 OpenGIS 표준을 준수하고, WKT 또는 WKB를 이용해 공간 데이터 관리 지원  
데이터 타입은 `POINT`, `LINESTRING`, `POLYGON`, `GEOMETRY`, `MULTIPOINT`, `MULTILINESTRING`, `MULTIPOLYGON`, `MULTITRYCOLLECTION`  

<br>

<img width="650" alt="spatialdatatype" src="https://github.com/user-attachments/assets/8419beb9-a4ae-426c-ac45-239fec4f518c" />

`POINT`, `LINESTRING`, `POLYGON` 타입은 하나의 단위 정보만 보유 가능  
`GEOMETRY` 타입은 위의 타입들의 슈퍼 타입으로, 3개의 타입의 객체 모두 저장 가능, 단 저장은 하나만 가능  

`MULTIPOINT`, `MULTILINESTRING`, `MULTIPOLYGON` 타입은 종류별로 여러 개의 객체 저장 가능  
`GEOMETRYCOLLECTION` 타입은 위의 타입들의 슈퍼 타입  

<br>

`GEOMETRY` 타입과 모든 자식 타입은 메모리, 디스크에서 `BLOB` 객체로 관리되고, 클라이언트로 전솔될 때도 `BLOB`으로 전송  
즉, `GEOMETRY` 타입은 `BLOB` 타입을 감싸고 있는 구조  
JDBC 표준에서는 아직 공간 데이터를 공식적으로 지원하지 않아 자바 클래스로 사용 불가  
그래서 ORM 라이브러리들은 `JTS` 같은 오픈소스 공간 데이터 라이브러리를 활용  

<br>

### 공간 데이터 생성
```
KT 포맷: POINT(x y)
객체 생성: ST_PointFromText('POINT(x y)', SRID)

KT 포맷: LINESTRING(x0 y0, x1 y1, x2 y2, x3 y3, ...)
객체 생성: ST_LineStringFromText('LINESTRING(x0 y0, x1 y1, x2 y2, x3 y3, ...)', SRID)

KT 포맷: POLYGON(x0 y0, x1 y1, x2 y2, x3 y3) 
객체 생성: ST_PolygonFromText('POLYGON(x0 y0, x1 y1, x2 y2, x0 y0)', SRID)

KT 포맷: MULTIPOINT(x0 y0, x1 y1, x2 y2)
객체 생성: ST_MultiPointFromText('MULTIPOINT(x0 y0, x1 y1, x2 y2)', SRID)

KT 포맷: MULTILINESTRING((x0 y0, x1 y1), (x2 y2, x3 y3))
객체 생성: ST_MultiLineStringFromText('MULTILINESTRING((x0 y0, x1 y1), (x2 y2, x3 y3))', SRID)

KT 포맷: MULTIPOLYGON(((x0 y0, x1 y1, x2 y2, x3 y3, x0 y0)),
                     ((x4 y4, x5 y5, x6 y6, x7 y7, x4 y4)))
객체 생성: ST_MultiPolygonFromText('MULTIPOLYGON(((x0 y0, x1 y1, x2 y2, x3 y3, x0 y0)),
                                               ((x4 y4, x5 y5, x6 y6, x7 y7, x4 y4)))', SRID)

KT 포맷: GEOMETRYCOLLECTION(POINT(x0 y0), POINT(x1 y1), LINESTRING(x2 y2, x3 y3))
객체 생성: ST_GeometryCollectionFromText('GEOMETRYCOLLECTION(POINT(x0 y0),
                                                           POINT(x1 y1),
                                                           LINESTRING(x2 y2, x3 y3))', SRID)
```

<br>

### 공간 데이터 조회
- 이진 데이터 조회(WKB 또는 이진 포맷)
- 텍스트 데이터 조회(WKT)
- 공간 데이터 속성 함수를 이용한 조회

<br>

```
mysql> SELECT id,
              location AS internal_format,
              ST_AsText(location) AS wkt_format,
              ST_AsBinary(location) AS wkb_format
       FROM plain_coord \G
*************************** 1. row ***************************
             id: 1
internal_format: 0x0000000001010000000000000000000000000000000000000
     wkt_format: POINT(0 0)
     wkb_foramt: 0x010100000000000000000000000000000000000000
```

<br>

- POINT 타입 속성 함수

```
mysql> SET @poi:=ST_PointFromText('POINT(37.544738 127.039074)', 4326);
mysql> SELECT
         ST_SRID(@poi) AS srid,
         ST_X(@poi) AS coord_x,
         ST_Y(@poi) AS coord_y,
         ST_Latitude(@poi) AS coord_latitude,
         ST_Longitude(@poi) AS coord_longitude;
+------+-----------+--------------------+----------------+--------------------+
| srid | coord_x   | coord_y            | coord_latitude | coord_longitude    |
+------+-----------+--------------------+----------------+--------------------+
| 4326 | 37.544738 | 127.03907400000001 |      37.544738 | 127.03907400000001 |
+------+-----------+--------------------+----------------+--------------------+
```

<br>

- LINESTRING과 MULTILINESTRING 타입 속성 함수

```
mysql> SET @line:=ST_LineStringFromText('LINESTRING(37.55601011174991 127.03600689589169,
                                                    37.55601011174991 127.05866710410828,
                                                    37.53804388825009 127.05866710410828,
                                                    37.53804388825009 127.03600689589169)');
mysql> SELECT
         ST_AsText(ST_StartPoint(@line)),
         ST_AsText(ST_EndPoint(@line)),
         ST_AsText(ST_PointN(@line, 2)),
         ST_IsClosed(@line),
         ST_Length(@line),
         ST_NumPoints(@line) \G
*************************** 1. row ***************************
ST_AsText(ST_StartPoint(@line)): POINT(37.55601011174991 127.03600689589169)
  ST_AsText(ST_EndPoint(@line)): POINT(37.53804388825009 127.03600689589169)
 ST_AsText(ST_PointN(@line, 2)): POINT(37.55601011174991 127.05866710410828)
             ST_IsClosed(@line): 0
               ST_Length(@line): 0.0632866399330112
            ST_NumPoints(@line): 4
```

<br>

평면 상의 거리가 아닌 구면체상의 거리는 `ST_Length()` 함수가 아닌 `ST_Distance_Sphere()` 함수 사용  

```sql
SET @p1:=ST_PointFromText('POINT(37.55601011174991 127.03600689589169)', 4236);
SET @p2:=ST_PointFromText('POINT(37.55601011174991 127.05866710410828)', 4236);

## 2002.3302054281864
SELECT ST_Distance(@p1, @p2);
```

<br>

- POLYGON과 MULTIPOLYGON 속성 함수

```
mysql> SET @polygon:=ST_PolygonFromText('POLYGON((37.55601011174991 127.03600689589169,
                                                  37.55601011174991 127.05866710410828,
                                                  37.53804388825009 127.05866710410828,
                                                  37.53804388825009 127.03600689589169,
                                                  37.55601011174991 127.03600689589169))', 4326);
mysql> SELECT
         ST_Area(@polygon),
         ST_AsText(ST_ExteriorRing(@polygon)),
         ST_AsText(ST_InteriorRingN(@polygon, 1)),
         ST_NumInteriorRing(@polygon),
         ST_NumInteriorRings(@polygon);
*************************** 1. row ***************************
                       ST_Area(@polygon): 3993026.2901834054
    ST_AsText(ST_ExteriorRing(@polygon)): LINESTRING(37.55601011174991 127.03600689589169,
                                                     37.55601011174991 127.05866710410828,
                                                     37.53804388825009 127.05866710410828,
                                                     37.53804388825009 127.03600689589169,
                                                     37.55601011174991 127.03600689589169)
ST_AsText(ST_InteriorRingN(@polygon, 1)): NULL
            ST_NumInteriorRing(@polygon): 0
           ST_NumInteriorRings(@polygon): 0
```

<br>
