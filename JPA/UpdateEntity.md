## 준영속 엔티티
영속성 컨텍스트가 더이상 관리하지 않는 엔티티  
임의로 생성한 엔티티 객체에 기존 식별자를 주입한 경우  
준영속 엔티티 수정  

    1. 변경감지
    2. 병합

<br>

## 변경감지(dirty checking)
식별자에 맞는 영속성 엔티티를 직접 가져와서 파라미터 엔티티의 정보로 수정  
원하는 속성만 성택해서 변경가능, 실무 추천  

````java
@Transactional
public void updateEntityByDirtyChecking(Long id, Entity entityForm) {
    Entity findEntity = EntityRepository.findOne(id);
    findEntity.setParam(entityForm.getParam());
}
````

<br>

## 병합(merge)
식별자를 이용해서 데이터베이스 엔티티의 모든 정보를 파라미터 엔티티의 정보로 수정  
한번 수정에 모든 속성 변경, 속성값 없으면 null 값  
````java
@Transactional
public Entity updateEntityByMerge (Entity entity) {
    return Entity mergeEntity = em.merge(entity)
}
````

### 동작방식
1. 파라미터로 넘어온 준영속 엔티티의 식별자 값으로 1타 캐시에서 엔티티 조회  
2. 1차 캐시에 없는 경우 데이터베이스에서 엔티티 조회 후 1차 캐시에 저장  
3. 조회한 영속 엔티티에 준영속 엔티티의 값으로 모든 정보 수정  
4. 영속 엔티티 반환  

<br>

