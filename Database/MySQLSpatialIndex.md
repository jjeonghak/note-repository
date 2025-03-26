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

```sql
## 평면 좌표계 사용 예제
CREATE TABLE plain_coord (
  id INT NOT NULL AUTO_INCREMENT,
  location POINT SRID 0,
  PRIMARY KEY(id)
);

INSERT INTO plain_coord VALUES (1, ST_PointFromText('POINT(0 0)'));
INSERT INTO plain_coord VALUES (1, ST_PointFromText('POINT(5 5)', 0));

## 투영 좌표계 사용 예제
CREATE TABLE projection_coord (
  id INT NOT NULL AUTO_INCREMENT,
  location POINT SRID 3857,
  PRIMARY KEY(id)
);

INSERT INTO projection_coord VALUES (1, ST_PointFromText('POINT(14133791.066622 4509381.876958)', 3857));
```

<br>

테이블을 생성할떄 SRID를 명식적으로 정의하지 않은 경우 모든 SRID 데이터 저장 가능  
하지만 이 경우는 인덱스를 이용한 빠른 검색 수행 불가  
마치 VARCHAR 타입 칼럼에 여러 콜레이션을 섞어서 저장해둔 것과 같은 결과  
만약 칼럼에 특정 좌표계를 명시한 경우, 다른 좌표계를 참조하는 공간 데이터를 저장하는 경우 에러 발생  

```
mysql> INSERT INTO plain_coord VALUES (2, ST_PointFromText('POINT(5 5)', 4326));
ERROR 3643 (HY000): The SRID of the geometry does not match the SRID of the column 'location'.
The SRID of the geometry is 4326, but the SRID of the column is 0. Consider changing the SRID
of the geometry or the SRID property of the column.
```

<br>

공간 데이터는 MySQL 서버가 내부적으로 사용하는 이진 포맷 데이터로 조회 가능  
`ST_AsWKB()` 함수의 결과값은 `WKB(Well Known Binary)` 포맷의 공간 데이터  
하지만 서버의 이진 데이터 포맷은 WKB 앞쪽에 SRID를 위한 4바이트 공간이 추가돼 있기 때문에 미세한 차이 존재  

```
mysql> SELECT id, location, ST_AsWKB(location) FROM plain_coord \G
*************************** 1. row ***************************
                id: 1
          location: 0x110FQ00001010000OO76C421E243F56A4172142078B1335141
ST_AsWKB(location): 0x010100000076C421E243F56A4172142078B1335141
*************************** 2. row ***************************
                id: 2
          location: 0x110F00000101000000F10EF02D44F56A417009C05D91255141
ST_AsWKB(location): 0x0101000000F10EF02D44F56A417009C05D91255141
```

<br>

눈으로 식별하기 위해서 `ST_AsText()` 함수를 사용해 이진 데이터를 `WKT` 포맷으로 변환  

```
mysql> SELECT id, ST_AsText(location) AS location_wkt, ST_X(location) AS location_x, ST_Y(location) AS location_y
       FROM projection_coord;
+----+---------------------------------------+-----------------+----------------+
| id | location_wkt                          | location_x      | location_y     |
+----+---------------------------------------+-----------------+----------------+
|  1 | POINT(14133791.066622 4509381.876958) | 14133791.066622 | 4509381.876958 |
|  2 | P0INT(14133793.435554 4494917.464846) | 14133793.435554 | 4494917.464846 |
+----+---------------------------------------+-----------------+----------------+
```

<br>

## 지리 좌표계

### 지리 좌표계 데이터 관리
공간 인덱스를 생성하는 칼럼은 반드시 NOT NULL  

```sql
CREATE TABLE sphere_coord (
  id INT NOT NULL AUTO_INCREMENT,
  name VARCHAR(20),
  location POINT NOT NULL SRID 4326,  -- // WGS84 좌표계
  PRIMARY KEY (id),
  SPATIAL INDEX sx_location(location)
);
```

<br>

공간 데이터를 검색하는 가장 일반적인 형태는 특정 위치를 기준으로 반경안의 데이터를 검색하는 작업  
지리 좌표계는 두 점의 거리를 `ST_Distance_Sphere()` 함수로 계산  

```
mysql> SELECT id, name, ST_AsText(location) AS location,
         ROUND(ST_Distance_Sphere(location, ST_PointFromText('POINT(37.547027 127.047337)', 4326))) AS distance_meters
       FROM sphere_coord
       WHERE ST_Distance_Sphere(location, ST_PointFromText('POINT(37.547027 127.047337)', 4326)) < 1000;
+----+--------------------+-----------------------------+-----------------+
| id | name               | location                    | distance_meters |
+----+--------------------+-----------------------------+-----------------+
|  1 | Seoulforest        | POINT(37.544738 127.039074) |             772 |
|  2 | Hanyang University | POINT(37.555363 127.044521) |             960 |
+----+--------------------+-----------------------------+-----------------+

mysql> EXPLAIN
         SELECT id, name, ST_AsText(location) AS location,
           ROUND(ST_Distance_Sphere(location, ST_PointFromText('POINT(37.547027 127.047337)', 4326))) AS distance_meters
         FROM sphere_coord
         WHERE ST_Distance_Sphere(location, ST_PointFromText('POINT(37.547027 127.047337)', 4326)) < 1000;
+----+-------------+--------------+------+------+------+-------------+
| id | select_type | table        | type | key  | rows | Extra       |
+----+-------------+--------------+------+------+------+-------------+
|  1 | SIMPLE      | sphere_coord | ALL  | NULL |    4 | Using where |
+----+-------------+--------------+------+------+------+-------------+
```

<br>

아직 인덱스를 이용한 반경 검색 기능은 지원하지 않음  
차선책으로 `MBR(Minimum Bounding Rectangle)`을 이용한 `ST_Within()` 함수를 이용  
우선 주어진 위치를 기준으로 반경 1km 원을 감사는 사각형을 생성  
WGS 84(SRID 4326) 공간 좌표계의 위치의 단위는 각도이고, 위도에 따라 경도 1도에 해당하는 거리가 상이  

```
-- // TopRight: 기준점의 북동쪽(우측 상단) 끝 좌표
Longitude_TopRight = Longitude_Origin + (${DistanceKm}/abs(cos(radians(${Latitude_Origin}))*111.32))
Latitude_TopRight = Longitude_Origin + (${DistanceKm}/111.32)

-- // BottomLeft: 기준점의 남서쪽(좌측 하단) 끝 좌표
Longitude_BottomLeft = Longitude_Origin - (${DistanceKm}/abs(cos(radians(${Latitude_Origin}))*111.32))
Latitude_BottomLeft = Longitude_Origin - (${DistanceKm}/111.32)
```

<br>

위의 식을 이용해서 중심 위치로부터 주어진 km 반경의 원을 감싸는 직사각형 객체 반환함수 구현  

```sql
DELIMITER ;;

CREATE DEFINER='root'@'localhost'
  FUNCTION getDistanceMBR(p_origin POINT, p_distanceKm DOUBLE) RETURNS POLYGON
DETERMINISTIC
  SQL SECURITY INVOKER
BEGIN
  DECLARE v_originLat DOUBLE DEFAULT 0.0;
  DECLARE v_originLon DOUBLE DEFAULT 0.0;

  DECLARE v_deltaLon DOUBLE DEFAULT 0.0;
  DECLARE v_Lat1 DOUBLE DEFAULT 0.0;
  DECLARE v_Lon1 DOUBLE DEFAULT 0.0;
  DECLARE v_Lat2 DOUBLE DEFAULT 0.0;
  DECLARE v_Lon2 DOUBLE DEFAULT 0.0;

  SET v_originLat = ST_X(p_origin);
  SET v_originLon = ST_Y(p_origin);

  SET v_deltaLon = p_distanceKm / ABS(COS(RADIANS(v_originLat))*111.32);
  SET v_Lon1 = v_originLon - v_deltaLon;
  SET v_Lon2 = v_originLon + v_deltaLon;
  SET v_Lat1 = v_originLat - (p_distanceKm / 111.32);
  SET v_Lat2 = v_originLat + (p_distanceKm / 111.32);

  SET @mbr = ST_AsText(ST_Envelope(ST_GeomFromText(CONCAT("LINESTRING(", v_Lat1, " ", v_Lon1,", ", v_Lat2, " ", v_Lon2, ")"))));
  RETURN ST_PolygonFromText(@mbr, ST_SRID(p_origin));
END ;;
```

<br>

<img width="500" alt="mbr" src="https://github.com/user-attachments/assets/bc740a41-c95c-4de9-b356-255c11e14b14" />


```
mysql> SET @distanceMBR = getDistanceMBR(ST_GeomFromText('POINT(37.547027 127.047337)', 4326), 1);
mysql> SELECT ST_SRID(@distanceMBR), ST_AsText(@distanceMBR) \G
*************************** 1. row ***************************
  ST_SRID(@distanceMBR): 4326
ST_AsText(@distanceMBR): POLYGON((37.53804388825009 127.03600689589169,
                                  37.55601011174991 127.03600689589169
                                  37.55601011174991 127.05866710410828
                                  37.53804388825009 127.05866710410828
                                  37.53804388825009 127.03600689589169))
```

<br>

만약 지리 좌표계가 아닌 8.0.24 이하 버전의 평면 좌표계(SRID 0)를 사용한다면 `ST_Buffer()` 함수 사용 가능  

```
mysql> SET @origin = ST_GeomFromText('POINT(0 0)');
mysql> SET @pt_strategy = ST_Buffer_Strategy('point_circle', 8);

-- // @origin으로부터 거리가 2인 점 8개로 구성된 다각형 조회
mysql> SELECT ST_AsText(ST_Buffer(@origin, 2, @pt_strategy)) AS bounding_circle \G
*************************** 1. row ***************************
bounding_circle: POLYGON((2 0, 1.414213562373095 1.4142135623730954, -3.6739403974420594e-16 2,
                          -1.4142135623730954 1.414213562373095, -2 -2.4492935982947064e-16,
                          -1.414213562373095 -1.4142135623730951, 1.2246467991473532ㄷ-16 -2,
                          1.4142135623730951 -1.414213562373095, 2 0))
```

<br>

실제 반경 검색은 `ST_Contains()` 또는 `ST_Within()` 함수 사용  
두 함수는 동일하지만 파라미터를 반대로 입력  

```
mysql> SELECT id, name
       FROM sphere_coord
       WHERE ST_Contains(getDistanceMBR(ST_PointFromText('POINT(37547027 127.047337)', 4326), 1), location);
+----+--------------------+
| id | name               |
+----+--------------------+
|  2 | Hanyang University |
|  1 | Seoulforest        |
+----+--------------------+

mysql> SELECT id, name
       FROM sphere_coord
       WHERE ST_Within(location, getDistanceMBR(ST_PointFromText('POINT(37547027 127.047337)', 4326), 1));
+----+--------------------+
| id | name               |
+----+--------------------+
|  2 | Hanyang University |
|  1 | Seoulforest        |
+----+--------------------+

mysql> EXPLAIN
         SELECT id, name
         FROM sphere_coord
         WHERE ST_Within(location, getDistanceMBR(ST_PointFromText('POINT(37547027 127.047337)', 4326), 1));
+----+-------------+--------------+-------+-------------+---------+------+-------------+
| id | select_type | table        | type  | key         | key_len | rows | Extra       |
+----+-------------+--------------+-------+-------------+---------+------+-------------+
|  1 | SIMPLE      | sphere_coord | range | sx_location |      34 |    4 | Using where |
+----+-------------+--------------+-------+-------------+---------+------+-------------+
```

<br>

또한 1km 반경의 MBR 사각형 내의 점들을 검색하기 때문에 모서리 부분이 포함  
가장 쉬운 방법은 인덱스를 통해 검색된 결과에 다시 한번 거리 계산 조건을 적용하는 것  

<img width="500" alt="mbr2" src="https://github.com/user-attachments/assets/0cc61b72-6f95-4f6a-9e2a-dab371193a01" />

```sql
SELECT id, name
FROM sphere_coord
WHERE ST_Within(location, getDistanceMBR(ST_PointFromText('POINT(37.547027 127.047337)', 4326), 1))
  AND ST_Distance_Sphere(location, ST_PointFromText('POINT(37.547027 127.047337)', 4326) <= 1000;
```

<br>

### 지리 좌표계 주의 사항










