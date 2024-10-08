## 엔티티 직접 노출
엔티티를 직접 반환하는 방식이므로 지양(필요하지 않은 속성까지 모두 노출)  
양방향인 경우 무한루프 발생(한쪽 방향 @JsonIgnore 어노테이션 필수)  
프록시 객체 조회에 대한 오류발생(Hibernate5Module로 프록시 객체 처리 필수)  

````java
@GetMapping("/api/v1/simple-orders")
public List<Order> orderV1() {
	List<Order> all = orderRepository.findAll(new OrderSearch());
	return all;
}
````

[gradle] 
````java
implementation 'com.fasterxml.jackson.datatype:jackson-datatype-hibernate5'
````

### 프록시 객체 null 처리
````java
@Bean
Hibernate5Module hibernate5Module() {
	return new Hibernate5Module();  
}
````

### 프록시 객체 강제 조회(FORCE_LAZY_LOADING)
````java
@Bean
Hibernate5Module hibernate5Module() {
	Hibernate5Module hibernate5Module = new Hibernate5Module();
	hibernate5Module.configure(Hibernate5Module.Feature.FORCE_LAZY_LOADING, true);
	return hibernate5Module;
}
````

<br>

## DTO 사용
쿼리가 1 + N + N번 실행

````java
@GetMapping("/api/v2/simple-orders")
public List<SimpleOrderDto> orderV2() {
	List<Order> orders = orderRepository.findAll(new OrderSearch());
	List<SimpleOrderDto> result = orders.stream()
		.map(o -> new SimpleOrderDto(o))
		.collect(Collectors.toList());
	return result;
}

@Data
static class SimpleOrderDto {
	private Long orderId;
	private String name;
	private LocalDateTime orderDate;
	private OrderStatus orderStatus;
	private Address address;

	public SimpleOrderDto(Order order) {
	    orderId = order.getId();
	    name = order.getMember().getName();
	    orderDate = order.getOrderDate();
	    orderStatus = order.getStatus();
	    address = order.getDelivery().getAddress();
	}
}
````

<br>

## 페치조인 사용
지연로딩이 아닌 즉시로딩으로 쿼리 한번에 모든 데이터  
연관된 엔티티의 모든 속성을 가져오지만 재사용성 높음  

````java
public List<Order> findAllWithMemberDelivery() {
        return em.createQuery(
                        "select o from Order o " +
                        "join fetch o.member m " +
                        "join fetch o.delivery d", Order.class)
                .getResultList();
}
    
@GetMapping("/api/v3/simple-orders")
public List<SimpleOrderDto> orderV3() {
	List<Order> orders = orderRepository.findAllWithMemberDelivery();
	List<SimpleOrderDto> result = orders.stream()
		.map(o -> new SimpleOrderDto(o))
		.collect(Collectors.toList());
	return result;
}
````

<br>

## DTO와 조인사용
페치조인은 연관된 엔티티의 모든 속성을 가져오지만 DTO를 이용한 조인은 원하는 속성만 조인  
new 명령어를 사용해서 JPQL 결과를 DTO로 즉시 변환  
원라는 데이터를 직접 선택하므로 데이터베이스와 애플리케이션 네트웍 용량 최적화(미비한 효과)  
페치조인보다 효율적이나 재사용성이 낮고 해당 DTO 한정(페치조인은 유연함)  

````java
public List<SimpleOrderQueryDto> findOrderDtos() {
        return em.createQuery(
                "select new jpabook.jpashop.repository" +
                        ".SimpleOrderQueryDto(o.id, m.name, o.orderDate, o.status, d.address) " +
                        "from Order o " +
                        "join o.member m " +
                        "join o.delivery d", SimpleOrderQueryDto.class)
                .getResultList();
}
    
@GetMapping("/api/v4/simple-orders")
public List<SimpleOrderQueryDto> orderV4() {
        return orderRepository.findOrderDtos();
}
````

<br>
