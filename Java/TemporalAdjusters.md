## 날짜 조정
Local 시간 클래스는 모두 불변  
날짜 조정시 기존 객체를 변경하지 않고 새로운 객체 반환  

````java
LocalDate date1 = LocalDate.of(2023, 6, 7);                   //2023-06-07
LocalDate date2 = date1.withYear(2000);                       //2000-06-07
LocalDate date3 = date2.withDayOfMonth(25);                   //2000-06-25
LocalDate date4 = date3.with(ChronoField.MONTH_OF_YEAR, 2);   //2000-02-25

//Temporal 메서드 사용
LocalDate date1 = LocalDate.of(2023, 6, 7);                   //2023-06-07
LocalDate date2 = date1.plusWeeks(1);                         //2023-06-14
LocalDate date3 = date2.minusYears(6);                        //2017-06-14
LocalDate date4 = date3.plus(6, ChronoField.MONTH);           //2017-08-14
````

<br>

## Temporal 공통 메서드
1. static from() : 주어진 Temporl 객체를 이용해서 클래스 인스턴스 생성  
2. static now() : 시스템 시계로 Temporal 객체 생성  
3. static of() : 주어진 구성 요소에서 Temporal 객체 인스턴스 생성  
4. static parse() : 문자열을 파싱해서 Temporal 객체 생성  
5. atOffset() : 시간대 오프셋과 Temporal 객체 병합  
6. atZone() : 시간대 오프셋과 Temporal 객체 병합  
7. format() : 지정된 포멧터를 이용해서 Temporal 객체를 문자열로 변환(Instant 지원안함)  
8. get() : Temporal 객체 상태 반환  
9. minus() : 특정 시간을 뺀 Temporal 객체 복사본 생성  
10. plus() : 특정 시간을 더한 Temporal 객체 복사본 생성  
11. with() : 일부 상태를 변경한 Temporal 객체 복사본 생성  

<br>

## TemporalAdjusters
java.time.temporal.TemporalAdjusters 패키지  
복잡한 날짜 조정 기능을 지원  
여러 TemporalAdjuster 인터페이스 제공  

````java
LocalDate date1 = LocalDate.of(2023, 6, 7);                   //2023-06-07
LocalDate date2 = date1.with(nextOrSame(DayOfWeek.SUNDAY));   //2023-06-11
LocalDate date3 = date2.with(lastDayOfMonth());               //2023-06-30
````

<br>

1. dayOfWeekInMonth : 서수 요일에 해당하는 날짜 반환하는 TemporalAdjuster를 반환  
2. firstDayOfMonth : 현재 달의 첫번째 날짜를 반환하는 TemporalAdjuster를 반환  
3. firstDayOfNextMonth : 다음 달의 첫번째 날짜를 반환하는 TemporalAdjuster를 반환  
4. firstDayOfNextYear : 내년의 첫번째 날짜를 반환하는 TemporalAdjuster를 반환  
5. firstDayOfYear : 올해의 첫번째 날짜를 반환하는 TemporalAdjuster를 반환  
6. firstInMonth : 현재 달의 첫번째 요일에 해당하는 날짜를 반환하는 TemporalAdjuster를 반환  
7. lastDayOfMonth : 현재 달의 마지막 날짜를 반환하는 TemporalAdjuster를 반환  
8. lastDayOfNextMonth : 다음 달의 마지막 날짜를 반환하는 TemporalAdjuster를 반환  
9. lastDayOfNextYear : 내년의 마지막 날짜를 반환하는 TemporalAdjuster를 반환  
10. lastDayOfYear : 올해의 마지막 날짜를 반환하는 TemporalAdjuster를 반환  
11. lastInMonth : 현재 달의 마지막 요일에 해당하는 날짜를 반환하는 TemporalAdjuster를 반환  
12. next previous : 현재 달에서 현재 날짜 이후로 지정한 요일이 처음 나오는 날짜를 반환하는 TemporalAdjuster를 반환  
13. nextOrSame : 현재 날짜 이후로 지정한 요일이 처음으로 나타나는 날짜를 반환하는 TemporalAdjuster를 반환  
14. previousOrSame : 현재 날짜 이후로 지정한 요일이 이전으로 나타나는 날짜를 반환하는 TemporalAdjuster를 반환  

<br>

## TemporalAdjuster
Temporal 객체를 어떻게 다른 Temporal 객체로 변환할지 정의  

````java
@FunctionalInterface
public interface TemporalAdjuster {
    Temporal adjustInfo(Temporal temporal);
}
````

<br>


