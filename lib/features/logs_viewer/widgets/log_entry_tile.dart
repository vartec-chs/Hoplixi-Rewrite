import 'package:flutter/material.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:intl/intl.dart';

/// Виджет для отображения одной записи лога
class LogEntryTile extends StatefulWidget {
  final LogEntry entry;

  const LogEntryTile({super.key, required this.entry});

  @override
  State<LogEntryTile> createState() => _LogEntryTileState();
}

class _LogEntryTileState extends State<LogEntryTile> {
  bool _expanded = false;

  Color _getLogLevelColor() {
    switch (widget.entry.level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.trace:
        return Colors.cyan;
      case LogLevel.fatal:
        return Colors.purple;
    }
  }

  String _getLogLevelEmoji() {
    switch (widget.entry.level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.trace:
        return '🔍';
      case LogLevel.fatal:
        return '🛑';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss.SSS').format(widget.entry.timestamp);
    final hasError =
        widget.entry.error != null || widget.entry.stackTrace != null;
    final hasData =
        widget.entry.additionalData != null &&
        widget.entry.additionalData!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: _expanded ? Colors.grey.shade50 : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Основная информация
              Row(
                children: [
                  Text(
                    _getLogLevelEmoji(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getLogLevelColor(),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.entry.level.name.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.entry.tag != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.entry.tag!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              timeStr,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            if (hasError || hasData) const SizedBox(width: 8),
                            if (hasError)
                              const Tooltip(
                                message: 'Содержит информацию об ошибке',
                                child: Icon(
                                  Icons.warning_amber,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            if (hasData) const SizedBox(width: 4),
                            if (hasData)
                              const Tooltip(
                                message: 'Содержит дополнительные данные',
                                child: Icon(
                                  Icons.data_object,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.entry.message,
                          maxLines: _expanded ? null : 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (hasError || hasData || _expanded)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                ],
              ),
              // Развернутая информация
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                // Ошибка
                if (widget.entry.error != null) ...[
                  Text(
                    'Ошибка:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      widget.entry.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Stack trace
                if (widget.entry.stackTrace != null) ...[
                  Text(
                    'Stack Trace:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        widget.entry.stackTrace.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.purple.shade900,
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Дополнительные данные
                if (widget.entry.additionalData != null &&
                    widget.entry.additionalData!.isNotEmpty) ...[
                  Text(
                    'Дополнительные данные:',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        widget.entry.additionalData.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade900,
                          fontFamily: 'monospace',
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
