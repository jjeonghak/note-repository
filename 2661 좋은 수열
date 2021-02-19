#include<iostream>
#include<string>
using namespace std;

int n;
bool END;

bool check(string a) { //좋은 수열 조건
	int start = a.length() - 1;
	for (int i = 1; i <= a.length() / 2; i++) {
		string b = a.substr(start - i, i);
		string c = a.substr(start, i);
		if (b.compare(c) == 0) return false;
		start--;
	}
	return true;
}

void sol(int len, string a) {
	if (END) return; //이미 끝을 봤으므로 나머지는 종료
	if (!check(a)) return; //조건을 만족시키지 못하면 종료
	if (len == n) { //끝
		END = true;
		cout << a;
		return;
	}
	sol(len + 1, a + "1");
	sol(len + 1, a + "2");
	sol(len + 1, a + "3");
}

int main(void) {
	cin >> n;
	sol(1, "1");
	return 0;
}
