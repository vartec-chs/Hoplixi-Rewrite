import 'package:flutter/widgets.dart';
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
            // TitleBar(),
            Expanded(child: child),
          ],
        ),
        Positioned(top: 0, left: 0, right: 0, child: TitleBar()),
      ],
    );
  }
}
