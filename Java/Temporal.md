## Date
java.util.Date 패키지 내에   
날짜와 시간 관련 기능을 제공  
특정 시점을 날짜가 아닌 밀리초 단위로 표현  
1900년을 기준으로 오프셋  
0부터 시작하는 달 인덱스 등 모호한 설계  
toString 메서드로 반환되는 문자열을 추가로 활용하기 어려움  
JVM 기본시간대인 CET(중앙 유럽 시간대, Central European Time) 사용  
여러 메서드 사장(deprecated)  
대안으로 Calendar 클래스 등장했지만 이 또한 많은 에러와 혼동 증가  
Date 클래스에만 작동하는 DateFormat 클래스도 스레드 안전하지 않음  

````java
//2023년 6월 7일
Date date = new Date(123, 6, 7);
````

<br>

## LocalDate
java.time 패키지 내에 존재  
시간을 제외한 날짜를 표현하는 불변 객체  
어떤 시간대 정보도 포함하지 않음  
파싱 불가한 경우 DateTimeParseException 오류 발생  

````java
LocalDate date = LocalDate.of(2023, 6, 7);      //2023-06-07
int year = date.getYear();                      //2023
Month month = date.getMonth();                  //JUNE
DayOfWeek dow = date.getDayOfWeek();            //WEDNESDAY
int day = date.getDayOfMonth();                 //7
int intMonth = date.getMonthValue();            //6
int len = date.lengthOfMonth();                 //30(6월의 일 수)
boolean leap = date.isLeapYear();               //false(윤년 아님)
LocalDate today = LocalDate.now();              //현재 날짜 정보
LocalDate pd = LocalDate.parse("2023-06-07");   //문자열 파싱
````

<br>

## TemporalField
시간 관련 객체에서 어떤 필드의 값에 접근할지 정의하는 인터페이스  
LocalDate.get 메서드에 TemporalField 값을 전달해서 정보 조회 가능  

````java
//ChronoField 열거자 요소 사용(TemporalField 정의)
int year = date.get(ChronoField.YEAR);
int month = date.get(ChronoField.MONTH_OF_YEAR);
int day = date.get(ChronoField.DAY_OF_MONTH);
````

<br>

## LocalTime
java.time 패키지 내에 존재  
시간을 표현하는 불변 객체  

````java
LocalTime time = LocalTime.of(13, 45, 20);
int hour = time.getHour();
int minute = time.getMinute();
int second = time.getSecond();
LcalTime parseTime = LocalTime("13:45:20");
````

<br>

## LocalDateTime
java.time 패키지 내에 존재  
LocalDate 클래스와 LocalTime 클래스를 쌍으로 갖는 복합 클래스  
날짜와 시간을 모두 표현  

````java
LocalDateTime dt1 = LocalDateTime.of(2023, Month.JUNE, 7, 13, 45, 20);
LocalDateTime dt2 = LocalDateTime.of(date, time);
LocalDateTime dt3 = date.atTime(13, 45, 20);
LocalDateTime dt4 = date.atTime(time);
LocalDateTime dt5 = time.atDate(date);

//LocalDateTime 
LocalDate date = dt1.toLocalDate();
LocalTime time = dt1.toLocalTime();
````

<br>

## Instant
java.time.Instant 패키지 내에 존재
기계의 관점에서 연속된 시간에서 특정 지점을 하나의 큰 수로 표현하는 방법  
유닉스 에포크 시간(UTC, 1970.01.01T00:00:00) 기준으로 특정 지점까지의 시간을 초로 표현  
나노초(10억분의 1) 정밀도 제공, 두번째 인수로 999,999,999까지의 정수 값 지정 가능  
TemporalField 인스턴스 지원안함  
Duration, Period 객체 사용  

````java
Instant.ofEpochSecond(3);
Instant.ofEpochSecond(3, 0);
Instant.ofEpochSecond(2, 1_000_000_000);    //2초 이후의 1억 나노초, 3초
Instant.ofEpochSecond(4, -1_000_000_000);   //4초 이전의 1억 나노초, 3초

//사람이 읽을 수 있는 시간 정보 제공안함
int day = Instant.now().get(ChronoField.DAY_OF_MONTH);  //UnsupportedTemporalException 오류 발셍
````

<br>

## Duration
두 시간 객체 사이의 지속시간을 표현  
LocalDate 객체는 나노초 시간 단위를 표현할 수 없음  

````java
Duration d1 = Duration.between(time1, time2);
Duration d2 = Duration.between(dateTime1, dateTime2);
Duration d3 = Duration.between(instant1, instant2);

Duration threeMinutes = Duration.ofMinutes(3);
Duration threeMinutes = Duration.of(3, ChronoUnit.MINUTES);
````

<br>

## Period
년, 월, 일로 시간을 표현할 경우 사용  

````java
Period tenDays = Period.between(LocalDate.of(2023, 6, 7),
    LocalDate.of(2023, 6, 17));
    
Period twoDays = Period.ofDays(2);
Period threeWeeks = Period.ofWeeks(3);
Period twoYearsSixMonthsOneDay = Period.of(2, 6, 1);
````

<br>

## Duration, Period 공통 메서드
1. static between() : 두 시간 사이의 간격 생성  
2. static from() : 시간 단위로 간격 생성  
3. static of() : 주어진 구성 요소에서 간격 생성  
4. static parse() : 문자열을 파싱해서 간격 생성  
5. addTo() : 현재값 복사본 생성후 지정된 Temporal 객체에 추가  
6. get() : 현재 간격 정보값 반환  
7. isNegative() : 간격의 음수 여부  
8. isZero() : 간격 값 0 여부  
9. minus() : 현재값에서 주어진 시간을 뺀 복사본 생성  
10. multipliedBy() : 현재값에서 주어진 값을 곱한 복사본 생성  
11. negated() : 주어진 값의 부호를 반전한 복사본 생성  
12. plus() : 현재값에서 주어진 시간을 더한 복사본 생성  
13. subtractFrom() : 지정된 Temporal 객체에서 간격을 뺌  

<br>
