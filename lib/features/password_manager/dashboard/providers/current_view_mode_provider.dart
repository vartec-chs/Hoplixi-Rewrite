import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ViewMode { list, grid }

final currentViewModeProvider = Provider<ViewMode>((ref) {
  return ViewMode.list;
});
