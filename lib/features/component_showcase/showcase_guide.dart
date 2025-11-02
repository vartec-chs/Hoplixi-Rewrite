import 'package:flutter/material.dart';

/// Пример использования Component Showcase для быстрого старта
class ComponentShowcaseExample extends StatelessWidget {
  const ComponentShowcaseExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

/// ============================================================================
/// БЫСТРЫЙ СТАРТ: Как добавить новый компонент в Showcase
/// ============================================================================
///
/// 1. Создайте файл экрана:
///    lib/features/component_showcase/screens/my_component_showcase_screen.dart
///
/// 2. Шаблон экрана:
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:hoplixi/shared/ui/my_component.dart';
///
/// class MyComponentShowcaseScreen extends StatelessWidget {
///   const MyComponentShowcaseScreen({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     return ListView(
///       padding: const EdgeInsets.all(24),
///       children: [
///         _buildSection(
///           context,
///           title: 'Basic Examples',
///           children: [
///             MyComponent(text: 'Example 1'),
///             const SizedBox(height: 12),
///             MyComponent(text: 'Example 2'),
///           ],
///         ),
///       ],
///     );
///   }
///
///   Widget _buildSection(
///     BuildContext context, {
///     required String title,
///     required List<Widget> children,
///   }) {
///     return Column(
///       crossAxisAlignment: CrossAxisAlignment.start,
///       children: [
///         Text(
///           title,
///           style: Theme.of(context).textTheme.titleLarge?.copyWith(
///                 fontWeight: FontWeight.bold,
///               ),
///         ),
///         const SizedBox(height: 16),
///         ...children,
///       ],
///     );
///   }
/// }
/// ```
///
/// 3. Добавьте импорт в component_showcase_screen.dart:
///
/// ```dart
/// import 'package:hoplixi/features/component_showcase/screens/my_component_showcase_screen.dart';
/// ```
///
/// 4. Добавьте элемент в _showcaseItems:
///
/// ```dart
/// final List<ShowcaseItem> _showcaseItems = [
///   // ... существующие элементы ...
///   ShowcaseItem(
///     title: 'My Component',
///     icon: Icons.widgets,
///     screen: const MyComponentShowcaseScreen(),
///   ),
/// ];
/// ```
///
/// 5. Готово! Ваш компонент появится в списке слева
///
/// ============================================================================
/// ПАТТЕРНЫ И ПРИМЕРЫ
/// ============================================================================
///
/// === Интерактивный пример с состоянием ===
///
/// ```dart
/// class MyShowcaseScreen extends StatefulWidget {
///   const MyShowcaseScreen({super.key});
///
///   @override
///   State<MyShowcaseScreen> createState() => _MyShowcaseScreenState();
/// }
///
/// class _MyShowcaseScreenState extends State<MyShowcaseScreen> {
///   String _result = 'No action yet';
///
///   void _handleAction(String action) {
///     setState(() => _result = action);
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text(action)),
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ListView(
///       padding: const EdgeInsets.all(24),
///       children: [
///         Container(
///           padding: const EdgeInsets.all(16),
///           decoration: BoxDecoration(
///             color: Theme.of(context).colorScheme.surfaceContainerHighest,
///             borderRadius: BorderRadius.circular(12),
///           ),
///           child: Text('Result: $_result'),
///         ),
///         const SizedBox(height: 24),
///         MyComponent(
///           onPressed: () => _handleAction('Button pressed!'),
///         ),
///       ],
///     );
///   }
/// }
/// ```
///
/// === Пример с формой ===
///
/// ```dart
/// final _formKey = GlobalKey<FormState>();
///
/// Form(
///   key: _formKey,
///   child: Column(
///     children: [
///       MyFormComponent(
///         validator: (value) {
///           if (value?.isEmpty ?? true) return 'Required';
///           return null;
///         },
///       ),
///       const SizedBox(height: 16),
///       FilledButton(
///         onPressed: () {
///           if (_formKey.currentState!.validate()) {
///             ScaffoldMessenger.of(context).showSnackBar(
///               const SnackBar(content: Text('Valid!')),
///             );
///           }
///         },
///         child: const Text('Validate'),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// === Пример с dismiss функционалом ===
///
/// ```dart
/// class _MyShowcaseScreenState extends State<MyShowcaseScreen> {
///   final List<String> _dismissed = [];
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         if (!_dismissed.contains('item1'))
///           MyComponent(
///             onDismiss: () => setState(() => _dismissed.add('item1')),
///           ),
///         if (_dismissed.isNotEmpty)
///           FilledButton(
///             onPressed: () => setState(() => _dismissed.clear()),
///             child: const Text('Show All'),
///           ),
///       ],
///     );
///   }
/// }
/// ```
///
/// ============================================================================
