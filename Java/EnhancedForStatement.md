## for-each
컬렉션이나 배열에 상관없이 코드 형태 동일  
여러 반복자와 인덱스 변수 사용없이 바로 컨테이너 원소에 접근  

````java
//전통적 컬렉션 순회
for (Iterator<Element> i = c.iterator(); i.hasNext(); )

//전통적 배열 순회
for (int i = 0; i < a.length; i++)

//컬렉션과 배열을 순회하는 올바른 관용구
for (Element e : elements)

//동일한 결과 - 코드 비교
for (Suit suit : suits)
  for (Rank rank : ranks)
      deck.add(new Card(suit, rank));

for (Iterator<Suit> i = suits.iterator(); i.hasNext(); ) {
    Suit suit = i.next();
    for (Iterator<Rank> j = ranks.iterator(); j.hasNext(); )
        deck.add(new Card(suit, j.next()));
}
````    

<br>

## for-each 제한사항
아래의 상황은 전통적인 for 방식 사용  
  
1. 파괴적인 필터링(destructive filtering)  
    컬렉션을 순회하면서 선택된 원소를 제거하는 경우(remove 호출)  
  
2. 변형(transforming)  
    리스트나 배열을 순회하면서 그 원소의 값 일부 혹은 전체를 교체하는 경우  

3. 병렬 반복(parallel iteration)  
    여러 컬렉션을 병렬로 순회하는 경우  

<br>


