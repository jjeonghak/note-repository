## 기본 정보
등록일, 수정일, 등록자, 수정자 등  

<br>

## JPA
@PrePersist, @PostPersist, @PreUpdate, @PostUpdate 등의 어노테이션으로 설정    

````java
@MappedSuperclass
@Getter
public class JpaBaseEntity {
    @Column(updatable = false, insertable = true)  //수정불가
    private LocalDateTime createDate;
    private LocalDateTime updateDate;

    @PrePersist
    public void prePersist() {
        LocalDateTime now = LocalDateTime.now();
        this.createDate = now;
        this.updateDate = now;
    }

    @PreUpdate
    public void preUpdate() {
        this.updateDate = LocalDateTime.now();
    }
}
````

<br>

## Data Jpa
스프링 부트 설정 클래스에 @EnableJpaAuding 어노테이션 적용  
스프링 부트 설정 클래스에 생성자 및 수정자 정보 설정 메서드 필요  

````java
@Bean
public AuditorAware<String> auditorProvider() {
  return () -> Optional.of(UUID.randomUUID().toString());
}

@EntityListeners(AuditingEntityListener.class)
@MappedSuperclass
@Getter
public class BaseEntity {
    @CreatedDate
    @Column(updatable = false, insertable = true)
    private LocalDateTime createDate;

    @LastModifiedDate
    private LocalDateTime lastModifiedDate;

    @CreatedBy
    @Column(updatable = false, insertable = true)
    private String createdBy;

    @LastModifiedBy
    private String lastModifiedBy;
}
````

<br>

## xml 

[META-INF/orm.xml]
````xml
<?xml version=“1.0” encoding="UTF-8”?>
<entity-mappings xmlns=“http://xmlns.jcp.org/xml/ns/persistence/orm”
                 xmlns:xsi=“http://www.w3.org/2001/XMLSchema-instance”
                 xsi:schemaLocation=“http://xmlns.jcp.org/xml/ns/persistence/
orm http://xmlns.jcp.org/xml/ns/persistence/orm_2_2.xsd”
                 version=“2.2">
    <persistence-unit-metadata>
        <persistence-unit-defaults>
            <entity-listeners>
                <entity-listener
class="org.springframework.data.jpa.domain.support.AuditingEntityListener”/>
            </entity-listeners>
        </persistence-unit-defaults>
    </persistence-unit-metadata>
</entity-mappings>
````

<br>


