## 엔티티 직접 노출
컬렉션에서 원하는 각각의 엔티티마다 강제 초기화 필수

````java
@GetMapping("/api/v1/orders")
public List<Order> orderV1() {
    List<Order> result = orderRepository.findAll(new OrderSearch());
    for (Order order : result) {
        order.getMember().getName();
        order.getDelivery().getAddress();
        List<OrderItem> orderItems = order.getOrderItems();
        orderItems.stream().forEach(o -> o.getItem().getName());
    }
    return result;
}
````

<br>

## 엔티티 조회 후 DTO 사용
컬렉션의 엔티티도 DTO로 변환해서 API 생성

````java
@GetMapping("/api/v2/orders")
public List<OrderDto> orderV2() {
    List<Order> orders = orderRepository.findAll(new OrderSearch());
    List<OrderDto> collect = orders.stream()
            .map(o -> new OrderDto(o))
            .collect(Collectors.toList());
    return collect;
}

@Data
static class OrderDto {
    private Long orderId;
    private String name;
    private LocalDateTime orderDate;
    private OrderStatus orderStatus;
    private Address address;
    private List<OrderItemDto> orderItems;

    public OrderDto(Order order) {
        orderId = order.getId();
        name = order.getMember().getName();
        orderDate = order.getOrderDate();
        orderStatus = order.getStatus();
        address = order.getDelivery().getAddress();
        orderItems = order.getOrderItems().stream()
                .map(o -> new OrderItemDto(o))
                .collect(Collectors.toList());
    }
}

@Getter
static class OrderItemDto {

    private String itemName;
    private int orderPrice;
    private int count;

    public OrderItemDto(OrderItem orderItem) {
        itemName = orderItem.getItem().getName();
        orderPrice = orderItem.getOrderPrice();
        count = orderItem.getCount();
    }
}
````

<br>

## 페치조인 사용
일반적인 사용
````java
 public List<Order> findAllWithItem() {
    return em.createQuery(
            "select distinct o from Order o " +
                    "join fetch o.member m " +
                    "join fetch o.delivery d " +
                    "join fetch o.orderItems oi " +
                    "join fetch oi.item i", Order.class)
            .getResultList();
}
````

<br>

일대일 또는 다대일은 페치조인 사용  
페이징을 위해서 일대다 매핑은 따로 지연로딩  
default_batch_fetch_size, @BatchSize 이용해서 지연로딩시 불러오는 데이터값 설정  

````java
public List<Order> findAllWithMemberDelivery(int offset, int limit) {
    return em.createQuery(
                    "select o from Order o " +
                            "join fetch o.member m " +
                            "join fetch o.delivery d", Order.class)
            .setFirstResult(offset)
            .setMaxResults(limit)
            .getResultList();
}

@GetMapping("/api/v3/orders")
public List<OrderDto> orderV3_page(
        @RequestParam(value = "offset", defaultValue = "0") int offset,
        @RequestParam(value = "limit", defaultValue = "100") int limit) {
    List<Order> orders = orderRepository.findAllWithMemberDelivery(offset, limit);
    List<OrderDto> result = orders.stream()
            .map(o -> new OrderDto(o))
            .collect(Collectors.toList());
    return result;
}
````

<br>

## DTO 직접 조회
컬렉션은 한번의 DTO 생성 쿼리로 불가능

````java
    @GetMapping("/api/v4/orders")
    public List<OrderQueryDto> orderV4() {
        return orderQueryRepository.findOrderQueryDtos();
    }
  
    public List<OrderQueryDto> findOrderQueryDtos() {
        List<OrderQueryDto> result = findOrders();
        result.forEach(o -> {
            List<OrderItemQueryDto> orderItems = findOrderItems(o.getOrderId());
            o.setOrderItems(orderItems);
        });
        return result;
    }
````

<br>

### 컬렉션 DTO
````java
private List<OrderItemQueryDto> findOrderItems(Long orderId) {
    return em.createQuery("select new jpabook.jpashop.repository.order.query" +
            ".OrderItemQueryDto(oi.order.id, i.name, oi.orderPrice, oi.count)" +
            "from OrderItem oi " +
            "join oi.item i " +
            "where oi.order.id = :orderId", OrderItemQueryDto.class)
            .setParameter("orderId", orderId)
            .getResultList();
}
````

<br>

### 컬렉션을 제외한 DTO
````java
private List<OrderQueryDto> findOrders() {
    return em.createQuery("select new jpabook.jpashop.repository.order.query" +
                    ".OrderQueryDto(o.id, m.name, o.orderDate, o.status, d.address) " +
                    "from Order o " +
                    "join o.member m " +
                    "join o.delivery d", OrderQueryDto.class)
            .getResultList();
}
````

<br>

## 컬렉션 조회 최적화(메모리 사용)
필요한 정보들을 한번에 메모리로 가져와서 직접 매핑  
ToOne 관계들을 먼저 조회한 후 식별자를 이용해서 ToMany 관계를 쿼리 한번에 조회  

````java
public List<OrderQueryDto> findAllByDto_optimization() {
    List<OrderQueryDto> result = findOrders();
    
    List<Long> orderIds = result.stream().map(o -> o.getOrderId()).collect(Collectors.toList());

    //in 쿼리문으로 한번에 필요한 정보 메모리에 저장
    List<OrderItemQueryDto> orderItems = em.createQuery("select new jpabook.jpashop.repository.order.query" +
                    ".OrderItemQueryDto(oi.order.id, i.name, oi.orderPrice, oi.count)" +
                    "from OrderItem oi " +
                    "join oi.item i " +
                    "where oi.order.id in :orderIds", OrderItemQueryDto.class)
            .setParameter("orderIds", orderIds)
            .getResultList();

    Map<Long, List<OrderItemQueryDto>> orderItemMap = orderItems.stream() 
            .collect(Collectors.groupingBy(orderItemQueryDto -> orderItemQueryDto.getOrderId()));

    //저장한 정보들을 직접 매핑
    result.forEach(o -> o.setOrderItems(orderItemMap.get(o.getOrderId())));

    return result;
}
````

<br>

## 플랫 데이터 최적화
모든 엔티티 테이블을 조인해서 한번에 조회

````java
public List<OrderFlatDto> findAllByDto_flat() {
    return em.createQuery("select distinct new jpabook.jpashop.repository.order.query" +
            ".OrderFlatDto(o.id, m.name, o.orderDate, o.status, d.address, i.name, oi.orderPrice, oi.count)" +
            "from Order o " +
            "join o.member m " +
            "join o.delivery d " +
            "join o.orderItems oi " +
            "join oi.item i", OrderFlatDto.class)
            .getResultList();
}
````

<br>
