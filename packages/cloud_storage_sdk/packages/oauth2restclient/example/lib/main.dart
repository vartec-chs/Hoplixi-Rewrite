import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:oauth2restclient/oauth2restclient.dart';

import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OAuth2RestClient Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class ProviderConfig {
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;

  const ProviderConfig({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
  });
}

class _MyHomePageState extends State<MyHomePage> {
  late final OAuth2Account account;

  // Список всех провайдеров
  final List<ProviderConfig> providers = const [
    ProviderConfig(
      name: 'google',
      displayName: 'Google',
      icon: Icons.g_mobiledata,
      color: Color(0xFF4285F4),
    ),
    ProviderConfig(
      name: 'microsoft',
      displayName: 'Microsoft',
      icon: Icons.business,
      color: Color(0xFF00A4EF),
    ),
    ProviderConfig(
      name: 'dropbox',
      displayName: 'Dropbox',
      icon: Icons.folder,
      color: Color(0xFF0061FF),
    ),
    ProviderConfig(
      name: 'yandex',
      displayName: 'Yandex',
      icon: Icons.yard,
      color: Color(0xFFFF0000),
    ),
  ];

  List<(String, String)> accounts = [];
  bool isLoading = false;
  bool isCancelled = false;
  int _currentOperationId = 0;
  String? currentOperation;
  String? error;
  String? successMessage;
  Map<String, dynamic>? userInfo;

  @override
  void initState() {
    super.initState();
    _initializeAccount();
  }

  void _initializeAccount() {
    final file = File(
      '${Directory.systemTemp.path}/oauth2_tokens_example.json',
    );
    debugPrint('Token storage: ${file.path}');

    account = OAuth2Account(
      appPrefix: 'oauth2restclientexample',
      tokenStorage: OAuth2TokenStorageJson(file: file),
    );

    // Инициализация всех провайдеров
    _setupProviders();
    _loadAccounts();
  }

  void _setupProviders() {
    // Google
    account.addProvider(
      Google(
        clientId: Config.googleClientId,
        clientSecret: Config.googleClientSecret,
        redirectUri: 'http://localhost:8569/callback',
        scopes: [
          'https://www.googleapis.com/auth/userinfo.email',
          'https://www.googleapis.com/auth/userinfo.profile',
          'openid',
        ],
      ),
    );

    // Microsoft
    account.addProvider(
      Microsoft(
        clientId: Config.microsoftClientId,

        redirectUri: 'http://localhost:8570/callback',
        scopes: ['openid', 'profile', 'email', 'User.Read'],
      ),
    );

    // Dropbox
    account.addProvider(
      Dropbox(
        clientId: Config.dropboxClientId,
        redirectUri: 'http://localhost:8713/callback',
        scopes: [
          "account_info.read",
          "files.content.read",
          "files.content.write",
          "files.metadata.write",
          "files.metadata.read",
          'openid',
          'email',
          "profile",
        ],
      ),
    );

    // Yandex
    account.addProvider(
      Yandex(
        clientId: Config.yandexClientId,
        clientSecret: Config.yandexClientSecret,
        redirectUri: 'http://localhost:8569/callback',
        scopes: ['login:email', 'login:info'],
      ),
    );
  }

  Future<void> _loadAccounts() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      accounts = await account.allAccounts();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Ошибка загрузки аккаунтов: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _login(String providerName) async {
    final int myOperationId = ++_currentOperationId;
    setState(() {
      isLoading = true;
      isCancelled = false;
      currentOperation =
          'Авторизация через ${_getProviderDisplayName(providerName)}';
      error = null;
      successMessage = null;
      userInfo = null;
    });

    try {
      final token = await account.newLogin(providerName);

      if (myOperationId != _currentOperationId) return;

      if (isCancelled) {
        setState(() {
          error = 'Операция отменена пользователем';
        });
        return;
      }

      if (token != null) {
        setState(() {
          successMessage = 'Успешная авторизация: ${token.userName}';
        });
        await _loadAccounts();
      } else {
        setState(() {
          error = 'Авторизация отменена';
        });
      }
    } catch (e) {
      if (myOperationId != _currentOperationId) return;
      if (!isCancelled) {
        setState(() {
          error = 'Ошибка авторизации: $e';
        });
      }
    } finally {
      if (myOperationId == _currentOperationId) {
        setState(() {
          isLoading = false;
          currentOperation = null;
          isCancelled = false;
        });
      }
    }
  }

  Future<void> _testAccount(String serviceName, String userName) async {
    final int myOperationId = ++_currentOperationId;
    setState(() {
      isLoading = true;
      isCancelled = false;
      currentOperation = 'Получение данных пользователя';
      error = null;
      successMessage = null;
      userInfo = null;
    });

    try {
      var token = await account.tryAutoLogin(serviceName, userName);

      if (myOperationId != _currentOperationId) return;

      if (isCancelled) {
        setState(() {
          error = 'Операция отменена пользователем';
          isLoading = false;
          currentOperation = null;
        });
        return;
      }

      if (token == null) {
        throw Exception('Токен не найден');
      }

      final client = await account.createClient(token);
      final info = await _getUserInfo(client, serviceName);

      if (myOperationId != _currentOperationId) return;

      if (isCancelled) {
        setState(() {
          error = 'Операция отменена пользователем';
          isLoading = false;
          currentOperation = null;
        });
        return;
      }

      setState(() {
        userInfo = info;
        successMessage = 'Данные успешно получены';
        isLoading = false;
        currentOperation = null;
      });
    } catch (e) {
      if (myOperationId != _currentOperationId) return;
      if (!isCancelled) {
        setState(() {
          error = 'Ошибка получения данных: $e';
          isLoading = false;
          currentOperation = null;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _getUserInfo(
    OAuth2RestClient client,
    String service,
  ) async {
    switch (service) {
      case 'google':
        return await client.getJson(
          'https://www.googleapis.com/oauth2/v2/userinfo',
        );
      case 'microsoft':
        return await client.getJson('https://graph.microsoft.com/v1.0/me');
      case 'dropbox':
        return await client.postJson(
          'https://api.dropboxapi.com/2/users/get_current_account',
        );
      case 'yandex':
        return await client.getJson('https://login.yandex.ru/info');
      default:
        throw Exception('Неизвестный провайдер: $service');
    }
  }

  Future<void> _deleteAccount(String serviceName, String userName) async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      await account.deleteAccount(serviceName, userName);
      setState(() {
        successMessage = 'Аккаунт удален';
      });
      await _loadAccounts();
    } catch (e) {
      setState(() {
        error = 'Ошибка удаления: $e';
        isLoading = false;
      });
    }
  }

  void _clearMessages() {
    setState(() {
      error = null;
      successMessage = null;
      userInfo = null;
    });
  }

  void _cancelOperation() {
    _currentOperationId++;
    setState(() {
      isCancelled = true;
      isLoading = false;
      currentOperation = null;
      error = 'Операция отменена';
    });
  }

  String _getProviderDisplayName(String name) {
    final provider = providers.firstWhere(
      (p) => p.name == name,
      orElse:
          () => ProviderConfig(
            name: name,
            displayName: name,
            icon: Icons.help,
            color: Colors.grey,
          ),
    );
    return provider.displayName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OAuth2RestClient Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _loadAccounts,
            tooltip: 'Обновить список аккаунтов',
          ),
        ],
      ),
      body: Column(
        children: [
          // Индикатор загрузки с возможностью отмены
          if (isLoading)
            Column(
              children: [
                const LinearProgressIndicator(),
                if (currentOperation != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.blue.shade50,
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            currentOperation!,
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _cancelOperation,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Отменить'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

          // Сообщения об ошибках
          if (error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _clearMessages,
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            ),

          // Сообщения об успехе
          if (successMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      successMessage!,
                      style: TextStyle(color: Colors.green.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _clearMessages,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            ),

          // Основной контент
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Список провайдеров для авторизации
                  Text(
                    'Доступные провайдеры',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: providers.length,
                    itemBuilder: (context, index) {
                      final provider = providers[index];
                      return _buildProviderCard(provider);
                    },
                  ),

                  const SizedBox(height: 32),

                  // Список аккаунтов
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Сохраненные аккаунты (${accounts.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (accounts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Нет сохраненных аккаунтов',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Авторизуйтесь через один из провайдеров',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: accounts.length,
                      itemBuilder: (context, index) {
                        final acc = accounts[index];
                        return _buildAccountCard(acc.$1, acc.$2);
                      },
                    ),

                  // Информация о пользователе
                  if (userInfo != null) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Информация о пользователе',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...userInfo!.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        '${entry.key}:',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        entry.value.toString(),
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard(ProviderConfig provider) {
    return Card(
      child: InkWell(
        onTap: isLoading ? null : () => _login(provider.name),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: provider.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(provider.icon, color: provider.color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(String serviceName, String userName) {
    final provider = providers.firstWhere(
      (p) => p.name == serviceName,
      orElse:
          () => const ProviderConfig(
            name: 'unknown',
            displayName: 'Unknown',
            icon: Icons.account_circle,
            color: Colors.grey,
          ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: provider.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(provider.icon, color: provider.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.displayName,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed:
                  isLoading ? null : () => _testAccount(serviceName, userName),
              tooltip: 'Тестировать',
              color: provider.color,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed:
                  isLoading
                      ? null
                      : () => _deleteAccount(serviceName, userName),
              tooltip: 'Удалить',
              color: Colors.red.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
