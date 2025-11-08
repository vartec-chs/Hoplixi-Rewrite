import 'entity_type.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity_type_state.freezed.dart';

@freezed
@immutable
sealed class EntityTypeState with _$EntityTypeState {
  const factory EntityTypeState({
    required final EntityType currentType,
    required final Map<EntityType, bool> availableTypes,
  }) = _EntityTypeState;
}
