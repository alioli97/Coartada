import 'package:coartada/core/strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solved count agrees in number', () {
    expect(const Strings('es').solvedCount(1), '1 resuelto');
    expect(const Strings('es').solvedCount(0), '0 resueltos');
    expect(const Strings('ca').solvedCount(1), '1 resolt');
    expect(const Strings('ca').solvedCount(3), '3 resolts');
    expect(const Strings('en').solvedCount(1), '1 solved');
  });
}
