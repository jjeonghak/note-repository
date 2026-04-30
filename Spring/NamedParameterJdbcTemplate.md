## 이름 지정 파라미터
기존 sql 문에서 순서 바인딩이 아닌 이름 바인딩 형식  
`?` 대신 `:ParamName` 형식으로 sql 파라미터 바인딩  
Map 같은 key:value 데이터 구조를 만들어서 전달  

````java
public NamedParamJdbcTemplateItemRepository(DataSource dataSource) {
    this.template = new NamedParameterJdbcTemplate(dataSource);
}

template.update(sql, param, keyHolder);
````

<br>

## 이름 지정 바인딩 파라미터 종류
1. Map  

2. SqlParameterSource(Interface)  
MapSqlParameterSource  
BeanPropertySqlParameterSource  

<br>

## Map
일반적인 Map 사용

````java
Map<String, Object> param = Map.of("itemId", itemId);
Item item = template.queryForObject(sql, param, itemRowMapper());
````

<br>

## MapSqlParameterSource
Map과 유사하지만 sql 타입을 지정할 수 있는 등 sql 특화 기능 제공  
메서드 체인을 통해 편리한 사용 가능  

````java
SqlParameterSource param = new MapSqlParameterSource()
        .addValue("itemName", updateParam.getItemName())
        .addValue("itemId", itemId);
template.update(sql, param);
````

<br>

## BeanPropertySqlParameterSource
자바빈 프로퍼티 규약을 통해서 자동으로 파라미터 객체 생성(getXxx() -> xxx)  
많은 부분으로 자동화하지만 DTO를 다루거나 객체와 엔티티의 모든 속성이 매칭이 안되면 사용불가  

````java
SqlParameterSoure param = new BeanPropertySqlParametersource(item);
````

<br>
  
## BeanPropertyRowMapper
ResutSet의 결과를 받아서 자바빈 규약에 맞추어 데이터를 변환(setXxx() -> xxx)  
객체와 엔티티의 속성명이 다른 경우 개발자가 직접 sql에 as 별칭 사용(select member_name as username)  
카멜 표기법과 언더스코어 표기법처럼 관례의 불일치 자동 변환(item_name -> itemName)  

````java
private RowMapper<Item> itemRowMapper() {
    return BeanPropertyRowMapper.newInstance(Item.class); //camel 변환 지원
}
````
  
<br>
