class AppRoutesPaths {
  static const String splash = '/splash';
  static const String setup = '/setup';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String logs = '/logs';
  static const String componentShowcase = '/component-showcase';

  // Add other route paths as needed
  static const String createStore = '/create-store';
  static const String openStore = '/open-store';

  // Dashboard related paths
  static const String dashboard = '/dashboard';
  static const String dashboardHome = '/dashboard/home';
  static const String dashboardCategories = '/dashboard/categories';
  static const String dashboardSearch = '/dashboard/search';
  static const String dashboardSettings = '/dashboard/settings';
  static const String dashboardIconManager = '/dashboard/icon-manager';
  static const String dashboardCategoryManager = '/dashboard/category-manager';
  static const String dashboardTagManager = '/dashboard/tag-manager';
  static const String dashboardMigration = '/dashboard/migration';

  // Password forms
  static const String dashboardPasswordCreate = '/dashboard/password/create';
  static const String dashboardMigratePasswords =
      '/dashboard/migrate/passwords';
  static const String dashboardPasswordEdit = '/dashboard/password/edit/:id';

  /// Генерирует путь для редактирования пароля с конкретным ID
  static String dashboardPasswordEditWithId(String id) =>
      '/dashboard/password/edit/$id';

  // Note forms
  static const String dashboardNoteCreate = '/dashboard/note/create';
  static const String dashboardNoteEdit = '/dashboard/note/edit/:id';

  /// Генерирует путь для редактирования заметки с конкретным ID
  static String dashboardNoteEditWithId(String id) =>
      '/dashboard/note/edit/$id';

  // Bank Card forms
  static const String dashboardBankCardCreate = '/dashboard/bank-card/create';
  static const String dashboardBankCardEdit = '/dashboard/bank-card/edit/:id';

  /// Генерирует путь для редактирования банковской карты с конкретным ID
  static String dashboardBankCardEditWithId(String id) =>
      '/dashboard/bank-card/edit/$id';

  // File forms
  static const String dashboardFileCreate = '/dashboard/file/create';
  static const String dashboardFileEdit = '/dashboard/file/edit/:id';

  /// Генерирует путь для редактирования файла с конкретным ID
  static String dashboardFileEditWithId(String id) =>
      '/dashboard/file/edit/$id';

  // OTP forms
  static const String dashboardOtpCreate = '/dashboard/otp/create';
  static const String dashboardMigrateOtp = '/dashboard/migrate/otp';
  static const String dashboardOtpEdit = '/dashboard/otp/edit/:id';

  /// Генерирует путь для редактирования OTP с конкретным ID
  static String dashboardOtpEditWithId(String id) => '/dashboard/otp/edit/$id';
}
