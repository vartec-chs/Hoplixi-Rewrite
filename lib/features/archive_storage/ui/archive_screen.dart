import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/archive_storage/provider/archive_notifier.dart';
import 'package:hoplixi/features/archive_storage/ui/widgets/export_tab.dart';
import 'package:hoplixi/features/archive_storage/ui/widgets/import_tab.dart';

/// Экран архивации и разархивации хранилищ
class ArchiveScreen extends ConsumerStatefulWidget {
  const ArchiveScreen({super.key});

  @override
  ConsumerState<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends ConsumerState<ArchiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Очищаем результаты при переключении вкладок
      ref.read(archiveNotifierProvider.notifier).clearResults();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Архивация хранилищ'),
        bottom: TabBar(
          controller: _tabController,
          tabAlignment: TabAlignment.fill,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file), text: 'Экспорт'),
            Tab(icon: Icon(Icons.download), text: 'Импорт'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ExportTab(), ImportTab()],
      ),
    );
  }
}
