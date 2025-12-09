import 'package:flutter/material.dart';
import 'package:hoplixi/shared/ui/slider_button.dart';

/// Экран для демонстрации slider buttons
class SliderButtonShowcaseScreen extends StatefulWidget {
  const SliderButtonShowcaseScreen({super.key});

  @override
  State<SliderButtonShowcaseScreen> createState() =>
      _SliderButtonShowcaseScreenState();
}

class _SliderButtonShowcaseScreenState
    extends State<SliderButtonShowcaseScreen> {
  String _lastAction = 'No action yet';

  void _showAction(String action) {
    setState(() {
      _lastAction = action;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(action), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Last Action:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _lastAction,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Slider Button Types',
          children: [
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Slide to Confirm',
              onSlideComplete: () {
                _showAction('Confirmed!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.delete,
              text: 'Slide to Delete',
              onSlideComplete: () {
                _showAction('Deleted!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.unlock,
              text: 'Slide to Unlock',
              onSlideComplete: () {
                _showAction('Unlocked!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.send,
              text: 'Slide to Send',
              onSlideComplete: () {
                _showAction('Sent!');
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'With Loading',
          children: [
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Slide to Save',
              showLoading: true,
              onSlideCompleteAsync: () async {
                await Future.delayed(const Duration(seconds: 2));
                _showAction('Saved after loading!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.send,
              text: 'Slide to Upload',
              showLoading: true,
              resetAfterComplete: true,
              onSlideCompleteAsync: () async {
                await Future.delayed(const Duration(seconds: 3));
                _showAction('Uploaded successfully!');
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'States',
          children: [
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Disabled Slider',
              enabled: false,
              onSlideComplete: () {
                _showAction('This should not happen');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.delete,
              text: 'No Reset After Complete',
              resetAfterComplete: false,
              onSlideComplete: () {
                _showAction('Completed without reset');
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Custom Theme',
          children: [
            SliderButtonTheme(
              data: SliderButtonThemeData(
                backgroundColor: Colors.purple.shade100,
                fillColor: Colors.purple,
                thumbColor: Colors.purple,
                iconColor: Colors.white,
                textColor: Colors.purple.shade900,
                height: 70.0,
                borderRadius: 35.0,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                thumbSize: 56.0,
                animationDuration: const Duration(milliseconds: 400),
                icon: Icons.stars,
              ),
              child: SliderButton(
                type: SliderButtonType.confirm,
                text: 'Custom Themed Slider',
                onSlideComplete: () {
                  _showAction('Custom theme completed!');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Color Variants',
          children: [
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Normal Variant',
              variant: SliderButtonVariant.normal,
              onSlideComplete: () {
                _showAction('Normal variant completed!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.delete,
              text: 'Error Variant',
              variant: SliderButtonVariant.error,
              onSlideComplete: () {
                _showAction('Error variant completed!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.send,
              text: 'Warning Variant',
              variant: SliderButtonVariant.warning,
              onSlideComplete: () {
                _showAction('Warning variant completed!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.unlock,
              text: 'Info Variant',
              variant: SliderButtonVariant.info,
              onSlideComplete: () {
                _showAction('Info variant completed!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Success Variant',
              variant: SliderButtonVariant.success,
              onSlideComplete: () {
                _showAction('Success variant completed!');
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Shrink to Circle Animation',
          children: [
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Slide to Confirm',
              variant: SliderButtonVariant.success,
              completionAnimation:
                  SliderButtonCompletionAnimation.shrinkToCircle,
              onSlideComplete: () {
                _showAction('Shrink animation completed!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.delete,
              text: 'Slide to Delete',
              variant: SliderButtonVariant.error,
              completionAnimation:
                  SliderButtonCompletionAnimation.shrinkToCircle,
              showLoading: true,
              onSlideCompleteAsync: () async {
                await Future.delayed(const Duration(seconds: 2));
                _showAction('Delete with shrink animation!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.send,
              text: 'Slide to Send',
              variant: SliderButtonVariant.info,
              completionAnimation:
                  SliderButtonCompletionAnimation.shrinkToCircle,
              resetAfterComplete: true,
              onSlideComplete: () {
                _showAction('Send with shrink animation!');
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Slide and Fade Animation',
          children: [
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Modern Slide Effect',
              variant: SliderButtonVariant.success,
              completionAnimation: SliderButtonCompletionAnimation.slideAndFade,
              onSlideComplete: () {
                _showAction('Slide and fade completed!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.send,
              text: 'Send with Style',
              variant: SliderButtonVariant.info,
              completionAnimation: SliderButtonCompletionAnimation.slideAndFade,
              showLoading: true,
              onSlideCompleteAsync: () async {
                await Future.delayed(const Duration(seconds: 2));
                _showAction('Sent with fade animation!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.unlock,
              text: 'Unlock Premium',
              variant: SliderButtonVariant.warning,
              completionAnimation: SliderButtonCompletionAnimation.slideAndFade,
              shimmerText: true,
              onSlideComplete: () {
                _showAction('Premium unlocked with style!');
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Shimmer Text Effect',
          children: [
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Shimmer Text',
              shimmerText: true,
              variant: SliderButtonVariant.success,
              onSlideComplete: () {
                _showAction('Shimmer text completed!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.unlock,
              text: 'Unlock with Shimmer',
              shimmerText: true,
              variant: SliderButtonVariant.info,
              completionAnimation:
                  SliderButtonCompletionAnimation.shrinkToCircle,
              onSlideComplete: () {
                _showAction('Shimmer unlock completed!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.send,
              text: 'Send with Effects',
              shimmerText: true,
              variant: SliderButtonVariant.warning,
              showLoading: true,
              completionAnimation:
                  SliderButtonCompletionAnimation.shrinkToCircle,
              onSlideCompleteAsync: () async {
                await Future.delayed(const Duration(seconds: 2));
                _showAction('Send with all effects!');
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSection(
          context,
          title: 'Combined Features',
          children: [
            SliderButton(
              type: SliderButtonType.confirm,
              text: 'Ultimate Slider (Shrink)',
              shimmerText: true,
              variant: SliderButtonVariant.success,
              completionAnimation:
                  SliderButtonCompletionAnimation.shrinkToCircle,
              showLoading: true,
              resetAfterComplete: true,
              onSlideCompleteAsync: () async {
                await Future.delayed(const Duration(seconds: 2));
                _showAction('All features with shrink!');
              },
            ),
            const SizedBox(height: 16),
            SliderButton(
              type: SliderButtonType.send,
              text: 'Ultimate Slider (Fade)',
              shimmerText: true,
              variant: SliderButtonVariant.info,
              completionAnimation: SliderButtonCompletionAnimation.slideAndFade,
              showLoading: true,
              resetAfterComplete: true,
              onSlideCompleteAsync: () async {
                await Future.delayed(const Duration(seconds: 2));
                _showAction('All features with fade!');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}
