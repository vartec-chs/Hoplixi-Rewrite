import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';

/// Цветочный clipper с лепестками
/// Создает эффект раскрывающегося цветка
class FlowerThemeSwitcherClipper implements ThemeSwitcherClipper {
  /// Количество лепестков
  final int petalCount;

  /// Размер лепестков
  final double petalSize;

  const FlowerThemeSwitcherClipper({this.petalCount = 6, this.petalSize = 0.4});

  @override
  Path getClip(Size size, Offset offset, double sizeRate) {
    final path = Path();
    final baseRadius = size.width * sizeRate;
    final centerX = offset.dx;
    final centerY = offset.dy;

    for (double angle = 0; angle <= 360; angle += 2) {
      final radian = angle * math.pi / 180;

      // Создаём лепестки с помощью синусоиды
      final petalMod = math.sin(angle * petalCount * math.pi / 360);
      final petalRadius =
          baseRadius * (1 + petalSize * petalMod * (1 - sizeRate * 0.5));

      final x = centerX + petalRadius * math.cos(radian);
      final y = centerY + petalRadius * math.sin(radian);

      if (angle == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(
    CustomClipper<Path> oldClipper,
    Offset? offset,
    double? sizeRate,
  ) {
    return true;
  }
}

/// Сердечный clipper
/// Создает форму сердца, расширяющегося от центра
class HeartThemeSwitcherClipper implements ThemeSwitcherClipper {
  const HeartThemeSwitcherClipper();

  @override
  Path getClip(Size size, Offset offset, double sizeRate) {
    final path = Path();
    final scale = size.width * sizeRate * 0.5;
    final centerX = offset.dx;
    final centerY = offset.dy;

    // Параметрическое уравнение сердца
    for (double t = 0; t <= 2 * math.pi; t += 0.02) {
      final x = 16 * math.pow(math.sin(t), 3);
      final y =
          -(13 * math.cos(t) -
              5 * math.cos(2 * t) -
              2 * math.cos(3 * t) -
              math.cos(4 * t));

      final scaledX = centerX + x * scale / 20;
      final scaledY = centerY + y * scale / 20;

      if (t == 0) {
        path.moveTo(scaledX, scaledY);
      } else {
        path.lineTo(scaledX, scaledY);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(
    CustomClipper<Path> oldClipper,
    Offset? offset,
    double? sizeRate,
  ) {
    return true;
  }
}

/// Многоугольный clipper с вращением
/// Создает вращающийся многоугольник
class PolygonThemeSwitcherClipper implements ThemeSwitcherClipper {
  /// Количество сторон
  final int sides;

  /// Угол вращения
  final bool rotate;

  const PolygonThemeSwitcherClipper({this.sides = 6, this.rotate = true});

  @override
  Path getClip(Size size, Offset offset, double sizeRate) {
    final path = Path();
    final radius = size.width * sizeRate;
    final centerX = offset.dx;
    final centerY = offset.dy;

    // Вращение во время анимации
    final rotationOffset = rotate ? sizeRate * math.pi * 2 : 0.0;

    for (int i = 0; i <= sides; i++) {
      final angle = (i * 2 * math.pi / sides) + rotationOffset;
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(
    CustomClipper<Path> oldClipper,
    Offset? offset,
    double? sizeRate,
  ) {
    return true;
  }
}
