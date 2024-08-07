## 날짜 파싱
java.time.format 패키지  
DateTimeformatter 클래스를 이용해서 문자열 날짜 파싱  
기존의 java.util.DateFormat 클래스와 다르게 스레드 안전  

<br>

### 날짜를 문자열로 변환
````java
LocalDate date = LocalDate.of(2023, 6, 7);
String date1 = data.format(DateTimeFormatter.BASIC_ISO_DATE);   //20230607
String date2 = data.format(DateTimeFormatter.ISO_LOCAL_DATE);   //2034-06-07
````

<br>

### 문자열을 날짜로 변환
````java
LocalDate date1 = LocalDate.parse("20230607", DateTimeFormatter.BASIC_ISO_DATE);
LocalDate date2 = LocalDAte.parse("2023-06-07", DateTimeFormatter.ISO_LOCAL_DATE);
````

<br>

### 패턴 사용
````java
DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");
LocalDate date1 = LocalDate.of(2023, 6, 7);
String formattedDate = date1.format(formatter);
LocalDate date2 = LocalDate.parse(formattedDate, formatter);
````

<br>

### Locale 지역화
````java
DateTimeFormatter italianFormatter = DateTimeFormatter.ofPattern("d.  MMMM yyyy", Locale.ITALIAN);
LocalDate date1 = LocalDate.of(2023, 6, 7);
String formattedDate = date.format(italianFormatter);
LocalDate date2 = LocalDate.parse(formattedDate, italianFormatter);
````

<br>

## DateTimeFormatterBuilder
복합적인 포메터를 정의해서 세부적인 제어 가능  

````java
DateTimeFormatter italianFormatter = new DateTimeFormatterBuilder()
    .appendText(ChronoField.DAY_OF_MONTH)
    .appendLiteral(". ")
    .appendText(ChronoField.MONTH_OF_YEAR)
    .appendLiteral(" ")
    .appendText(ChronoField.YEAR)
    .parseCaseInsensitive()
    .toFormatter(Locale.ITALIAN);
````

<br>
