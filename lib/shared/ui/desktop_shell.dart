import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/ui/status_bar.dart';
import 'titlebar.dart';

class DesktopShell extends StatelessWidget {
  final Widget child;

  const DesktopShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Consumer(
              builder: (context, ref, _) {
                final titlebarState = ref.watch(titlebarStateProvider);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: titlebarState.backgroundTransparent ? 0 : 40,
                );
              },
            ),
            Expanded(child: child),
            const StatusBar(),
          ],
        ),
        const Positioned(top: 0, left: 0, right: 0, child: TitleBar()),
      ],
    );
  }
}
