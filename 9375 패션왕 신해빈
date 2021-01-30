#include<iostream>
#include<map>
using namespace std;

int main(void) {
	int t, n;
	string a, b;
	map<string, int> m;
	pair<map<string, int>::iterator, bool> p; //반복자도 자료형
	cin >> t;
	for (int i = 0; i < t; i++) {
		m.clear(); //맵 초기화
		int c = 1;
		cin >> n;
		for (int j = 0; j < n; j++) {
			cin >> a >> b;
			p = m.insert(pair<string, int>(b, 1)); //맵에 데이터 삽입
			if (!p.second) m[b]++; //p.second는 항상 0이므로 호출될때마다 m.second +1
		}
		map<string, int>::iterator j;
		for (j = m.begin(); j != m.end(); j++) {
			c *= (j->second + 1); //(같은 종류 의상의 수+1), +1은 안입는 경우 포함
		}
		cout << c - 1 << endl; //다 안입는 경우 1을 제외
	}
	return 0;
}
