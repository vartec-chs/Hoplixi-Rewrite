import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'widgets/action_button.dart';
import 'package:hoplixi/shared/ui/titlebar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTitleBarLabel();
    });
  }

  void _updateTitleBarLabel() {
    // ref.read(labelStateProvider.notifier).updateLabel('Home');
    ref.read(labelStateProvider.notifier).updateColor(Colors.white);
  }

  void _onScroll() {
    // if scrolling on 150 pixels or more, update the title bar label
    if (_scrollController!.offset >= 100) {
      ref.read(labelStateProvider.notifier).setHidden(true);
    } else {
      ref.read(labelStateProvider.notifier).setHidden(false);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          clipBehavior: Clip.hardEdge,
          controller: _scrollController,
          scrollBehavior: const ScrollBehavior().copyWith(
            overscroll: false,
            physics: BouncingScrollPhysics(),
            scrollbars: false,
          ),
          slivers: [
            // _buildAnimatedSliverAppBar(context),
            SliverToBoxAdapter(child: _buildNewAppBar(context)),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 0,
                    left: 12.0,
                    right: 12.0,
                    bottom: 12.0,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxWidth < 500;

                      if (isSmallScreen) {
                        // Вертикальное расположение для узких экранов
                        return Column(
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
                              description:
                                  'Импортировать или экспортировать проект',
                              disabled: true,
                              onTap: () {
                                // TODO: Импорт/Экспорт
                              },
                            ),
                          ],
                        );
                      }

                      // Горизонтальное расположение для широких экранов
                      return Column(
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
                                  description:
                                      'Импортировать или экспортировать проект',
                                  disabled: true,
                                  onTap: () {
                                    // TODO: Импорт/Экспорт
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedSliverAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      expandedHeight: 200.0,
      floating: true,
      pinned: true,
      snap: false,
      elevation: 0,
      surfaceTintColor: colorScheme.background,
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
            FadeAnimatedText(
              'Добро пожаловать',
              textStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
              duration: const Duration(milliseconds: 2000),
            ),
            ScaleAnimatedText(
              'Home',
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
        background: Container(
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
                bottom: -30,
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
      ),
    );
  }

  Widget _buildNewAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipPath(
      clipper: CustomCurvedClipper(),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.05),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 200,
              child: Center(
                child: AnimatedTextKit(
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
                    FadeAnimatedText(
                      'Добро пожаловать',
                      textStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                      duration: const Duration(milliseconds: 2000),
                    ),
                    ScaleAnimatedText(
                      'Home',
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
              ),
            ),
          ],
        ),
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

class CustomCurvedEdges extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 40,
    );
    path.quadraticBezierTo(
      3 * size.width / 4,
      size.height - 80,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}
