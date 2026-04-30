## 콜백
콜백 또는 콜에프터 함수(call after function)는 다른 코드의 인수로서 넘겨주는 실행가능한 코드  
콜백 필요에 따라 즉시 또는 나중에 실행 가능  

<br>

## 템플릿 콜백 패턴
스프링에서는 전략 패턴을 템플릿 콜백 패턴으로 정의  
전략 패턴의 Context -&gt; Template, Strategy -&gt; Callback

    JdbcTemplate, RestTemplate, TransactionTemplate, RedisTemplate

<br>

````java
public interface Callback {
    void call();
}

@Slf4j
public class TimeLogTemplate {
    public void execute(Callback callback) {
        long startTime = System.currentTimeMillis();
        callback.call(); //위임
        long endTime = System.currentTimeMillis();
        log.info("logic run time: {}", endTime - startTime);
    }
}

@Test
void callbackV1() {
    TimeLogTemplate template = new TimeLogTemplate();
    template.execute(new Callback() {
        @Override
        public void call() {
            log.info("logic start");
        }
    });
}

@Test
void callbackV2() {
    TimeLogTemplate template = new TimeLogTemplate();
    template.execute(() -> log.info("logic start"));
}
````

<br>

