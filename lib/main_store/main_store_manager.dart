import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/main_store/main_store.dart';
import 'package:hoplixi/main_store/services/db_history_services.dart';

class MainStoreManager {
  MainStore? _currentStore;
  String? _currentStorePath;
  static const String _dbExtension = MainConstants.dbExtension;
  DatabaseHistoryService? _dbHistoryService;

  MainStoreManager(this._dbHistoryService);
}
