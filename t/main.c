int add(int *array, int len) {
	int i, n;
	for (i = 0, n = 0; i < len; i++) {
		n += array[i];
	}
	return n;
}

/* block comment */

int main() {
	int b = 44;
	int k, i;
	float e = 00.1;
	const int a = 5, c = 12;

	// this is a line comment

	for (k = 12; i < 12; i++) {
		if (a)
			if (b) 1+2;
			else if (a) 3+1;
			else {
				1+1;
			}
	}

	return 0;
}
