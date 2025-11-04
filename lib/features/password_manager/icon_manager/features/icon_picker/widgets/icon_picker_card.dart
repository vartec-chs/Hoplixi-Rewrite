import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/main_store/models/dto/icon_dto.dart';

/// Виджет карточки иконки для picker
class IconPickerCard extends StatelessWidget {
  final IconCardDto icon;
  final VoidCallback onTap;

  const IconPickerCard({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Превью иконки
              Expanded(child: _buildIconPreview(context)),
              const SizedBox(height: 8),
              // Название иконки
              Text(
                icon.name,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconPreview(BuildContext context) {
    final iconData = Uint8List.fromList(icon.data);
    final isSvg =
        icon.type.toLowerCase() == 'svg' ||
        icon.type.toLowerCase() == 'image/svg+xml' ||
        icon.type.toLowerCase().contains('svg');

    if (isSvg) {
      return SvgPicture.memory(
        iconData,
        fit: BoxFit.contain,
        placeholderBuilder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );
    } else {
      return Image.memory(
        iconData,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.broken_image,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          );
        },
      );
    }
  }
}
