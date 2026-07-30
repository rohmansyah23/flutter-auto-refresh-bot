import 'package:flutter_test/flutter_test.dart';

import 'package:auto_refresh_browser/main.dart';

void main() {
  test('MyApp is a valid widget', () {
    expect(const MyApp(initialUrl: 'https://duckduckgo.com'), isA<MyApp>());
  });
}
