# Theme Switcher Clippers

Красивые кастомные clippers для анимации переключения темы в приложении Hoplixi.

## Доступные Clippers

### 1. WaveThemeSwitcherClipper (Волны)
Создает волнообразную анимацию с различными эффектами.

**Параметры:**
- `waveCount` - количество волн/лучей (default: 3)
- `amplitude` - амплитуда волны (default: 30.0)
- `spiralEffect` - эффект спирали (default: true)
- `starEffect` - звёздный эффект с острыми углами (default: false)

**Примеры использования:**

```dart
// Мягкие волны с спиралью
const WaveThemeSwitcherClipper(
  waveCount: 5,
  amplitude: 40.0,
  spiralEffect: true,
  starEffect: false,
)

// Звёздный эффект
const WaveThemeSwitcherClipper(
  waveCount: 6,
  amplitude: 25.0,
  spiralEffect: false,
  starEffect: true,
)

// Комбинированный эффект (максимальная красота!)
const WaveThemeSwitcherClipper(
  waveCount: 8,
  amplitude: 50.0,
  spiralEffect: true,
  starEffect: true,
)
```

### 2. FlowerThemeSwitcherClipper (Цветок)
Создает эффект раскрывающегося цветка с лепестками.

**Параметры:**
- `petalCount` - количество лепестков (default: 6)
- `petalSize` - размер лепестков (default: 0.4)

**Пример:**
```dart
const FlowerThemeSwitcherClipper(
  petalCount: 8,
  petalSize: 0.5,
)
```

### 3. HeartThemeSwitcherClipper (Сердце)
Создает форму сердца, расширяющегося от центра.

**Пример:**
```dart
const HeartThemeSwitcherClipper()
```

### 4. PolygonThemeSwitcherClipper (Многоугольник)
Создает вращающийся многоугольник.

**Параметры:**
- `sides` - количество сторон (default: 6)
- `rotate` - вращение во время анимации (default: true)

**Примеры:**
```dart
// Шестиугольник с вращением
const PolygonThemeSwitcherClipper(sides: 6, rotate: true)

// Треугольник без вращения
const PolygonThemeSwitcherClipper(sides: 3, rotate: false)

// Восьмиугольник
const PolygonThemeSwitcherClipper(sides: 8, rotate: true)
```

## Использование в ThemeSwitcher

```dart
animated_theme.ThemeSwitcher.switcher(
  clipper: const WaveThemeSwitcherClipper(
    waveCount: 5,
    amplitude: 40.0,
    spiralEffect: true,
  ),
  builder: (context, switcher) {
    return YourWidget(
      onTap: () => switcher.changeTheme(
        theme: newTheme,
        isReversed: isDark,
      ),
    );
  },
);
```

## Особенности

- ✨ **Плавные анимации** - используют quadraticBezierTo для мягких кривых
- 🎨 **Настраиваемые эффекты** - комбинируйте различные параметры
- 🌊 **Пульсация** - добавляет динамику в анимацию
- ⭐ **Звёздный эффект** - острые лучи для драматичности
- 🌀 **Спиральный эффект** - закручивающееся движение
- 💚 **Производительность** - оптимизированы для 60 FPS

## Рекомендации

- Для **быстрых переходов** используйте малые значения `amplitude` (20-30)
- Для **драматичных эффектов** увеличьте `waveCount` (6-10) и `amplitude` (40-60)
- **FlowerThemeSwitcherClipper** отлично подходит для романтичных тем
- **PolygonThemeSwitcherClipper** идеален для минималистичных дизайнов
- **HeartThemeSwitcherClipper** - для особых случаев 💝
