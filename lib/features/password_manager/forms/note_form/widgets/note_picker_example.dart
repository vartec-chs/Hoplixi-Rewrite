import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/forms/note_form/widgets/note_picker_modal.dart';
import 'package:hoplixi/shared/ui/button.dart';

/// Пример использования модального окна выбора заметки
class NotePickerExample extends ConsumerStatefulWidget {
  const NotePickerExample({super.key});

  @override
  ConsumerState<NotePickerExample> createState() => _NotePickerExampleState();
}

class _NotePickerExampleState extends ConsumerState<NotePickerExample> {
  NotePickerResult? _selectedNote;

  Future<void> _showPicker() async {
    final result = await showNotePickerModal(context, ref);
    if (result != null && mounted) {
      setState(() {
        _selectedNote = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пример выбора заметки')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedNote != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Выбранная заметка:',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedNote!.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_selectedNote!.id}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SmoothButton(
              label: _selectedNote == null
                  ? 'Выбрать заметку'
                  : 'Изменить выбор',
              onPressed: _showPicker,
              type: SmoothButtonType.filled,
              variant: SmoothButtonVariant.normal,
            ),
          ],
        ),
      ),
    );
  }
}
