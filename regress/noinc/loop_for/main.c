int sum(int n) {
	int i, sum = 0;

	for (i = 1; i <= n; i++) {
		sum = sum + i;
	}

	return sum;
}

int main() {
	return sum(5) - 15;
}
