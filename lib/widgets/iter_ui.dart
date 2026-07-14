import 'package:flutter/material.dart';

class IterPage extends StatelessWidget {
  const IterPage({
    super.key,
    required this.child,
    this.currentTab,
    this.onTabChanged,
  });

  final Widget child;
  final int? currentTab;
  final ValueChanged<int>? onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: currentTab == null
          ? null
          : IterBottomNavigation(
              currentIndex: currentTab!,
              onChanged: onTabChanged!,
            ),
    );
  }
}

class IterBottomNavigation extends StatelessWidget {
  const IterBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onChanged,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Oggi'),
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          label: 'Scopri',
        ),
        NavigationDestination(
          icon: Icon(Icons.route_outlined),
          label: 'Viaggi',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profilo',
        ),
      ],
    );
  }
}

class PlanningProgress extends StatelessWidget {
  const PlanningProgress({
    super.key,
    required this.currentStep,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 14),
  });

  final int currentStep;
  final EdgeInsetsGeometry padding;

  static const _labels = <String>['Luoghi', 'Viaggio', 'Base', 'Piano'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final step = currentStep.clamp(0, _labels.length - 1);
    return Semantics(
      label: 'Costruzione del viaggio',
      value: '${_labels[step]}, passaggio ${step + 1} di ${_labels.length}',
      child: ExcludeSemantics(
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _labels[step],
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: colors.primary),
                  ),
                  const Spacer(),
                  Text(
                    '${step + 1} di ${_labels.length}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  for (var index = 0; index < _labels.length; index++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        height: index == step ? 5 : 3,
                        decoration: BoxDecoration(
                          color: index <= step
                              ? colors.primary
                              : colors.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    if (index != _labels.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
    this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: body,
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.icon = Icons.auto_awesome,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.onPrimaryContainer),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressRule extends StatelessWidget {
  const ProgressRule({super.key, required this.value, required this.label});

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      value: '${(value * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 8,
              color: colors.primary,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
