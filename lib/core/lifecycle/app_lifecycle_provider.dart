import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

class AppLifecycleNotifier extends Notifier<AppLifecycleState> {
  @override
  AppLifecycleState build() {
    return AppLifecycleState.resumed;
  }

  void onDetach() {
    logInfo('App lifecycle: detached', tag: 'AppLifecycle');
    state = AppLifecycleState.detached;
  }

  void onHide() {
    logInfo('App lifecycle: hidden', tag: 'AppLifecycle');
    state = AppLifecycleState.hidden;
  }

  void onInactive() {
    logInfo('App lifecycle: inactive', tag: 'AppLifecycle');
    state = AppLifecycleState.inactive;
  }

  void onPause() {
    logInfo('App lifecycle: paused', tag: 'AppLifecycle');
    state = AppLifecycleState.paused;
  }

  void onRestart() {
    logInfo('App lifecycle: restarted', tag: 'AppLifecycle');
  }

  void onResume() {
    logInfo('App lifecycle: resumed', tag: 'AppLifecycle');
    state = AppLifecycleState.resumed;
  }

  void onShow() {
    logInfo('App lifecycle: shown', tag: 'AppLifecycle');
  }

  Future<AppExitResponse> onExitRequested() async {
    logInfo('App lifecycle: exit requested', tag: 'AppLifecycle');
    return AppExitResponse.exit;
  }
}

final appLifecycleProvider =
    NotifierProvider<AppLifecycleNotifier, AppLifecycleState>(
      AppLifecycleNotifier.new,
    );
