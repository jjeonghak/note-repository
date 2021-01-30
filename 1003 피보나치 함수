#include<iostream>
using namespace std;

pair<int, int> cnt[41];

pair<int,int> fibo(int n) {
	if (cnt[n].first!=0||cnt[n].second!=0) return cnt[n];
	else if (n == 0) return cnt[0] = {1,0};
	else if (n == 1) return cnt[1] = {0,1};

	else return cnt[n] = { fibo(n - 1).first+fibo(n - 2).first, fibo(n - 1).second + fibo(n - 2).second };
}

int main(void) {
	int t, n;
	ios_base::sync_with_stdio(0);
	cin.tie(0);
	cin >> t;
	for (int i = 0; i < t; i++) {
		cin >> n;
		fibo(n);
		cout << cnt[n].first << " " << cnt[n].second << endl;
	}
	return 0;
}
