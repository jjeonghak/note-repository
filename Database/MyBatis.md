## MyBatis
JdbcTemplate보다 더 많은 기능을 제공하는 SQL Mapper  
sql을 xml에 편리하게 작성가능  
동적 쿼리를 편리하게 작성가능  

<br>

## MyBatis 설정
[gradle]
````java
implementation 'org.mybatis.spring.boot:mybatis-spring-boot-starter:3.0.0'
````

[properties]



````properties
# 마이바티스 타입정보를 사용할 때 패키지 이름을 미리 지정(콤마 또는 세미콜론으로 여러개 설정 가능)
mybatis.type-aliases-package=hello.itemservice.domain

# 언더바를 카멜로 자동 변경
mybatis.configuration.map-underscore-to-camel-case=true

# 마이바티스 실행 쿼리로그
logging.level.hello.itemservice.repository.mybatis=trace
````

<br>

## MyBatis 적용
마이바티스 매핑 xml을 호출하는 매퍼 인터페이스  
@Mapper 어노테이션 인터페이스 생성필수  
파라미터 갯수가 두개 이상인 경우 @Param 어노테이션 사용  
&lt;where&gt;는 &lt;if&gt;가 하나라도 성공할 경우 where 생성, 하나만 성공한 경우 and를 where로 치환  
xml 파일에서 특수문자 사용시 마크업 언어로 변경필수, 또는 CDATA 문법   
    
    < : &lt;
    > : &gt;
    & : &amp;

<br>

[../ItemMapper.class]
````java
@Mapper
public interface ItemMapper {

  void save(Item item);

  void update(@Param("itemId") Long itemId, @Param("updateParam")ItemUpdateDto updateParam);

  List<Item> findAll(ItemSearchCond itemSearchCond);

  Optional<Item> findById(Long itemId);
}
````

<br>

[resources/../ItemMapper.xml]
````xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTO Mapper 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
        
<mapper namespace="hello.itemservice.repository.mybatis.ItemMapper">
    <insert id="save" useGeneratedKeys="true" keyProperty="itemId">
        insert into item (item_name, price, quantity)
        values(#{itemName}, #{price}, #{quantity})
    </insert>

    <update id="update">
        update item
        set item_name=#{updateParam.itemName},
            price=#{updateParam.price},
            quantity=#{updateParam.quantity}
        where item_id=#{itemId}
    </update>

    <select id="findById" resultType="Item">
        select item_id, item_name, price, quantity
        from item
        where item_id=#{itemId}
    </select>

    <select id="findAll" resultType="Item">
        select item_id, item_name, price, quantity
        from item
        <where>
            <if test="itemName != null and itemName != ''">
                and item_name like concat('%', #{itemName}, '%')
            </if>
            <if test="maxPrice != null">
                and price &lt;= #{maxPrice}
            </if>
        </where>
    </select>
</mapper>
````

<br>

## 매퍼 구현체
MybatisAutoConfiguration 클래스에서 자동으로 등록  
매퍼 구현체는 MyBatis에서 발생한 예외를 스프링 예외 추상화 DataAccessException 변환  
  
    1. 어플리케이션 로딩 시점에 MyBatis 스프링 연동 모듈은 @Mapper 어노테이션 인터페이스 탐색
    2. 해당 인터페이스에 대한 동적 프록시 구현체 생성
    3. 생성된 구현체를 스프링 빈으로 등록

<br>

## 동적 쿼리
1. if : 해당 조건에 따라 값을 추가할지 판단, 내부 문법은 OGNL 문법 사용  
````xml
<if test="title != null">
  and title like #{title}
</if>
````

<br>

2. choose(when, otherwise) : switch 구문과 유사  
````xml
<choos>
  <when test="title != null">
    and title loke #{title}
  </when>
  <otherwise>
    and featured = 1
  </otherwise>
</choose>
````

<br>

3. trim(where, set) : where와 and 치환  
````xml
<trim prefix="where" prefixOverrides="and | or">
  ...
</trim>

<where>
  <if test="state != null">
    state = #{state}
  </if>
  <if test="title != null">
    and title like #{title}
  </if>
</where>
````

<br>

4. foreach : 컬렉션 반복 처리  
````xml
<where>
  <foreach item="item" index="index" collection="list"
      open="id in (" separator="," close=")" nullable="true">
        #{item}
  </foreach>
</where>
````

<br>

5. resultMap : 별칭을 사용하지않고 객체와 테이블 매핑  
````xml
<resultMap id="userResultMap" type="User">
  <id property="id" column="user_id"/>
  <reuslt property="name" column="user_name"/>
</resultMap>

<select id="selectUsers" resultMap="userResultMap">
  ...
</select>
````

<br>
