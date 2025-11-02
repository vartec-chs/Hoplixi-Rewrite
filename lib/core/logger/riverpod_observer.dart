import 'package:riverpod/src/framework.dart';

import 'app_logger.dart';

final class LoggingProviderObserver extends ProviderObserver {
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    logInfo(
      '[RIVERPOD] ➕ ADD   ${context.provider.name ?? context.provider.runtimeType} = $value',
      tag: 'Riverpod',
    );
    super.didAddProvider(context, value);
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    logInfo(
      '[RIVERPOD] ❌ DISPOSE ${context.provider.name ?? context.provider.runtimeType}',
      tag: 'Riverpod',
    );
    super.didDisposeProvider(context);
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    logInfo(
      '[RIVERPOD] ⬆️ UPDATE ${context.provider.name ?? context.provider.runtimeType}: $previousValue → $newValue',
      tag: 'Riverpod',
    );
    super.didUpdateProvider(context, previousValue, newValue);
  }

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    logError(
      '[RIVERPOD] ⚠️ ERROR  ${context.provider.name ?? context.provider.runtimeType}: $error',
      stackTrace: stackTrace,
      tag: 'Riverpod',
    );
    super.providerDidFail(context, error, stackTrace);
  }

  void didFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    logError(
      '[RIVERPOD] ⚠️ ERROR  ${provider.name ?? provider.runtimeType}: $error',
      stackTrace: stackTrace,
      tag: 'Riverpod',
    );
  }

  @override
  void mutationSuccess(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
    Object? result,
  ) {
    logInfo(
      '[RIVERPOD] ✅ MUTATION ${context.provider.name ?? context.provider.runtimeType}: $mutation → $result',
      tag: 'Riverpod',
    );
    super.mutationSuccess(context, mutation, result);
  }

  @override
  void mutationError(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
    Object error,
    StackTrace stackTrace,
  ) {
    logError(
      '[RIVERPOD] ⚠️ MUTATION ERROR ${context.provider.name ?? context.provider.runtimeType}: $mutation → $error',
      stackTrace: stackTrace,
      tag: 'Riverpod',
    );
    super.mutationError(context, mutation, error, stackTrace);
  }

  @override
  void mutationReset(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
  ) {
    logInfo(
      '[RIVERPOD] 🔄 MUTATION RESET ${context.provider.name ?? context.provider.runtimeType}: $mutation',
      tag: 'Riverpod',
    );
    super.mutationReset(context, mutation);
  }

  @override
  void mutationStart(
    ProviderObserverContext context,
    Mutation<Object?> mutation,
  ) {
    logInfo(
      '[RIVERPOD] 🔄 MUTATION START ${context.provider.name ?? context.provider.runtimeType}: $mutation',
      tag: 'Riverpod',
    );
    super.mutationStart(context, mutation);
  }
}
