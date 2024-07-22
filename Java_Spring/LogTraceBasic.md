## 로그 추적기 요구사항
모드 public 메서드의 호출과 응답 정보를 로그로 출력  
어플리케이션의 흐름 변경 금지  
메서드 호출에 걸린 시간  
정상 흐름과 예외 흐름 구분  
메서드 호출의 깊이 표현  
HTTP 요청 구분  

    //정상 요청
    [796bccd9] OrderController.request()
    [796bccd9] |-->OrderService.orderItem()
    [796bccd9] |   |-->OrderRepository.save()
    [796bccd9] |   |<--OrderRepository.save() time=1004ms
    [796bccd9] |<--OrderService.orderItem() time=1014ms
    [796bccd9] OrderController.request() time=1016ms
    
    //예외 발생
    [b7119f27] OrderController.request()
    [b7119f27] |-->OrderService.orderItem()
    [b7119f27] | |-->OrderRepository.save() 
    [b7119f27] | |<X-OrderRepository.save() time=0ms ex=java.lang.IllegalStateException: 예외 발생! 
    [b7119f27] |<X-OrderService.orderItem() time=10ms ex=java.lang.IllegalStateException: 예외 발생! 
    [b7119f27] OrderController.request() time=11ms ex=java.lang.IllegalStateException: 예외 발생!

````java
@Getter
public class TraceId {

    private String id;
    private int level;

    public TraceId() {
        this.id = createId();
        this.level = 0;
    }
    
    private TraceId(String id, int level) {
        this.id = id;
        this.level = level;
    }
    
    private String createId() {
        //ab99e16f-3cde-4d24-8241-256108c203a2
        //앞 8자리만 사용
        return UUID.randomUUID().toString().substring(0, 8);
    }
    
    public TraceId createNextId() { return new TraceId(id, level + 1); }

    public TraceId createPreviousId() { return new TraceId(id, level - 1); }
    
    public boolean isFirstLevel() { return level == 0; }

}
````

````java
@Getter
public class TraceStatus {

    private TraceId traceId;
    private Long startTimeMs;
    private String message;

    public TraceStatus(TraceId traceId, Long startTimeMs, String message) {
        this.traceId = traceId;
        this.startTimeMs = startTimeMs;
        this.message = message;
    }
}
````
````java
@Slf4j
@Component
public class LogTraceV2 {

    private static final String START_PREFIX = "-->";
    private static final String COMPLETE_PREFIX = "<--";
    private static final String EX_PREFIX = "<X-";

    public TraceStatus begin(String message) {
        TraceId traceId = new TraceId();
        long startTimeMs = System.currentTimeMillis();
        log.info("[{}] {}{}", traceId.getId(),
          addSpace(START_PREFIX, traceId.getLevel()), message);
        return new TraceStatus(traceId, startTimeMs, message);
    }

    public TraceStatus beginSync(TraceId beforeTraceId, String message) {
        TraceId nextId = beforeTraceId.createNextId();
        long startTimeMs = System.currentTimeMillis();
        log.info("[{}] {}{}", nextId.getId(),
          addSpace(START_PREFIX, nextId.getLevel()), message);
        return new TraceStatus(nextId, startTimeMs, message);
    }

    public void end(TraceStatus status) { complete(status, null); }

    public void exception(TraceStatus status, Exception e) { complete(status, e); }

    private void complete(TraceStatus status, Exception e) {
        long stopTimeMs = System.currentTimeMillis();
        long resultTimeMs = stopTimeMs - status.getStartTimeMs();
        TraceId traceId = status.getTraceId();
        if (e == null) {
            log.info("[{}] {}{} time={}ms", traceId.getId(),
              addSpace(COMPLETE_PREFIX, traceId.getLevel()), status.getMessage(), resultTimeMs);
        } else {
            log.info("[{}] {}{} time={}ms ex={}", traceId.getId(),
              addSpace(EX_PREFIX, traceId.getLevel()), status.getMessage(), resultTimeMs, e.toString());
        }
    }

    private static String addSpace(String prefix, int level) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < level; i++) {
            sb.append((i == level - 1) ? "|" + prefix : "|  ");
        }
        return sb.toString();
    }
}
````
````java
@RestController
@RequiredArgsConstructor
public class OrderControllerV2 {

    private final OrderServiceV2 orderService;
    private final LogTraceV2 trace;

    @GetMapping("/v2/request")
    public String request(String itemId) {
        TraceStatus status = null;
        try {
            status = trace.begin("OrderController.request()");
            orderService.orderItem(status.getTraceId(), itemId);
            trace.end(status);
          return "ok";
        } catch (Exception e) {
            trace.exception(status, e);
            throw e;
        }
    }
}
````
````java
@Service
@RequiredArgsConstructor
public class OrderServiceV2 {

    private final OrderRepositoryV2 orderRepository;
    private final LogTraceV2 trace;
    public void orderItem(TraceId traceId, String itemId) {
        TraceStatus status = null;
        try {
            //beginSync 메서드와 매개변수로 받은 traceId를 통해 같은 트랙잭션 관리
            status = trace.beginSync(traceId, "OrderService.orderItem()");
            orderRepository.save(status.getTraceId(), itemId);
            trace.end(status);
        } catch (Exception e) {
            trace.exception(status, e);
            throw e;
        }
    }
}
````

<br>
