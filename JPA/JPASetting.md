## JPA 설정
* 스프링 부트 사용시 아래 설정 필요없음  
* persistence.xml 및 LocalContainerEntityManagerFactoryBean 없이 가능  

<br>

### maven 라이브러리 빌드
````xml
<dependencies>
    <!-- JPA 하이버네이트 -->
    <dependency>
        <groupId>org.hibernate</groupId>
        <artifactId>hibernate-entitymanager</artifactId>
        <version>5.6.8.Final</version>
    </dependency>

    <!-- H2 데이터베이스 -->
    <dependency>
        <groupId>com.h2database</groupId>
        <artifactId>h2</artifactId>
        <version>2.1.212</version>
    </dependency>
</dependencies>
````

<br>

### persistence.xml
resources/META-INF/presistence.xml 생성

````xml
<?xml version="1.0" encoding="UTF-8"?>
<persistence version="2.2"
xmlns="http://xmlns.jcp.org/xml/ns/persistence" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/persistence http://xmlns.jcp.org/xml/ns/persistence/persistence_2_2.xsd">
        
    <!-- persistenceUnitName, 팩토리 생성시 필요 -->
    <persistence-unit name="hello">
        <properties>
        
            <!-- 필수 속성 -->
            <property name="javax.persistence.jdbc.driver" value="org.h2.Driver"/>
            <property name="javax.persistence.jdbc.user" value="sa"/>
            <property name="javax.persistence.jdbc.password" value=""/>
            <property name="javax.persistence.jdbc.url" value="jdbc:h2:tcp://localhost/~/test"/>
            
            <!-- H2Dialect, 사용할 데이터베이스 종류의 방언 -->
            <property name="hibernate.dialect" value="org.hibernate.dialect.H2Dialect"/>
            
            <!-- 옵션 -->
            <!-- show_sql, 결과창에 전송한 sql 쿼리문 출력 -->
            <property name="hibernate.show_sql" value="true"/>
            
            <!-- format_sql, sql 쿼리문 출력 포멧 -->
            <property name="hibernate.format_sql" value="true"/>
            
            <!-- use_sql_comments, sql 쿼리문 전송 이유 출력 -->
            <property name="hibernate.use_sql_comments" value="true"/>
            
            <!--<property name="hibernate.hbm2ddl.auto" value="create" />-->
            
        </properties>
    </persistence-unit>
</persistence>
````

<br>

### 데이터베이스 방언  
JPA는 특정 데이터베이스에 종속되지 않음  
방언 : SQL 표준을 지키지 않는 특정 데이터베이스만의 고유한 기능, 필수로 설정  

      MySQLDialect, OracleDialect, H2Dialect

<br>
