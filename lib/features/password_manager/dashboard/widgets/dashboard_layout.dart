import 'package:flutter/material.dart';
import 'package:hoplixi/core/theme/constants.dart';

/// Адаптивный layout для dashboard
/// На больших экранах: main content + sidebar справа
/// На маленьких экранах: только main content (формы открываются на новой странице)
class DashboardLayout extends StatefulWidget {
  final Widget mainContent;
  final Widget? sidebarContent;
  final VoidCallback? onCloseSidebar;
  final double breakpoint;

  const DashboardLayout({
    super.key,
    required this.mainContent,
    this.sidebarContent,
    this.onCloseSidebar,
    this.breakpoint = 900,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sidebarAnimation;
  late Animation<double> _fadeAnimation;
  Widget? _currentSidebarContent;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _currentSidebarContent = widget.sidebarContent;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _sidebarAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    if (widget.sidebarContent != null) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(DashboardLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Открытие sidebar
    if (widget.sidebarContent != null && oldWidget.sidebarContent == null) {
      _currentSidebarContent = widget.sidebarContent;
      _isClosing = false;
      _animationController.forward();
    }
    // Закрытие sidebar
    else if (widget.sidebarContent == null &&
        oldWidget.sidebarContent != null) {
      _isClosing = true;
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentSidebarContent = null;
            _isClosing = false;
          });
        }
      });
    }
    // Смена контента
    else if (widget.sidebarContent != null &&
        oldWidget.sidebarContent != null &&
        widget.sidebarContent != oldWidget.sidebarContent) {
      // Fade out -> change content -> fade in
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _currentSidebarContent = widget.sidebarContent;
          });
          _animationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= widget.breakpoint;

        if (isDesktop && (_currentSidebarContent != null || _isClosing)) {
          // Десктопная версия с анимированным sidebar
          return Row(
            children: [
              // Main content
              Expanded(flex: 2, child: widget.mainContent),

              // Анимированный Sidebar
              AnimatedBuilder(
                animation: _sidebarAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: SizedBox(
                      width:
                          MediaQuery.of(context).size.width /
                          2 *
                          _sidebarAnimation.value,
                      child: _sidebarAnimation.value > 0
                          ? Opacity(
                              opacity: _fadeAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.only(
                                    // bottomLeft: Radius.circular(screenPaddingValue),
                                    topLeft: Radius.circular(
                                      screenPaddingValue,
                                    ),
                                  ),
                                  // border: Border(
                                  //   left: BorderSide(
                                  //     color: Theme.of(context).dividerColor,
                                  //     width: 1,
                                  //   ),
                                  // ),
                                ),
                                child: _sidebarAnimation.value > 0.3
                                    ? Column(
                                        children: [
                                          // Заголовок sidebar с кнопкой закрытия
                                          Container(
                                            height: 56,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Theme.of(
                                                    context,
                                                  ).dividerColor,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.close),
                                                  onPressed:
                                                      widget.onCloseSidebar,
                                                  tooltip: 'Закрыть',
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Содержимое sidebar
                                          if (_currentSidebarContent != null)
                                            Expanded(
                                              child: _currentSidebarContent!,
                                            ),
                                        ],
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                },
              ),
            ],
          );
        }

        // Мобильная версия - только main content
        return widget.mainContent;
      },
    );
  }
}

/// Провайдер для управления состоянием sidebar
class DashboardSidebarController extends ChangeNotifier {
  Widget? _sidebarContent;

  Widget? get sidebarContent => _sidebarContent;
  bool get hasSidebar => _sidebarContent != null;

  void openSidebar(Widget content) {
    _sidebarContent = content;
    notifyListeners();
  }

  void closeSidebar() {
    _sidebarContent = null;
    notifyListeners();
  }
}
