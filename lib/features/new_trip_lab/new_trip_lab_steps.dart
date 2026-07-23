import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'new_trip_lab_controller.dart';
import 'new_trip_lab_models.dart';
import 'new_trip_simple_option_grid.dart';

class NewTripStepContent extends StatelessWidget {
  const NewTripStepContent({
    super.key,
    required this.controller,
    required this.step,
    required this.onEditOrigin,
    required this.onRetryOrigin,
    this.largeTitle = false,
    this.compactHeading = false,
  });

  final NewTripPrototypeController controller;
  final NewTripPrototypeStep step;
  final VoidCallback onEditOrigin;
  final VoidCallback onRetryOrigin;
  final bool largeTitle;
  final bool compactHeading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _QuestionHeading(
          controller: controller,
          step: step,
          largeTitle: largeTitle,
          compactHeading: compactHeading,
        ),
        const SizedBox(height: 24),
        switch (step) {
          NewTripPrototypeStep.origin => _OriginStep(
            controller: controller,
            onEdit: onEditOrigin,
            onRetry: onRetryOrigin,
          ),
          NewTripPrototypeStep.dates => _DateStep(controller: controller),
          NewTripPrototypeStep.company => _CompanyStep(controller: controller),
          NewTripPrototypeStep.transport => _TransportStep(
            controller: controller,
          ),
          NewTripPrototypeStep.budget => _BudgetStep(controller: controller),
          NewTripPrototypeStep.travelStyle => _TravelStyleStep(
            controller: controller,
          ),
          NewTripPrototypeStep.pace => _PaceStep(controller: controller),
          NewTripPrototypeStep.walking => _WalkingStep(controller: controller),
        },
      ],
    );
  }
}

class NewTripProgress extends StatelessWidget {
  const NewTripProgress({super.key, required this.controller, this.foreground});

  final NewTripPrototypeController controller;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentIndex = controller.currentStepIndex;
    final total = controller.totalSteps;
    final currentLabel = controller.currentStep.label;
    final remaining = total - currentIndex - 1;
    final remainingLabel = remaining == 0
        ? 'Ultima domanda'
        : remaining == 1
        ? '1 domanda ancora'
        : '$remaining domande ancora';
    final progressValue =
        '${currentIndex + 1} di $total, $currentLabel, $remainingLabel';
    final active = foreground ?? colors.primary;
    final inactive = foreground == null
        ? colors.outlineVariant
        : foreground!.withValues(alpha: .24);
    return Semantics(
      label: 'Avanzamento del nuovo viaggio',
      value: progressValue,
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    currentLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: active,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${currentIndex + 1} di $total',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground ?? colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                remainingLabel,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground ?? colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                for (var index = 0; index < total; index++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      height: index == currentIndex ? 5 : 3,
                      decoration: BoxDecoration(
                        color: index <= currentIndex ? active : inactive,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  if (index != total - 1) const SizedBox(width: 5),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NewTripOriginPill extends StatelessWidget {
  const NewTripOriginPill({
    super.key,
    required this.controller,
    required this.onEdit,
  });

  final NewTripPrototypeController controller;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final locating = controller.originStatus == PrototypeOriginStatus.locating;
    final label = locating
        ? 'Rileviamo la partenza…'
        : controller.hasOrigin
        ? 'Parti da ${controller.origin}'
        : 'Aggiungi la partenza';
    return Semantics(
      button: true,
      label: '$label. Modifica',
      child: Material(
        color: colors.surfaceContainerHighest,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('new-trip-origin-pill'),
          onTap: onEdit,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    controller.originFromDevice
                        ? Icons.my_location
                        : Icons.location_on_outlined,
                    size: 19,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    controller.hasOrigin ? Icons.edit_outlined : Icons.add,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NewTripContextualAction extends StatelessWidget {
  const NewTripContextualAction({super.key, required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    final label = controller.contextualActionLabel;
    if (label == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('new-trip-contextual-action'),
            onPressed: controller.canPerformContextualAction
                ? controller.performContextualAction
                : null,
            icon: const Icon(Icons.check),
            label: Text(label),
          ),
        ),
      ),
    );
  }
}

String newTripStepSummary(
  BuildContext context,
  NewTripPrototypeController controller,
  NewTripPrototypeStep step,
) => controller.plainSummaryFor(step);

class _QuestionHeading extends StatelessWidget {
  const _QuestionHeading({
    required this.controller,
    required this.step,
    required this.largeTitle,
    required this.compactHeading,
  });

  final NewTripPrototypeController controller;
  final NewTripPrototypeStep step;
  final bool largeTitle;
  final bool compactHeading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compactHeading) ...[
          Text(
            'UNA COSA ALLA VOLTA',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          step.title,
          style: largeTitle
              ? Theme.of(context).textTheme.displaySmall
              : Theme.of(context).textTheme.headlineMedium,
        ),
        if (!compactHeading) ...[
          const SizedBox(height: 9),
          Text(
            step.support,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _OriginStep extends StatelessWidget {
  const _OriginStep({
    required this.controller,
    required this.onEdit,
    required this.onRetry,
  });

  final NewTripPrototypeController controller;
  final VoidCallback onEdit;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final locating = controller.originStatus == PrototypeOriginStatus.locating;
    return _SoftPanel(
      icon: locating ? Icons.my_location : Icons.location_city_outlined,
      title: locating ? 'Cerchiamo la tua città' : 'Inserisci la partenza',
      body: locating
          ? 'Usiamo soltanto la posizione approssimativa e mai in background.'
          : controller.originFailureMessage(),
      child: locating
          ? TextButton(
              onPressed: onEdit,
              child: const Text('Inserisci manualmente'),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.search),
                  label: const Text('Cerca partenza'),
                ),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Riprova'),
                ),
              ],
            ),
    );
  }
}

class _DateStep extends StatelessWidget {
  const _DateStep({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    final mode = controller.dateMode;
    if (mode == null) {
      return _IllustratedOptionPicker(
        options: [
          for (final item in PrototypeDateMode.values)
            _OptionData(
              icon: _dateModeIcon(item),
              emoji: switch (item) {
                PrototypeDateMode.exact => '📅',
                PrototypeDateMode.manualAvailability => '🔀',
                PrototypeDateMode.savedAvailability => '🗓️',
                PrototypeDateMode.open => '✨',
              },
              label: item.label,
              subtitle: item.description,
              enabled:
                  item != PrototypeDateMode.savedAvailability ||
                  controller.hasSavedFreeDays,
              lockedReason:
                  item == PrototypeDateMode.savedAvailability &&
                      !controller.hasSavedFreeDays
                  ? 'Aggiungi prima dei giorni liberi'
                  : null,
              selected: false,
              onTap: () => controller.setDateMode(item),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActionChip(
          avatar: Icon(_dateModeIcon(mode), size: 18),
          label: Text(mode.label),
          onPressed: controller.showDateModePicker,
          tooltip: 'Cambia modalità',
        ),
        const SizedBox(height: 16),
        switch (mode) {
          PrototypeDateMode.exact => _ExactDates(controller: controller),
          PrototypeDateMode.manualAvailability => _DepartureDates(
            controller: controller,
          ),
          PrototypeDateMode.savedAvailability => _SavedAvailability(
            controller: controller,
          ),
          PrototypeDateMode.open => _OpenDates(controller: controller),
        },
        const SizedBox(height: 14),
        _DateValidation(controller: controller),
      ],
    );
  }
}

class _ExactDates extends StatelessWidget {
  const _ExactDates({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    return _Calendar(
      key: const ValueKey('new-trip-calendar-exact'),
      type: CalendarDatePicker2Type.range,
      values: <DateTime?>[
        controller.exactStart,
        controller.exactEnd,
      ].whereType<DateTime>().toList(),
      controller: controller,
      onChanged: controller.setExactDates,
    );
  }
}

class _DepartureDates extends StatelessWidget {
  const _DepartureDates({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    final sortedDates = controller.departureDates.toList()
      ..sort((left, right) => left.compareTo(right));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'In quali giorni potresti partire?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Ogni giorno vale anche da solo. Non servono date consecutive.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _Calendar(
          key: const ValueKey('new-trip-calendar-departures'),
          type: CalendarDatePicker2Type.multi,
          values: sortedDates,
          controller: controller,
          onChanged: controller.setDepartureDates,
        ),
        if (sortedDates.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final date in sortedDates)
                InputChip(
                  label: Text(_formatDayMonth(date)),
                  onDeleted: () => controller.setDepartureDates(
                    sortedDates.where((item) => item != date).toList(),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        _DurationPicker(
          controller: controller,
          mode: PrototypeDateMode.manualAvailability,
        ),
      ],
    );
  }
}

class _SavedAvailability extends StatelessWidget {
  const _SavedAvailability({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    final highlighted = <DateTime>[
      for (final window in controller.activeSavedWindows)
        for (
          var date = window.start;
          !date.isAfter(window.end);
          date = nextCalendarDay(date)
        )
          date,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Calendar(
          key: const ValueKey('new-trip-calendar-saved'),
          type: CalendarDatePicker2Type.multi,
          values: highlighted,
          controller: controller,
          readOnlyLabel:
              'Calendario dei giorni liberi salvati, sola lettura. Usa le finestre salvate qui sotto per includere o escludere i giorni.',
        ),
        const SizedBox(height: 14),
        Text(
          'Finestre salvate',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final window in controller.savedWindows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilterChip(
              avatar: const Icon(Icons.event_available_outlined, size: 18),
              selected: controller.isSavedWindowIncluded(window),
              label: Text(
                '${_formatDayMonth(window.start)}–${_formatDayMonth(window.end)} · ${window.dayCount} giorni',
              ),
              onSelected: (_) => controller.toggleSavedWindow(window),
            ),
          ),
        const SizedBox(height: 14),
        _DurationPicker(
          controller: controller,
          mode: PrototypeDateMode.savedAvailability,
        ),
      ],
    );
  }
}

class _OpenDates extends StatelessWidget {
  const _OpenDates({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quanto avanti guardiamo?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final months in const <int>[3, 6, 12])
              ChoiceChip(
                avatar: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text('$months mesi'),
                selected: controller.openHorizonMonths == months,
                onSelected: (_) => controller.setOpenHorizon(months),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _DurationPicker(controller: controller, mode: PrototypeDateMode.open),
        const SizedBox(height: 16),
        const _SoftPanel(
          icon: Icons.insights_outlined,
          title: 'Prezzi indicativi',
          body:
              'Senza date concrete mostreremo range mensili o stagionali, mai un prezzo puntuale finto.',
        ),
      ],
    );
  }
}

class _DurationPicker extends StatelessWidget {
  const _DurationPicker({required this.controller, required this.mode});

  final NewTripPrototypeController controller;
  final PrototypeDateMode mode;

  @override
  Widget build(BuildContext context) {
    final selected = switch (mode) {
      PrototypeDateMode.manualAvailability => controller.manualDuration,
      PrototypeDateMode.savedAvailability => controller.savedDuration,
      PrototypeDateMode.open => controller.openDuration,
      PrototypeDateMode.exact => null,
    };
    final (minimum, maximum) = switch (mode) {
      PrototypeDateMode.manualAvailability => (
        controller.manualCustomMin,
        controller.manualCustomMax,
      ),
      PrototypeDateMode.savedAvailability => (
        controller.savedCustomMin,
        controller.savedCustomMax,
      ),
      PrototypeDateMode.open => (
        controller.openCustomMin,
        controller.openCustomMax,
      ),
      PrototypeDateMode.exact => (1, 1),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quanto potrebbe durare?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in PrototypeDurationPreset.values)
              ChoiceChip(
                label: Text(preset.label),
                selected: selected == preset,
                onSelected: (_) => controller.setDurationPreset(mode, preset),
              ),
          ],
        ),
        if (selected == PrototypeDurationPreset.custom) ...[
          const SizedBox(height: 14),
          _AdaptiveCounterPair(
            first: _CompactCounter(
              label: 'Minimo',
              value: minimum,
              minimum: 1,
              onChanged: (value) => controller.setCustomDuration(
                mode,
                minimum: value,
                maximum: maximum,
              ),
            ),
            second: _CompactCounter(
              label: 'Massimo',
              value: maximum,
              minimum: 1,
              onChanged: (value) => controller.setCustomDuration(
                mode,
                minimum: minimum,
                maximum: value,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CompanyStep extends StatelessWidget {
  const _CompanyStep({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    final needsCounts =
        controller.company == PrototypeCompany.friends ||
        controller.company == PrototypeCompany.family;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IllustratedOptionPicker(
          options: [
            for (final company in PrototypeCompany.values)
              _OptionData(
                icon: _companyIcon(company),
                emoji: switch (company) {
                  PrototypeCompany.solo => '🎒',
                  PrototypeCompany.couple => '💞',
                  PrototypeCompany.friends => '🥳',
                  PrototypeCompany.family => '👨‍👩‍👧',
                },
                label: company.label,
                selected: controller.company == company,
                onTap: () => controller.selectCompany(company),
              ),
          ],
        ),
        if (needsCounts) ...[
          const SizedBox(height: 18),
          _AdaptiveCounterPair(
            first: _CompactCounter(
              label: 'Adulti',
              value: controller.adults,
              minimum: controller.company == PrototypeCompany.friends ? 2 : 1,
              onChanged: controller.setAdults,
            ),
            second: _CompactCounter(
              label: 'Bambini',
              value: controller.children,
              minimum: 0,
              onChanged: controller.setChildren,
            ),
          ),
        ],
      ],
    );
  }
}

class _TransportStep extends StatelessWidget {
  const _TransportStep({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IllustratedOptionPicker(
          options: [
            _OptionData(
              icon: Icons.auto_awesome_outlined,
              emoji: '✨',
              label: 'Qualsiasi, se conviene',
              subtitle: 'Confronta tutte le alternative.',
              selected: controller.acceptsAnyTransport,
              onTap: controller.selectAnyTransport,
            ),
            for (final transport in PrototypeTransport.values)
              _OptionData(
                icon: _transportIcon(transport),
                emoji: switch (transport) {
                  PrototypeTransport.flight => '✈️',
                  PrototypeTransport.train => '🚆',
                  PrototypeTransport.bus => '🚌',
                  PrototypeTransport.car => '🚗',
                },
                label: transport.label,
                selected: controller.transports.contains(transport),
                onTap: () => controller.toggleTransport(transport),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          controller.transports.isEmpty
              ? 'Scegli almeno un mezzo.'
              : '${controller.transports.length} ${controller.transports.length == 1 ? 'mezzo ammesso' : 'mezzi ammessi'} alla ricerca.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BudgetStep extends StatelessWidget {
  const _BudgetStep({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    const quickValues = <int>[300, 500, 800, 1200];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IllustratedOptionPicker(
          options: [
            for (final value in quickValues)
              _OptionData(
                icon: value <= 500
                    ? Icons.savings_outlined
                    : value <= 800
                    ? Icons.account_balance_wallet_outlined
                    : Icons.workspace_premium_outlined,
                emoji: switch (value) {
                  300 => '🌱',
                  500 => '💶',
                  800 => '👛',
                  _ => '✨',
                },
                label: value == 1200 ? '€1200+' : '€$value',
                subtitle: 'Tutto incluso · per persona',
                selected:
                    controller.budgetPerPerson == value &&
                    controller.budgetIsOpenEnded == (value == 1200),
                onTap: () => controller.setBudget(
                  value,
                  openEnded: value == 1200,
                  autoAdvance: true,
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _BudgetTextField(controller: controller),
        const SizedBox(height: 16),
        const _SoftPanel(
          icon: Icons.receipt_long_outlined,
          title: 'Un numero confrontabile',
          body:
              'Include trasporto, quota alloggio e spesa giornaliera stimata per una persona.',
        ),
      ],
    );
  }
}

class _TravelStyleStep extends StatelessWidget {
  const _TravelStyleStep({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IllustratedOptionPicker(
          options: [
            for (final style in PrototypeTravelStyle.values)
              _OptionData(
                icon: _travelStyleIcon(style),
                emoji: switch (style) {
                  PrototypeTravelStyle.culture => '🏛️',
                  PrototypeTravelStyle.food => '🍝',
                  PrototypeTravelStyle.nature => '🌿',
                  PrototypeTravelStyle.sea => '🌊',
                  PrototypeTravelStyle.rest => '🧘',
                  PrototypeTravelStyle.localLife => '🧭',
                  PrototypeTravelStyle.nightlife => '🌙',
                },
                label: style.label,
                selected: controller.styles.contains(style),
                enabled:
                    controller.styles.contains(style) ||
                    !controller.hasReachedStyleLimit,
                lockedReason:
                    controller.hasReachedStyleLimit &&
                        !controller.styles.contains(style)
                    ? 'Massimo tre priorità'
                    : null,
                onTap: () => controller.toggleTravelStyle(style),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${controller.styles.length} di 3 priorità selezionate',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PaceStep extends StatelessWidget {
  const _PaceStep({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    return _IllustratedOptionPicker(
      options: [
        for (final pace in PrototypePace.values)
          _OptionData(
            icon: switch (pace) {
              PrototypePace.relaxed => Icons.spa_outlined,
              PrototypePace.balanced => Icons.balance_outlined,
              PrototypePace.intense => Icons.bolt_outlined,
            },
            emoji: switch (pace) {
              PrototypePace.relaxed => '🧘',
              PrototypePace.balanced => '⚖️',
              PrototypePace.intense => '⚡',
            },
            label: pace.label,
            subtitle: pace.description,
            selected: controller.pace == pace,
            onTap: () => controller.selectPace(pace),
          ),
      ],
    );
  }
}

class _WalkingStep extends StatelessWidget {
  const _WalkingStep({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    return _IllustratedOptionPicker(
      options: [
        for (final walking in PrototypeWalking.values)
          _OptionData(
            icon: switch (walking) {
              PrototypeWalking.little => Icons.airline_seat_recline_normal,
              PrototypeWalking.normal => Icons.directions_walk_outlined,
              PrototypeWalking.much => Icons.hiking_outlined,
              PrototypeWalking.accessibility => Icons.accessible_outlined,
            },
            emoji: switch (walking) {
              PrototypeWalking.little => '☕',
              PrototypeWalking.normal => '🚶',
              PrototypeWalking.much => '🥾',
              PrototypeWalking.accessibility => '♿',
            },
            label: walking.label,
            selected: controller.walking == walking,
            onTap: () => controller.selectWalking(walking),
          ),
      ],
    );
  }
}

class _IllustratedOptionPicker extends StatelessWidget {
  const _IllustratedOptionPicker({required this.options});

  final List<_OptionData> options;

  @override
  Widget build(BuildContext context) {
    return NewTripSimpleOptionGrid(
      children: [
        for (final option in options) _IllustratedOption(data: option),
      ],
    );
  }
}

class _IllustratedOption extends StatelessWidget {
  const _IllustratedOption({required this.data});

  final _OptionData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = data.selected
        ? colors.primaryContainer
        : colors.surfaceContainerLow;
    final foreground = data.enabled
        ? data.selected
              ? colors.onPrimaryContainer
              : colors.onSurface
        : colors.onSurface.withValues(alpha: .4);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: data.selected ? colors.primary : colors.outlineVariant,
        width: data.selected ? 1.5 : 1,
      ),
    );
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: Text(data.emoji, style: const TextStyle(fontSize: 30)),
        ),
        const SizedBox(height: 7),
        Text(
          data.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (data.subtitle case final subtitle? when subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ],
    );
    return Semantics(
      button: true,
      enabled: data.enabled,
      selected: data.selected,
      excludeSemantics: true,
      label: _semanticOptionLabel([
        data.label,
        data.subtitle,
        data.lockedReason,
      ]),
      child: Material(
        color: background,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('new-trip-option-${data.label}'),
          onTap: data.enabled ? data.onTap : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 96, minWidth: 96),
            child: Padding(padding: const EdgeInsets.all(12), child: content),
          ),
        ),
      ),
    );
  }
}

String _semanticOptionLabel(Iterable<String?> segments) => segments
    .whereType<String>()
    .map((segment) => segment.trim())
    .where((segment) => segment.isNotEmpty)
    .map(
      (segment) => RegExp(r'[.!?]$').hasMatch(segment) ? segment : '$segment.',
    )
    .join(' ');

class _OptionData {
  const _OptionData({
    required this.icon,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
    this.lockedReason,
  });

  final IconData icon;
  final String emoji;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final String? lockedReason;
  final VoidCallback onTap;
}

class _BudgetTextField extends StatefulWidget {
  const _BudgetTextField({required this.controller});

  final NewTripPrototypeController controller;

  @override
  State<_BudgetTextField> createState() => _BudgetTextFieldState();
}

class _BudgetTextFieldState extends State<_BudgetTextField> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.budgetPerPerson?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _BudgetTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.controller.budgetPerPerson?.toString() ?? '';
    if (_textController.text != next) {
      _textController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('new-trip-budget-field'),
      controller: _textController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: const InputDecoration(
        labelText: 'Oppure scrivi il tuo budget',
        prefixText: '€ ',
        suffixText: 'a persona',
        hintText: '650',
      ),
      onChanged: widget.controller.setBudgetFromText,
      onSubmitted: (_) => widget.controller.submitBudget(),
    );
  }
}

class _AdaptiveCounterPair extends StatelessWidget {
  const _AdaptiveCounterPair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 360 || textScale > 1.25;
        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 10), second],
          );
        }
        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}

class _CompactCounter extends StatelessWidget {
  const _CompactCounter({
    required this.label,
    required this.value,
    required this.minimum,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int minimum;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      value: '$value',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.outlined(
                  tooltip: 'Diminuisci $label',
                  onPressed: value > minimum
                      ? () => onChanged(value - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Aumenta $label',
                  onPressed: value < 30 ? () => onChanged(value + 1) : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    super.key,
    required this.type,
    required this.values,
    required this.controller,
    this.onChanged,
    this.readOnlyLabel,
  });

  final CalendarDatePicker2Type type;
  final List<DateTime?> values;
  final NewTripPrototypeController controller;
  final ValueChanged<List<DateTime>>? onChanged;
  final String? readOnlyLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final calendar = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: CalendarDatePicker2(
          config: CalendarDatePicker2Config(
            calendarType: type,
            firstDate: controller.today,
            lastDate: controller.lastSelectableDate,
            currentDate: controller.today,
            firstDayOfWeek: 1,
            weekdayLabels: const <String>['D', 'L', 'M', 'M', 'G', 'V', 'S'],
            dynamicCalendarRows: true,
            centerAlignModePicker: true,
            useAbbrLabelForMonthModePicker: true,
            controlsTextStyle: textTheme.titleMedium,
            weekdayLabelTextStyle: textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            dayTextStyle: textTheme.bodyMedium,
            todayTextStyle: textTheme.bodyMedium?.copyWith(
              color: colors.secondary,
              fontWeight: FontWeight.w800,
            ),
            selectedDayTextStyle: textTheme.bodyMedium?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
            selectedRangeDayTextStyle: textTheme.bodyMedium?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
            selectedDayHighlightColor: colors.primary,
            selectedRangeHighlightColor: colors.primaryContainer,
            dayBorderRadius: BorderRadius.circular(10),
            semanticsDictionary: const {
              CalendarDatePicker2SemanticsLabel.selectMonth:
                  'Seleziona il mese',
              CalendarDatePicker2SemanticsLabel.selectYear: 'Seleziona l’anno',
            },
          ),
          value: values,
          onValueChanged: (values) =>
              onChanged?.call(values.whereType<DateTime>().toList()),
        ),
      ),
    );
    final label = readOnlyLabel;
    if (label == null) return calendar;
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: IgnorePointer(ignoring: true, child: calendar),
      ),
    );
  }
}

class _DateValidation extends StatelessWidget {
  const _DateValidation({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    final message = controller.dateValidationMessage;
    return _SoftPanel(
      icon: message == null ? Icons.check_circle_outline : Icons.info_outline,
      title: message == null
          ? 'Disponibilità pronta'
          : 'Completa questa scelta',
      body: message ?? controller.plainSummaryFor(NewTripPrototypeStep.dates),
      isError:
          message != null && controller.dateMode != PrototypeDateMode.exact,
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({
    required this.icon,
    required this.title,
    required this.body,
    this.child,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? child;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = isError
        ? colors.errorContainer
        : colors.primaryContainer;
    final foreground = isError
        ? colors.onErrorContainer
        : colors.onPrimaryContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 22, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        body,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: foreground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (child != null) ...[const SizedBox(height: 12), child!],
          ],
        ),
      ),
    );
  }
}

IconData _dateModeIcon(PrototypeDateMode mode) => switch (mode) {
  PrototypeDateMode.exact => Icons.date_range_outlined,
  PrototypeDateMode.manualAvailability => Icons.event_available_outlined,
  PrototypeDateMode.savedAvailability => Icons.work_history_outlined,
  PrototypeDateMode.open => Icons.auto_awesome_outlined,
};

IconData _companyIcon(PrototypeCompany company) => switch (company) {
  PrototypeCompany.solo => Icons.person_outline,
  PrototypeCompany.couple => Icons.favorite_border,
  PrototypeCompany.friends => Icons.groups_outlined,
  PrototypeCompany.family => Icons.family_restroom_outlined,
};

IconData _transportIcon(PrototypeTransport transport) => switch (transport) {
  PrototypeTransport.flight => Icons.flight_outlined,
  PrototypeTransport.train => Icons.train_outlined,
  PrototypeTransport.bus => Icons.directions_bus_outlined,
  PrototypeTransport.car => Icons.directions_car_outlined,
};

IconData _travelStyleIcon(PrototypeTravelStyle style) => switch (style) {
  PrototypeTravelStyle.culture => Icons.museum_outlined,
  PrototypeTravelStyle.food => Icons.restaurant_outlined,
  PrototypeTravelStyle.nature => Icons.forest_outlined,
  PrototypeTravelStyle.sea => Icons.beach_access_outlined,
  PrototypeTravelStyle.rest => Icons.spa_outlined,
  PrototypeTravelStyle.localLife => Icons.storefront_outlined,
  PrototypeTravelStyle.nightlife => Icons.nightlife_outlined,
};

const List<String> _months = <String>[
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];

String _formatDayMonth(DateTime date) =>
    '${date.day} ${_months[date.month - 1]}';
