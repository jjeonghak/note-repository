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

### SRS(Spatial Reference System)
MySQL 서버에서 지원하는 SRS 정보 조회 가능  

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

`WGS 84` 좌표계는 지구 전체를 구체 형태로 표현하는 지리 좌표계  
DEFINITION 칼럼에 AXIS가 두 번 표시되는데, 위도와 경도 순서로 나열  
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














