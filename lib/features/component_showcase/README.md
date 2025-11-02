# Component Showcase

Фича для демонстрации и тестирования всех кастомных UI компонентов приложения.

## Структура

```
component_showcase/
├── component_showcase_screen.dart  # Главный экран с навигацией
└── screens/                         # Экраны для каждого типа компонентов
    ├── button_showcase_screen.dart
    ├── text_field_showcase_screen.dart
    ├── slider_button_showcase_screen.dart
    └── notification_showcase_screen.dart
```

## Как использовать

Откройте Component Showcase через главный экран приложения или перейдите по роуту `/component-showcase`.

Используйте NavigationRail слева для переключения между различными категориями компонентов:
- **Buttons** - демонстрация SmoothButton с различными типами, размерами и состояниями
- **Text Fields** - примеры PrimaryTextField, PrimaryTextFormField, PasswordField
- **Slider Buttons** - интерактивные слайдеры для подтверждения действий
- **Notifications** - карточки уведомлений (ошибки, успех, инфо, предупреждения)

## Как добавить новый компонент

### Шаг 1: Создайте экран для нового компонента

Создайте файл в `lib/features/component_showcase/screens/`:

```dart
import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/your_component.dart';

class YourComponentShowcaseScreen extends StatelessWidget {
  const YourComponentShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSection(
          context,
          title: 'Basic Examples',
          children: [
            // Добавьте примеры использования вашего компонента
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
```

### Шаг 2: Добавьте импорт в главный экран

В файле `component_showcase_screen.dart`:

```dart
import 'package:hoplixi/features/component_showcase/screens/your_component_showcase_screen.dart';
```

### Шаг 3: Добавьте новый элемент в список

В методе `_showcaseItems`:

```dart
final List<ShowcaseItem> _showcaseItems = [
  // ... существующие элементы
  ShowcaseItem(
    title: 'Your Component',
    icon: Icons.your_icon,
    screen: const YourComponentShowcaseScreen(),
  ),
];
```

## Рекомендации

### Организация демо

- Группируйте примеры по категориям (типы, размеры, состояния)
- Используйте `_buildSection()` для создания секций с заголовками
- Добавляйте отступы между примерами для лучшей читаемости

### Интерактивность

- Демонстрируйте все возможные состояния компонента
- Добавляйте интерактивные примеры с callback'ами
- Используйте SnackBar для отображения результатов действий

### Примеры кода

```dart
// Плохо - нет группировки
Column(
  children: [
    YourComponent(...),
    YourComponent(...),
    YourComponent(...),
  ],
)

// Хорошо - четкая структура
_buildSection(
  context,
  title: 'Component Types',
  children: [
    YourComponent(type: TypeA()),
    const SizedBox(height: 12),
    YourComponent(type: TypeB()),
  ],
)
```

## Доступ к Showcase

- **Из кода**: `context.push(AppRoutesPaths.componentShowcase)`
- **Из UI**: Главный экран → "Component Showcase"

## Полезные паттерны

### Демонстрация состояний с использованием StatefulWidget

```dart
class _YourShowcaseScreenState extends State<YourComponentShowcaseScreen> {
  String _lastAction = 'No action yet';

  void _handleAction(String action) {
    setState(() {
      _lastAction = action;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(action)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Отображение последнего действия
        Container(
          padding: const EdgeInsets.all(16),
          child: Text('Last action: $_lastAction'),
        ),
        // Примеры компонентов
        YourComponent(
          onAction: () => _handleAction('Action performed!'),
        ),
      ],
    );
  }
}
```

### Форма с валидацией

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      YourFormComponent(
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Field is required';
          }
          return null;
        },
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // Форма валидна
          }
        },
        child: const Text('Submit'),
      ),
    ],
  ),
)
```

## TODO

- [ ] Добавить поддержку темной/светлой темы переключателя
- [ ] Добавить возможность копирования кода примеров
- [ ] Добавить поиск по компонентам
- [ ] Добавить экспорт примеров
