import 'package:drift/drift.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/main_store/dao/password_dao.dart';
import 'package:hoplixi/main_store/dao/password_history_dao.dart';
import 'package:hoplixi/main_store/dao/otp_dao.dart';
import 'package:hoplixi/main_store/dao/otp_history_dao.dart';
import 'package:hoplixi/main_store/dao/note_dao.dart';
import 'package:hoplixi/main_store/dao/note_history_dao.dart';
import 'package:hoplixi/main_store/dao/bank_card_dao.dart';
import 'package:hoplixi/main_store/dao/bank_card_history_dao.dart';
import 'package:hoplixi/main_store/dao/file_dao.dart';
import 'package:hoplixi/main_store/dao/file_history_dao.dart';
import 'package:hoplixi/main_store/dao/category_dao.dart';
import 'package:hoplixi/main_store/dao/icon_dao.dart';
import 'package:hoplixi/main_store/models/enums/index.dart';
import 'package:hoplixi/main_store/tables/index.dart';
import './dao/filters_dao/filters_dao.dart';
import 'package:uuid/uuid.dart';

part 'main_store.g.dart';

@DriftDatabase(
  tables: [
    StoreMetaTable,
    Passwords,
    PasswordsHistory,
    Otps,
    OtpsHistory,
    Notes,
    NotesHistory,
    BankCards,
    BankCardsHistory,
    Files,
    FilesTags,
    FilesHistory,
    Categories,
    Tags,
    Icons,
    PasswordsTags,
    OtpsTags,
    NotesTags,
    BankCardsTags,
  ],
  daos: [
    PasswordDao,
    PasswordHistoryDao,
    OtpDao,
    OtpHistoryDao,
    NoteDao,
    NoteHistoryDao,
    BankCardDao,
    BankCardHistoryDao,
    FileDao,
    FileHistoryDao,
    CategoryDao,
    IconDao,
    BankCardFilterDao,
    FileFilterDao,
    NoteFilterDao,
    OtpFilterDao,
    PasswordFilterDao,
  ],
)
class MainStore extends _$MainStore {
  static const String _logTag = 'MainStore';

  MainStore(super.e);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        logInfo(
          'Migrating database from version $from to $to',
          tag: '${_logTag}Migration',
        );

        // Migration v2 -> v3: Add is_archived column to otps table
        if (from < 3) {
          await m.addColumn(otps, otps.isArchived);
          logInfo(
            'Added is_archived column to otps table',
            tag: '${_logTag}Migration',
          );
        }

        logInfo('Migration completed', tag: '${_logTag}Migration');
      },
    );
  }

  @override
  int get schemaVersion => MainConstants.databaseSchemaVersion;
}
