import 'package:flutter/material.dart';

/// Универсальный компонент для отображения индикаторов статуса карточки
/// (закреплено, избранное, архив)
class CardStatusIndicators extends StatelessWidget {
  /// Флаг закрепления
  final bool isPinned;

  /// Флаг избранного
  final bool isFavorite;

  /// Флаг архивации
  final bool isArchived;

  /// Смещение сверху
  final double top;

  /// Начальное смещение слева
  final double left;

  /// Расстояние между индикаторами
  final double spacing;

  const CardStatusIndicators({
    super.key,
    required this.isPinned,
    required this.isFavorite,
    required this.isArchived,
    this.top = 2,
    this.left = 8,
    this.spacing = 26,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> indicators = [];
    double currentLeft = left;

    if (isPinned) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(Icons.push_pin, size: 20, color: Colors.orange),
          ),
        ),
      );
      currentLeft += spacing;
    }

    if (isFavorite) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(Icons.star, size: 18, color: Colors.amber),
          ),
        ),
      );
      currentLeft += spacing;
    }

    if (isArchived) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(Icons.archive, size: 18, color: Colors.blueGrey),
          ),
        ),
      );
    }

    return Stack(children: indicators);
  }

  /// Строит список Positioned виджетов для использования в Stack
  List<Widget> buildPositionedWidgets() {
    final List<Widget> indicators = [];
    double currentLeft = left;

    if (isPinned) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(Icons.push_pin, size: 20, color: Colors.orange),
          ),
        ),
      );
      currentLeft += spacing;
    }

    if (isFavorite) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(Icons.star, size: 18, color: Colors.amber),
          ),
        ),
      );
      currentLeft += spacing;
    }

    if (isArchived) {
      indicators.add(
        Positioned(
          top: top,
          left: currentLeft,
          child: Transform.rotate(
            angle: -0.52,
            child: const Icon(Icons.archive, size: 18, color: Colors.blueGrey),
          ),
        ),
      );
    }

    return indicators;
  }
}
