import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_platform/universal_platform.dart';
import 'widgets/action_button.dart';
import 'package:hoplixi/shared/ui/titlebar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ScrollController _scrollController;
  double _offset = 0;

  final double _expandedHeight = 220;
  final double _toolbarHeight = kToolbarHeight;
  final double _maxRadius = 28.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTitleBarLabel();
    });
  }

  void _updateTitleBarLabel() {
    ref.read(titlebarStateProvider.notifier).updateColor(Colors.white);
    ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
  }

  void _onScroll() {
    setState(() => _offset = _scrollController.offset);

    if (_scrollController.offset >= 160) {
      ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(false);
    } else {
      ref.read(titlebarStateProvider.notifier).setBackgroundTransparent(true);
    }
  }

  double get _radiusFactor {
    final double threshold = (_expandedHeight - _toolbarHeight).clamp(
      1.0,
      double.infinity,
    );
    final double t = (threshold - _offset) / threshold;
    return t.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double radius = _maxRadius * _radiusFactor;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primaryContainer,
                  colorScheme.primary.withValues(alpha: 0.7),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.onPrimary.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: MediaQuery.of(context).size.height * 0.7,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.onPrimary.withOpacity(0.05),
                    ),
                  ),
                ),
              ],
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            scrollBehavior: ScrollBehavior().copyWith(
              overscroll: false,
              scrollbars: false,

              // platform: TargetPlatform.windows ,
            ),
            slivers: [
              _buildAnimatedSliverAppBar(context),
              SliverFillRemaining(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(radius),
                    ),
                    boxShadow: [
                      if (radius > 0)
                        const BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, -2),
                          blurRadius: 8,
                        ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: (UniversalPlatform.isMobile && _offset < 160)
                        ? MediaQuery.of(context).padding.top + 12
                        : 16,
                  ),
                  child: _buildContentSection(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;

        if (isSmallScreen) {
          return SingleChildScrollView(
            child: Column(
              children: [
                ActionButton(
                  icon: CupertinoIcons.folder_open,
                  label: 'Открыть',
                  description: 'Открыть существующий проект',
                  isPrimary: true,
                  onTap: () {
                    // TODO: Открыть бд
                  },
                ),
                const SizedBox(height: 12),
                ActionButton(
                  icon: CupertinoIcons.add_circled,
                  label: 'Создать',
                  description: 'Создать новый проект',
                  onTap: () {
                    // TODO: Создать бд
                  },
                ),
                const SizedBox(height: 12),
                ActionButton(
                  icon: CupertinoIcons.arrow_up_right_square,
                  label: 'Импорт/Экспорт',
                  description: 'Импортировать или экспортировать проект',
                  disabled: true,
                  onTap: () {
                    // TODO: Импорт/Экспорт
                  },
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      icon: CupertinoIcons.folder_open,
                      label: 'Открыть',
                      description: 'Открыть существующий проект',
                      isPrimary: true,
                      onTap: () {
                        // TODO: Открыть бд
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActionButton(
                      icon: CupertinoIcons.add_circled,
                      label: 'Создать',
                      description: 'Создать новый проект',
                      onTap: () {
                        // TODO: Создать бд
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      icon: CupertinoIcons.arrow_up_right_square,
                      label: 'Импорт/Экспорт',
                      description: 'Импортировать или экспортировать проект',
                      disabled: true,
                      onTap: () {
                        // TODO: Импорт/Экспорт
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSliverAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 200.0,
      floating: true,
      pinned: false,
      snap: false,
      elevation: 0,
      surfaceTintColor: colorScheme.surface,

      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Hoplixi',
              textStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
              speed: const Duration(milliseconds: 150),
            ),
            ScrambleAnimatedText(
              'Добро пожаловать',
              textStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
              speed: const Duration(milliseconds: 300),
            ),
            BounceAnimatedText(
              'Главный экран',
              textStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
              duration: const Duration(milliseconds: 1500),
            ),
          ],
          repeatForever: true,

          pause: const Duration(milliseconds: 1000),
          displayFullTextOnTap: true,
          stopPauseOnTap: false,
        ),
        background: Container(),
      ),
    );
  }
}

class CustomCurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);

    final firstCurve = Offset(0, size.height - 20);
    final lastCurve = Offset(26, size.height - 20);
    path.quadraticBezierTo(
      firstCurve.dx,
      firstCurve.dy,
      lastCurve.dx,
      lastCurve.dy,
    );

    final secondCurve = Offset(0, size.height - 20);
    final secondLastCurve = Offset(size.width - 30, size.height - 20);

    path.quadraticBezierTo(
      secondCurve.dx,
      secondCurve.dy,
      secondLastCurve.dx,
      secondLastCurve.dy,
    );

    final thirdCurve = Offset(size.width, size.height - 20);
    final thirdLastCurve = Offset(size.width, size.height);
    path.quadraticBezierTo(
      thirdCurve.dx,
      thirdCurve.dy,
      thirdLastCurve.dx,
      thirdLastCurve.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
