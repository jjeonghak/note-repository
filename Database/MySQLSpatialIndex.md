# 공간 검색
공간 데이터 관리 기능은 다른 RDBMS보다 늦은 편  
8.0 버전부터 빠르게 많은 기능을 보완  

<br>

## 용어 설명
- `OGC(Open Geospatial Consortium)`  
위치 기반 데이터에 대한 표준을 수립하는 단체  

- `OpenGIS`  
`OGC`에서 제정한 지리 정보 시스템(`GIS, Geographic Information System`) 표준으로, 정보 데이터를 표기 및 저장하는 방법
`OpenGIS` 표준을 준수한 응용 프로그램의 위치 기반 데이터는 상호 변환없이 교환 가능하도록 설계  

- `SRS`, `GCS`, `PCS`  
`SRS(Spatial Reference System)`는 좌표계와 유사  
`GCS(Geographic Coordinate System)`와 `PCS(Projected Coordinate System)`으로 구분  
`GCS`(지리 좌표계)는 지구 구체상의 특정 위치나 공간을 표현하는 좌표계를 의미, 흔히 위도와 경도 같은 `각도` 단위의 숫자로 표시  
`PCS`(투영 좌표계)는 구체 형태의 지구를 평면으로 투영시킨 좌표계를 의미, 주로 `미터` 같은 선형적인 단위로 표시  

- `SRID`, `SRS-ID`  
`SRID(Spatial Reference ID)` 또는 `SRS-ID`는 특정 `SRS` 고유번호 의미  

- `WKT`, `WKB`  
`WKT(Well-Known Text format)`와 `WKB(Well-Known Binary format)`는 `OpenGIS`에서 명시한 위치 좌표 표현 방법
텍스트 또는 이진 포맷으로 저장하는 표준  

<br>

## SRS(Spatial Reference System)
MySQL 서버에서 지원하는 SRS 정보 조회 가능  
8.0 이전 버전에 사용하던 데이터는 모두 `SRID=0`으로 자동 인식  
지원되는 공간 함수들이 대부분 `SRID=0`인 경우에만 작동하며, 일부만 `WGS84` 좌표계 데이터 처리 가능  
`ST_` 접두사를 가지는 공간 데이터 함수들이 `OpenGIS` 표준을 준수해서 만들어진 함수  

```
mysql> DESC information_schema.ST_SPATIAL_REFERENCE_SYSTEMS;
+--------------------------+---------------+------+-----+---------+-------+
| Field                    | Type          | Null | Key | Default | Extra |
+--------------------------+---------------+------+-----+---------+-------+
| SRS_NAME                 | varchar(80)   | NO   |     | NULL    |       |
| SRS_ID                   | int unsigned  | NO   |     | NULL    |       |
| ORGANIZATION             | varchar(256)  | YES  |     | NULL    |       |
| ORGANIZATION_COORDSYS_ID | int unsigned  | YES  |     | NULL    |       |
| DEFINITION               | varchar(4096) | NO   |     | NULL    |       |
| DESCRIPTION              | varchar(2048) | YES  |     | NULL    |       |
+--------------------------+---------------+------+-----+---------+-------+
```

<br>

`GEOGCS`는 지리 좌표계, `PROJCS`는 투영 좌표계 의미  
MySQL 서버는 대략 지리 좌표계 483개, 투영 좌표계 4668개 지원  
실제 특정 나라, 지역을 위한 좌표계는 평면으로 투영해도 오차가 크게 발생하지 않기 때문  

```
mysql> SELECT * FROM information_schema.ST_SPATIAL_REFERENCE_SYSTEMS WHERE SRS_ID = 4326 \G
*************************** 1. row ***************************
                SRS_NAME: WGS 84
                  SRS_ID: 4326
            ORGANIZATION: EPSG
ORGANIZATION_COORDSYS_ID: 4326
              DEFINITION: GEOGCS["WGS 84",DATUM["World Geodetic System 1984",
                          SPHEROID["WGS 84",6378137,298.257223563,
                          AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],
                          PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],
                          UNIT["degree",0.017453292519943278,AUTHORITY["EPSG","9122"]],
                          AXIS["Lat",NORTH],AXIS["Long",EAST],AUTHORITY["EPSG","4326"]]
             DESCRIPTION:
```

<br>

지리 좌표계의 DEFINITION 칼럼에 AXIS가 두 번 표시되는데, 위도와 경도 순서로 나열  
해당 좌표계를 사용하는 특정 위치는 `POINT(위도 경도)`와 같이 표현  

```
mysql> SELECT ST_X(ST_PointFromText('POINT(37.544738 127.039074)', 4326)) AS coord_x;
+-----------+
| coord_x   |
+-----------+
| 37.544738 |
+-----------+

mysql> SELECT ST_Latitude(ST_PointFromText('POINT(37.544738 127.039074)', 4326)) AS coord_latitude;
+----------------+
| coord_latitude |
+----------------+
|      37.544738 |
+----------------+

-- // SRID 값이 0인 데이터의 경우는 ST_X(), ST_Y() 함수만 사용 가능
mysql> SELECT ST_Latitude(ST_PointFromText('POINT(10 20)', 0)) AS coord_latitude;
ERROR 3726 (22S00): Function st_latitude is only defined for geographic spatial reference
systems, but one of its arguments is in SRID 0, which is not geographic
```

<br>

투영 좌표계의 DEFINITION 칼럼에 AXIS가 두 번 표시되는데, 경도와 위도 순서로 나열  
해당 좌표계를 사용하는 특정 위치는 `POINT(경도 위도)`와 같이 표현  

```
mysql> SELECT * FROM information_schema.ST_SPATIAL_REFERENCE_SYSTEMS WHERE SRS_ID = 3857 \G
*************************** 1. row ***************************
                SRS_NAME: WGS 84 / Pseudo-Mercator
                  SRS_ID: 3857
            ORGANIZATION: EPSG
ORGANIZATION_COORDSYS_ID: 3857
              DEFINITION: PROJCS["WGS 84 / Pseudo-Mercator",
                            GEOGCS["WGS 84",
                            DATUM["World Geodetic System 1984",
                            SPHEROID["WGS 84",6378137,298.257223563,AUTHORITY["EPSG","7030"]],
                            AUTHORITY["EPSG","6326"]],
                          PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],
                          UNIT["degree",0.017453292519943278,AUTHORITY["EPSG","9122"]],
                          AXIS["Lat",NORTH],AXIS["Lon",EAST],AUHTORITY["EPSG","4326"]],
                          PROJECTION["Popular Visualisation Pseudo Mercator",AUTHORITY["EPSG","1024"]],
                          PARAMETER["Latitude of natural origin",0,AUTHORITY["EPSG","8801"]],
                          PARAMETER["Longitude of natural origin",0,AUTHORITY["EPSG","8802"]],
                          PARAMETER["False easting",0,AUTHORITY["EPSG","8806"]],
                          PARAMETER["False northing",0,AUTHORITY["EPSG","8807"]],
                          UNIT["meter",1,AUTHORITY["EPSG","9001"]],
                          AXIS["X",EAST],AXIS["Y",NORTH],AUTHORITY["EPSG","3857"]]
DESCRIPTION: NULL
```

<br>

8.0 버전에서 공간 데이터를 저장할때 SRID 지정하는 것은 문자열 타입의 문자셋, 콜레이션과 비슷한 수준  
`SRID=0`인 공간 좌표계산은 아무런 단위없이 단순히 피타고라스 정리에 의한 수식 계산  

```
-- // 평면 좌표계(SRID=0)를 사용하는 공간 데이터
mysql> SELECT ST_Distance(ST_PointFromText('POINT(0 0)', 0),
                          ST_PointFromText('POINT(1 1)', 0)) AS distance;
+--------------------+
| distance           |
+--------------------+
| 1.4142135623730951 |
+--------------------+

-- // 웹 기반 지도 좌표계(SRID=3857)를 사용하는 공간 데이터
mysql> SELECT ST_Distance(ST_PointFromText('POINT(0 0)', 3857),
                          ST_PointFromText('POINT(1 1)', 3857)) AS distance;
+--------------------+
| distance           |
+--------------------+
| 1.4142135623730951 |
+--------------------+

-- // WGS 84 지리 좌표계(SRID=4326)를 사용하는 공간 데이터
mysql> SELECT ST_Distance(ST_PointFromText('POINT(0 0)', 4326),
                          ST_PointFromText('POINT(1 1)', 4326)) AS distance;
+--------------------+
| distance           |
+--------------------+
| 156897.79947260793 |
+--------------------+
```

<br>

## 투영 좌표계와 평면 좌표계
MySQL 서버에서는 투영 좌표계나 지리 좌표계에 속하지 않는 평면 좌표계 존재  
평면 좌표계(`SRID=0`)와 대표적인 투영 좌표계(`SRID=3857`)는 거의 차이가 없음  
평면 좌표계는 단위를 가지지 않고 값의 제한이 없기 때문에 무한 평면 좌표계라고도 표현  
평면 좌표계와 투영 좌표계는 모두 피타고라스 정리 수식에 의해서 좌표간 거리 계산  
























