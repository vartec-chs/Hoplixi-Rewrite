import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';

/// Виджет карточки иконки
class IconCard extends StatelessWidget {
  final IconCardDto icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const IconCard({super.key, required this.icon, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Иконка
              Expanded(child: Center(child: _buildIcon())),
              const SizedBox(height: 8),
              // Название
              Text(
                icon.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              // Тип иконки
              Text(
                icon.type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final iconData = Uint8List.fromList(icon.data);

    // Определяем тип иконки по расширению
    if (icon.type.toLowerCase() == 'svg' ||
        icon.type.toLowerCase() == 'image/svg+xml') {
      // SVG иконка
      return SvgPicture.memory(
        iconData,
        fit: BoxFit.contain,
        width: 64,
        height: 64,
        placeholderBuilder: (context) => const SizedBox(
          width: 64,
          height: 64,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      // Обычная растровая иконка (PNG, JPG, etc.)
      return Image.memory(
        iconData,
        fit: BoxFit.contain,
        width: 64,
        height: 64,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 64);
        },
      );
    }
  }
}
