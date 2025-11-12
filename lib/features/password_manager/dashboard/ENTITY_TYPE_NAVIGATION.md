# Entity Type Navigation Flow

## Overview
Навигация для создания разных типов сущностей зависит от выбранного типа в `entityTypeProvider`.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│         DashboardLayout (ConsumerStatefulWidget)        │
│  ┌───────────────────────────────────────────────────┐  │
│  │ watch: entityTypeProvider                         │  │
│  │ _entityName = entityTypeState.currentType.label   │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  _onCreateEntity() {                                   │
│    switch(currentType) {                               │
│      case password: go(/dashboard/password/create)    │
│      case note: go(/dashboard/note/create)            │
│      case bankCard: go(/dashboard/bankcard/create)    │
│      case file: go(/dashboard/file/create)            │
│      case otp: go(/dashboard/otp/create)              │
│    }                                                   │
│  }                                                     │
│                                                         │
│  ├── ExpandableFAB (desktop)                          │
│  │   └── onCreateEntity -> _onCreateEntity()         │
│  │                                                    │
│  └── ExpandableFAB (mobile)                           │
│      └── onCreateEntity -> _onCreateEntity()         │
│                                                         │
│                   ↓                                     │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │      DashboardHomeScreen (ConsumerStatefulWidget) │  │
│  │  ┌───────────────────────────────────────────────┐ │  │
│  │  │ DashboardSliverAppBar                         │ │  │
│  │  │ └── EntityTypeCompactDropdown                 │ │  │
│  │  │     └── onChanged: selectType(type)           │ │  │
│  │  │         Updates entityTypeProvider            │ │  │
│  │  └───────────────────────────────────────────────┘ │  │
│  │                                                     │  │
│  │  watch: paginatedListProvider                     │  │
│  │  watch: currentViewModeProvider                   │  │
│  │  watch: entityTypeProvider.currentType            │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Flow Diagram

```
1. User selects entity type from dropdown in AppBar
   ↓
   EntityTypeCompactDropdown.onChanged()
   ↓
   ref.read(entityTypeProvider.notifier).selectType(newType)
   ↓
   entityTypeProvider state updated

2. DashboardLayout.build() watches entityTypeProvider
   ↓
   _entityName = currentType.label
   ↓
   ExpandableFAB displays updated label

3. User clicks FAB to create entity
   ↓
   _onCreateEntity() called
   ↓
   Switch on entityTypeState.currentType
   ↓
   Navigate to appropriate screen:
      - password → /dashboard/password/create
      - note → /dashboard/note/create (TODO)
      - bankCard → /dashboard/bankcard/create (TODO)
      - file → /dashboard/file/create (TODO)
      - otp → /dashboard/otp/create (TODO)

4. Form screen opened for specific entity type
```

## File Structure

```
lib/features/password_manager/dashboard/
├── models/
│   ├── entity_type.dart              # Enum with 5 types
│   └── entity_type_state.dart        # Freezed state for provider
├── providers/
│   └── entity_type_provider.dart     # NotifierProvider
├── widgets/
│   ├── dashboard_layout.dart         # ConsumerStatefulWidget
│   │   └── _onCreateEntity()         # Navigation logic
│   └── dashboard_home/
│       ├── entity_type_dropdown.dart # 2 dropdown widgets
│       │   └── EntityTypeCompactDropdown
│       └── app_bar/
│           └── app_bar.dart          # Uses dropdown
└── screens/
    └── dashboard_home_screen.dart    # Main screen with list
```

## Key Components

### 1. Entity Type Enum (`entity_type.dart`)
```dart
enum EntityType {
  password('password', 'Пароли', Icons.lock),
  note('note', 'Заметки', Icons.note),
  bankCard('bank_card', 'Банковские карты', Icons.credit_card),
  file('file', 'Файлы', Icons.attach_file),
  otp('otp', 'OTP/2FA', Icons.security);
}
```

### 2. Entity Type Provider (`entity_type_provider.dart`)
```dart
final entityTypeProvider = NotifierProvider<...>(EntityTypeNotifier.new);

class EntityTypeNotifier extends Notifier<EntityTypeState> {
  @override
  EntityTypeState build() {
    return EntityTypeState(
      currentType: EntityType.password,
      availableTypes: {for (final type in EntityType.values) type: true},
    );
  }
  
  void selectType(EntityType type) {
    state = state.copyWith(currentType: type);
  }
}
```

### 3. Dashboard Layout Updates (`dashboard_layout.dart`)
```dart
class DashboardLayout extends ConsumerStatefulWidget {
  void _onCreateEntity() {
    final entityTypeState = ref.read(entityTypeProvider);
    
    switch (entityTypeState.currentType) {
      case EntityType.password:
        context.go(AppRoutesPaths.dashboardPasswordCreate);
      case EntityType.note:
        // TODO: Implement
      case EntityType.bankCard:
        // TODO: Implement
      case EntityType.file:
        // TODO: Implement
      case EntityType.otp:
        // TODO: Implement
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final entityTypeState = ref.watch(entityTypeProvider);
    _entityName = entityTypeState.currentType.label;
    
    // FAB uses _onCreateEntity as callback
  }
}
```

### 4. Entity Type Dropdown (`entity_type_dropdown.dart`)
```dart
class EntityTypeCompactDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityTypeState = ref.watch(entityTypeProvider);
    
    return DropdownButton<EntityType>(
      value: entityTypeState.currentType,
      onChanged: (EntityType? newType) {
        if (newType != null) {
          ref.read(entityTypeProvider.notifier).selectType(newType);
          onEntityTypeChanged?.call(newType);
        }
      },
    );
  }
}
```

## State Flow

```
User selects "Заметки" from dropdown
         ↓
EntityTypeState.currentType = EntityType.note
         ↓
DashboardLayout watches provider and updates _entityName = "Заметки"
         ↓
FAB displays "Заметки" label
         ↓
User clicks FAB
         ↓
_onCreateEntity() reads current type
         ↓
switch(note) → context.go(/dashboard/note/create)
         ↓
(TODO) Note form screen opened
```

## Implementation Status

✅ **Completed:**
- EntityType enum with 5 types
- EntityTypeProvider with NotifierProvider pattern
- EntityTypeCompactDropdown integrated in AppBar
- DashboardLayout converted to ConsumerStatefulWidget
- _onCreateEntity navigation logic implemented

✅ **Password:** `/dashboard/password/create` → PasswordFormScreen

⏳ **TODO - Form Screens:**
- Note: `/dashboard/note/create`
- Bank Card: `/dashboard/bankcard/create`
- File: `/dashboard/file/create`
- OTP: `/dashboard/otp/create`

⏳ **TODO - Routes:**
Add paths and routes for:
```dart
// paths.dart
static const String dashboardNoteCreate = '/dashboard/note/create';
static const String dashboardBankCardCreate = '/dashboard/bankcard/create';
static const String dashboardFileCreate = '/dashboard/file/create';
static const String dashboardOtpCreate = '/dashboard/otp/create';

// routes.dart
GoRoute(path: AppRoutesPaths.dashboardNoteCreate, builder: ...),
// etc.
```

## Usage Example

```dart
// In DashboardLayout FAB action
void _onCreateEntity() {
  final currentType = ref.read(entityTypeProvider).currentType;
  
  // Navigate based on selected type
  switch(currentType) {
    case EntityType.password:
      context.go(AppRoutesPaths.dashboardPasswordCreate);
      // Opens PasswordFormScreen
    case EntityType.note:
      context.go(AppRoutesPaths.dashboardNoteCreate);
      // Will open NoteFormScreen (TODO)
    // ...
  }
}
```

## Testing

Test navigation:
1. Select "Пароли" from dropdown → Click FAB → Opens PasswordFormScreen ✓
2. Select "Заметки" from dropdown → Click FAB → Should navigate to NoteFormScreen
3. Verify FAB label changes based on selection
4. Verify entityTypeProvider state updates correctly
