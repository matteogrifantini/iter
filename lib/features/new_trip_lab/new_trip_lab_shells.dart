import 'package:flutter/material.dart';

import 'new_trip_lab_controller.dart';
import 'new_trip_lab_models.dart';
import 'new_trip_lab_steps.dart';

class NewTripQuestionShell extends StatelessWidget {
  const NewTripQuestionShell({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onEditOrigin,
    required this.onRetryOrigin,
  });

  final NewTripPrototypeController controller;
  final VoidCallback onBack;
  final VoidCallback onEditOrigin;
  final VoidCallback onRetryOrigin;

  @override
  Widget build(BuildContext context) => _SimpleShell(
    controller: controller,
    onBack: onBack,
    onEditOrigin: onEditOrigin,
    onRetryOrigin: onRetryOrigin,
  );
}

class _SimpleShell extends StatelessWidget {
  const _SimpleShell({
    required this.controller,
    required this.onBack,
    required this.onEditOrigin,
    required this.onRetryOrigin,
  });

  final NewTripPrototypeController controller;
  final VoidCallback onBack;
  final VoidCallback onEditOrigin;
  final VoidCallback onRetryOrigin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final alpha = theme.brightness == Brightness.dark ? .32 : .22;
    final background = Color.alphaBlend(
      colors.secondaryContainer.withValues(alpha: alpha),
      colors.surfaceContainerLowest,
    );
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: background,
      appBar: _QuestionAppBar(
        controller: controller,
        onBack: onBack,
        background: background,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.currentStep !=
                      NewTripPrototypeStep.origin) ...[
                    NewTripOriginPill(
                      controller: controller,
                      onEdit: onEditOrigin,
                    ),
                    const SizedBox(height: 28),
                  ],
                  _AnimatedStep(
                    controller: controller,
                    onEditOrigin: onEditOrigin,
                    onRetryOrigin: onRetryOrigin,
                    compactHeading: true,
                  ),
                  Padding(
                    key: const ValueKey('new-trip-simple-progress'),
                    padding: const EdgeInsets.only(top: 24, bottom: 20),
                    child: NewTripProgress(controller: controller),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        key: const ValueKey('new-trip-simple-bottom-navigation'),
        color: background,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: NewTripContextualAction(controller: controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedStep extends StatelessWidget {
  const _AnimatedStep({
    required this.controller,
    required this.onEditOrigin,
    required this.onRetryOrigin,
    this.compactHeading = false,
  });

  final NewTripPrototypeController controller;
  final VoidCallback onEditOrigin;
  final VoidCallback onRetryOrigin;
  final bool compactHeading;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        if (reduceMotion) {
          return FadeTransition(opacity: animation, child: child);
        }
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.06, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: NewTripStepContent(
        key: ValueKey(
          '${controller.currentStep.name}-${controller.dateMode?.name}',
        ),
        controller: controller,
        step: controller.currentStep,
        onEditOrigin: onEditOrigin,
        onRetryOrigin: onRetryOrigin,
        compactHeading: compactHeading,
      ),
    );
  }
}

class _QuestionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _QuestionAppBar({
    required this.controller,
    required this.onBack,
    this.background,
  });

  final NewTripPrototypeController controller;
  final VoidCallback onBack;
  final Color? background;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: background,
    leading: IconButton(
      tooltip: controller.canGoBack ? 'Indietro' : 'Chiudi anteprima',
      onPressed: onBack,
      icon: Icon(controller.canGoBack ? Icons.arrow_back : Icons.close),
    ),
    title: const Text('Nuovo viaggio'),
  );
}
