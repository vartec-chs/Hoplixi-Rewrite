import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final routerRefreshNotifierProvider =
    NotifierProvider<RouterRefreshNotifier, int>(
        () => RouterRefreshNotifier());

class RouterRefreshNotifier extends Notifier<int> with ChangeNotifier {
  @override
  int build() {
    return 0;
  }
}
