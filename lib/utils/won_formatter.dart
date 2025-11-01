String formatWon(int value) {
  final s = value.toString();
  final b = StringBuffer();

  for (int i = 0; i < s.length; i++) {
    final k = s.length - i; // 남은 자릿수
    b.write(s[i]);

    // 세 자리씩 끊기
    if (k > 1 && k % 3 == 1) {
      b.write(',');
    }
  }

  return b.toString();
}
