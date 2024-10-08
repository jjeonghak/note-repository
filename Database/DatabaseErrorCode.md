## 데이터베이스 오류코드
데이터베이스 내부에서 어떠한 오류가 발생했는지 오류코드를 통해 구분  
SQLException 내부에 errorCode를 포함  

````java
e.getErrorCode()
````

같은 오류지만 각각의 데이터베이스마다 정의된 오류코드 상이

    * H2 데이터베이스
      23505 : 키 중복 오류
      42000 : SQL 문법 오류
      
    * MySQL
      1062 : 키 중복 오류

<br>

## 스프링 예외 추상화
스프링은 데이터 접근 계층에 대한 여러가지 예외를 정리해서 일관된 예외 계층 제공  
데이터베이스에서 발생하는 오류코드를 스프링이 정의한 예외로 자동 변환해주는 변환기 제공  
특정 기술에 종속적이지 않게 설계되어 서비스 계층에서도 사용 가능  

    RuntimeException
      DataAccessException
      
        NonTransientDataAccessException
          BadSqlGrammarException
          DataIntegrityViolationException
            DuplicateKeyException
          ...
            
        TransientDataAccessException
          QueryTimeoutException
          OptimisticLockingException
          PessimisticLockingException
          ...

<br>

최상위 예외는 RuntimeException  
Transient 예외는 일시적으로 동일한 sql을 다시 시도했을 경우 성공할 가능성 존재  
NonTransient 예외는 동일한 sql을 그대로 반복해서 실행한 경우 실패  

<br>

## 스프링 예외 변환기
직접 예외를 확인하고 스프링 정의 예외로 변환하는 것은 현실적으로 불가능  
데이터베이스마다 오류코드 상이 문제 해결  
최종적으로 DataAccessException 하위 예외 클래스 반환  
translate() : 설명, 실행한 sql, 발생한 예외 순으로 파라미터 전달, 적절한 스프링 예외로 반환  

````java
SQLErrorCodeSQLExceptionTranslator exTranslator = new SQLErrorCodeSQLExceptionTranslator(dataSource);
DataAccessException resultEx = exTranslator.translate("task", sql, e);
````

<br>

org.springframework.jdbc.support.sql-error-codes.xml 정보를 사용

````xml
<!-- [org.springframework.jdbc.support.sql-error-codes.xml] -->
<bean id="H2" class="org.springframework.jdbc.support.SQLErrorCodes">
  <property name="badSqlGrammarCodes">
    <value>42000,42001,42101,42102,42111,42112,42121,42122,42132</value>
  </property>
  <property name="duplicateKeyCodes">
    <value>23001,23505</value>
  </property>
  <property name="dataIntegrityViolationCodes">
    <value>22001,22003,22012,22018,22025,23000,23002,23003,23502,23503,23506,23507,23513</value>
  </property>
  <property name="dataAccessResourceFailureCodes">
    <value>90046,90100,90117,90121,90126</value>
  </property>
  <property name="cannotAcquireLockCodes">
    <value>50200</value>
  </property>
</bean>
````

<br>
