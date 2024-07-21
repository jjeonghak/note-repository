## 시간대
시간대와 관련한 정보  
기존의 java.util.TimeZone을 대체할 java.time.ZoneId 클래스 등장  
서머타임(DST, Daylight Saving Time) 같은 복잡한 사항이 자동 처리  

<br>

## 시간대 규칙 집합
표준 시간이 같은 지역을 묶어서 정의  
ZoneRules 클래스에는 약 40개의 시간대 존재  
지역 ID는 `{지역}/{도시}` 형식  
IANA Time Zone Database(https://www.iana.org/time-zone 참고)에서 제공하는 지역 집합 정보 사용  

````java
    ZoneId romeZone = ZoneId.of("Europe/Rome");
````

<br>

### 기존 TimeZone 객체를 ZoneId 객체로 변환
````java
ZoneId zoneId = TimeZone.getDefault().toZoneId();
````

<br>

### 여러 시간을 ZoneId 객체로 변환
````java
LocalDate date = LocalDate.now();
ZonedDateTime zdt1 = date.atStartOfDay(romeZone);
LocalDateTime dateTime = LocalDateTime.now();
ZonedDateTime zdt2 = dateTime.atZone(romeZone);
Instant instant = Instant.now();
ZonedDateTime zdt3 = instant.atZone(romeZone);
````

<br>

### ZoneId 클래스를 이용한 변환
````java
Instant instant = Instant.now();
LocalDateTime timeFromInstant = LocalDateTime.ofInstant(instant, romeZone);
````

<br>

## 시간 개념
````
  ZonedDateTime
    ㄴ ZoneId
    ㄴ LocalDateTime
      ㄴ LocalDate
      ㄴ LocalTime
````

<br>

## 고정 오프셋
협정 세계시(UTC, Universal Time Coordinated) 또는 그리니치 표준시(GMT, Greenwich Mean Time) 기준 시간대 표현  
ZoneId 서브클래스인 ZoneOffset 클래스를 이용한 시간대 비교 가능  
뉴욕은 런던보다 5시간 느리다는 것을 런던의 그리니치 0도 자오선과 시간값 차이 표현  
ISO-8601 캘린더 시스템 이용  

<br>

### 시간차 표현
````java
ZoneOffset newYorkOffset = ZoneOffset.of("-05:00");
````

<br>
    
### OffsetDateTime 클래스를 이용한 방식
````java
LocalDateTime dateTime = LocalDateTime.now();
OffsetDateTime dateTimeInNewYork = OffsetDateTime.of(dateTime, newYorkOffset);
````

<br>

## 대안 캘린더 시스템
ISO-8601 캘린더 시스템은 실질적으로 전 세계에서 통용  
자바 8에선 ThaiBuddhistDate, MinguoDate, JapaneseDate, HijrahDate 캘린더 시스템 추가  
LocalDate 클래스와 동일하게 ChronoLocalDate 인터페이스 구현  
설계자들은 LocalDate 클래스 사용 권장  
멀티 캘린더 시스템에는 기본적인 불변식 적용안됨(Y = 12M, D < 32, length(Y) = 12)  
지역화하는 상황을 제외하고는 사용하지 않는 것 권장  

````java
LocalDAte date = LocalDate.now();
JapaneseDate japaneseDate = JapaneseDate.from(date);
````

<br>

### Chronology 클래스를 이용한 방식
````java
Chronology japaneseChronology = Chronology.ofLocale(Locale.JAPAN);
ChronoLocalDate now = japaneseChronology.dateNow();
````

<br>

## 이슬람력
새롭게 추가된 캘린더 중 HijrahDate 캘린더 시스템이 가장 복잡  
이슬람력은 변형(variant) 존재  
태음월(lunar month)에 기초  
새로운 달(month)을 결정할 때 새로운 달(moon)을 전세계에서 볼 수 있는지 여부에 따라 변형 메서드(withVariant) 존재  
표준 변형 방법으로 UmmAl-Qura 제공  

````java
HijrahDate ramadanDate = HijrahDate.now()
    .with(ChronoField.DAY_OF_MONTH, 1)
    .with(ChronoField.MONTH_OF_YEAR, 9);
Systme.out.println("Ramadan starts on " + IsoChronology.INSTANCE.date(ramadanDate)
    + " and ends on " + IsoChronology.INSTANCE.date(ramadanDate.with(TemporalAdjusters.lastDayOfMonth())));
````

<br>
