import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';

/// Волнообразный clipper для анимации переключения темы
/// Создает красивую спиральную волну с пульсацией и звёздным эффектом
class WaveThemeSwitcherClipper implements ThemeSwitcherClipper {
  /// Количество волн (лучей)
  final int waveCount;

  /// Амплитуда волны (высота волны)
  final double amplitude;

  /// Добавить эффект спирали
  final bool spiralEffect;

  /// Добавить звёздный эффект (острые углы)
  final bool starEffect;

  const WaveThemeSwitcherClipper({
    this.waveCount = 3,
    this.amplitude = 30.0,
    this.spiralEffect = true,
    this.starEffect = false,
  });

  @override
  Path getClip(Size size, Offset offset, double sizeRate) {
    final path = Path();

    // Радиус волны (основной)
    final baseRadius = size.width * sizeRate;

    // Начинаем с центра
    final centerX = offset.dx;
    final centerY = offset.dy;

    // Плавность перехода (для более гладких волн в начале)
    final smoothFactor = math.min(1.0, sizeRate * 2);

    // Создаем волнообразный путь с улучшенной анимацией
    for (double angle = 0; angle <= 360; angle += 3) {
      final radian = angle * math.pi / 180;

      // Базовая волна с синусоидой
      var waveOffset =
          amplitude *
          smoothFactor *
          (1 - sizeRate * 0.5) *
          math.sin(angle * waveCount * math.pi / 180);

      // Добавляем спиральный эффект
      if (spiralEffect) {
        final spiralOffset =
            amplitude *
            0.3 *
            smoothFactor *
            math.sin(angle * math.pi / 90 + sizeRate * math.pi * 2);
        waveOffset += spiralOffset;
      }

      // Добавляем звёздный эффект (острые лучи)
      if (starEffect) {
        final starMod = angle % (360 / waveCount);
        final starPeak = math.exp(
          -math.pow(starMod - 180 / waveCount, 2) / 500,
        );
        waveOffset += amplitude * 0.5 * starPeak * (1 - sizeRate);
      }

      // Добавляем пульсацию (биение)
      final pulseOffset =
          amplitude *
          0.2 *
          smoothFactor *
          math.sin(sizeRate * math.pi * 4) *
          math.cos(angle * math.pi / 180);

      // Финальный радиус с всеми эффектами
      final finalRadius = baseRadius + waveOffset + pulseOffset;

      // Координаты точки
      final x = centerX + finalRadius * math.cos(radian);
      final y = centerY + finalRadius * math.sin(radian);

      if (angle == 0) {
        path.moveTo(x, y);
      } else {
        // Используем quadraticBezierTo для более плавных кривых
        final prevAngle = (angle - 3) * math.pi / 180;
        final prevRadius =
            baseRadius +
            amplitude *
                smoothFactor *
                (1 - sizeRate * 0.5) *
                math.sin((angle - 3) * waveCount * math.pi / 180);

        final prevX = centerX + prevRadius * math.cos(prevAngle);
        final prevY = centerY + prevRadius * math.sin(prevAngle);

        // Контрольная точка для плавной кривой
        final controlX = (prevX + x) / 2;
        final controlY = (prevY + y) / 2;

        path.quadraticBezierTo(controlX, controlY, x, y);
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
