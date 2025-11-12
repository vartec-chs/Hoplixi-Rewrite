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

  // Password forms
  static const String dashboardPasswordCreate = '/dashboard/password/create';
  static const String dashboardPasswordEdit = '/dashboard/password/edit/:id';

  /// Генерирует путь для редактирования пароля с конкретным ID
  static String dashboardPasswordEditWithId(String id) =>
      '/dashboard/password/edit/$id';
}
