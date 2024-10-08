## 커넥션 풀
커넥션을 관리하는 풀  
커넥션을 미리 생성해두고 사용하는 방식  
커넥션 갯수 default 10  
어플리케이션 로직은 DB 드라이버가 아닌 커넥션 풀에 커넥션 요청  
사용후 재사용을 위해 커넥션 풀에 반환  
commons-dbcp2, tomcat-jdbc pool, HikariCP 등  
커넥션 풀에 커넥션을 생성할때 별도의 쓰레드 적용  
커넥션 초과 호출시 쓰레드 일정시간 대기후 종료  

````java
@Test
void dataSourceConnectionPool() throws SQLException, InterruptedException {
    //커넥션 풀링
    HikariDataSource dataSource = new HikariDataSource();
    dataSource.setJdbcUrl(ConnectionConst.URL);
    dataSource.setUsername(ConnectionConst.USERNAME);
    dataSource.setPassword(ConnectionConst.PASSWORD);
    dataSource.setMaximumPoolSize(10);
    dataSource.setPoolName("MyPool");

    Connection con = dataSource.getConnection();
    Thread.sleep(1000);  //로그를 보기위해 추가
}
````

<br>

    정상로그 : 'MyPool - After adding stats (total=10, active=1, idle=9, wating=0)'
    초과로그 : 'MyPool - Pool stats (total=10, active=10, idle=0, wating=1)'
             'MyPool - Fill pool skipped, pool is at sufficient level.' 

<br>

## 데이터소스
커넥션을 획득하는 방법을 추상화하는 인터페이스  
DriverManager는 Datasource 인터페이스를 사용하지 않으므로 직접 구현  
대신 DriverManagerDataSource 클래스 제공  

````java
public interface DataSource {
    Connection getConnection() throws SQLException;
}
````

<br>

## 드라이버와 데이터소스 차이
드라이버는 커넥션을 획득할 때마다 여러 파라미터를 계속 전달  
데이터소스는 처음 객체를 생성하는 순간에만 파라미터 전달  
설정과 사용의 분리를 통해 향후 변경에 유연하게 대처  

<br>

### 드라이버  
````java
Connection con = DriverManager.getConnection(URL, USERNAME, PASSWORD);
````

### 데이터소스
````java
DriverManagerDataSource dataSource = new DriverManagerDataSource(URL, USERNAME, PASSWORD);
Connection con = dataSource.getConnection();
````

<br>

