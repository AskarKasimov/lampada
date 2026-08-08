import 'package:flutter_test/flutter_test.dart';
import 'package:lampada/core/network/remote_fetch_exception.dart';
import 'package:lampada/core/result/result.dart';

void main() {
  test('хранит вид и первопричину сетевого сбоя', () {
    final error = RemoteFetchException(FailureKind.network, 'offline');

    expect(error.kind, FailureKind.network);
    expect(error.cause, 'offline');
  });
}
