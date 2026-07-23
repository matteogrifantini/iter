import 'package:flutter/material.dart';

import 'new_trip_lab_controller.dart';
import 'new_trip_lab_models.dart';
import 'new_trip_lab_steps.dart';

class NewTripSharedFlow extends StatelessWidget {
  const NewTripSharedFlow({
    super.key,
    required this.controller,
    required this.onBack,
    required this.onEditOrigin,
    required this.onFinish,
  });

  final NewTripPrototypeController controller;
  final VoidCallback onBack;
  final VoidCallback onEditOrigin;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final stage = controller.stage;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Indietro',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(switch (stage) {
          NewTripFlowStage.summary => 'Controlla la ricerca',
          NewTripFlowStage.searching => 'Cerchiamo possibilità',
          NewTripFlowStage.results => 'Possibilità trovate',
          NewTripFlowStage.compare => 'Confronta',
          NewTripFlowStage.selected => 'La tua scelta',
          NewTripFlowStage.questions => 'Nuovo viaggio',
        }),
      ),
      body: switch (stage) {
        NewTripFlowStage.summary => _SearchSummary(
          controller: controller,
          onEditOrigin: onEditOrigin,
        ),
        NewTripFlowStage.searching => _SearchingState(controller: controller),
        NewTripFlowStage.results => _ResultsList(controller: controller),
        NewTripFlowStage.compare => _Comparison(controller: controller),
        NewTripFlowStage.selected => _SelectedProposal(
          controller: controller,
          onFinish: onFinish,
        ),
        NewTripFlowStage.questions => const SizedBox.shrink(),
      },
      bottomNavigationBar: switch (stage) {
        NewTripFlowStage.summary => _SearchAction(controller: controller),
        NewTripFlowStage.results when controller.proposals.isNotEmpty =>
          _ShortlistTray(controller: controller),
        _ => null,
      },
    );
  }
}

class _SearchSummary extends StatelessWidget {
  const _SearchSummary({required this.controller, required this.onEditOrigin});

  final NewTripPrototypeController controller;
  final VoidCallback onEditOrigin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final steps = NewTripPrototypeStep.values
        .where((step) => step != NewTripPrototypeStep.origin)
        .toList(growable: false);
    final useAdaptiveSummaryList =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.25;
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Il viaggio che stiamo cercando',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Controlla i vincoli. Le destinazioni arrivano soltanto dopo questa conferma.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      NewTripOriginPill(
                        controller: controller,
                        onEdit: onEditOrigin,
                      ),
                      if (controller.activeRelaxation != null) ...[
                        const SizedBox(height: 12),
                        Chip(
                          avatar: const Icon(Icons.tune, size: 18),
                          label: Text(
                            'Tentativo: ${controller.activeRelaxation}',
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: useAdaptiveSummaryList
                    ? SliverList.builder(
                        itemCount: steps.length,
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SummaryCard(
                              step: step,
                              value: controller.plainSummaryFor(step),
                              onTap: () => controller.goToQuestion(
                                step,
                                returnToSummary: true,
                              ),
                            ),
                          );
                        },
                      )
                    : SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 360,
                              mainAxisExtent: 116,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: steps.length,
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          return _SummaryCard(
                            step: step,
                            value: controller.plainSummaryFor(step),
                            onTap: () => controller.goToQuestion(
                              step,
                              returnToSummary: true,
                            ),
                          );
                        },
                      ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 28)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchAction extends StatelessWidget {
  const _SearchAction({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 11, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('new-trip-search'),
              onPressed: controller.canStartSearch
                  ? controller.startSearch
                  : null,
              icon: const Icon(Icons.travel_explore),
              label: const Text('Cerca possibilità'),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.step,
    required this.value,
    required this.onTap,
  });

  final NewTripPrototypeStep step;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${step.label}. $value. Modifica',
      child: Material(
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_stepIcon(step), size: 19, color: colors.primary),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        step.label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_outlined, size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchingState extends StatelessWidget {
  const _SearchingState({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.travel_explore,
                    size: 34,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  controller.searchMessages[controller.searchMessageIndex],
                  key: const ValueKey('new-trip-search-stage'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nessuna percentuale inventata: ti diciamo cosa stiamo confrontando.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 26),
                for (
                  var index = 0;
                  index < controller.searchMessages.length;
                  index++
                )
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          index < controller.searchMessageIndex
                              ? Icons.check_circle
                              : index == controller.searchMessageIndex
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: index <= controller.searchMessageIndex
                              ? colors.primary
                              : colors.outline,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            controller.searchMessages[index],
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight:
                                      index == controller.searchMessageIndex
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.proposals.isEmpty) {
      return _NoResults(controller: controller);
    }
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '6 viaggi, già confrontabili',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tieni da due a quattro proposte. Il prezzo viene prima della scelta finale.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final sort in PrototypeProposalSort.values)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(sort.label),
                                  selected: controller.proposalSort == sort,
                                  onSelected: (_) =>
                                      controller.setProposalSort(sort),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
                sliver: SliverList.builder(
                  itemCount: controller.sortedProposals.length,
                  itemBuilder: (context, index) {
                    final proposal = controller.sortedProposals[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ProposalCard(
                        proposal: proposal,
                        controller: controller,
                        onDetails: () =>
                            _showProposalDetails(context, controller, proposal),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.controller,
    required this.onDetails,
  });

  final PrototypeTravelProposal proposal;
  final NewTripPrototypeController controller;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shortlisted = controller.isShortlisted(proposal.id);
    return Card(
      key: ValueKey('proposal-${proposal.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 8.2,
                child: Image.asset(proposal.heroAsset, fit: BoxFit.cover),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: _Badge(
                  icon: Icons.auto_awesome,
                  label: '${proposal.fitScore}% compatibile',
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: IconButton.filledTonal(
                  tooltip: shortlisted
                      ? 'Rimuovi dal confronto'
                      : 'Tieni per il confronto',
                  onPressed: controller.shortlistIsFull && !shortlisted
                      ? null
                      : () => controller.toggleShortlist(proposal.id),
                  icon: Icon(
                    shortlisted ? Icons.bookmark : Icons.bookmark_border,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            proposal.journey.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            proposal.journey.stops.join(' · '),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _priceLabel(proposal),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          _groupPriceLabel(proposal, controller.travelers),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      icon: Icons.event_outlined,
                      label: proposal.bestDateLabel,
                    ),
                    _InfoPill(
                      icon: switch (proposal.arrivalTransport) {
                        PrototypeTransport.flight => Icons.flight_outlined,
                        PrototypeTransport.train => Icons.train_outlined,
                        PrototypeTransport.bus => Icons.directions_bus_outlined,
                        PrototypeTransport.car => Icons.directions_car_outlined,
                      },
                      label: proposal.arrivalTransport.label,
                    ),
                    _InfoPill(
                      icon: Icons.schedule_outlined,
                      label: _travelTime(proposal.travelMinutes),
                    ),
                    _InfoPill(
                      icon: Icons.multiple_stop_outlined,
                      label: proposal.changesCount == 0
                          ? 'Diretto'
                          : '${proposal.changesCount} cambio',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  proposal.matchReasons.first,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.tertiaryContainer.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Compromesso: ${proposal.compromise}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onDetails,
                        child: const Text('Dettagli'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: controller.shortlistIsFull && !shortlisted
                            ? null
                            : () => controller.toggleShortlist(proposal.id),
                        icon: Icon(shortlisted ? Icons.check : Icons.add),
                        label: Text(
                          shortlisted ? 'Tenuta' : 'Tieni per il confronto',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${proposal.confidence.label} · ${proposal.freshnessLabel}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortlistTray extends StatelessWidget {
  const _ShortlistTray({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 12,
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stackVertically =
                  constraints.maxWidth < 430 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.25;
              final status = Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${controller.shortlistIds.length}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      controller.canCompare
                          ? 'Pronte per il confronto'
                          : controller.shortlistIds.isEmpty
                          ? 'Tieni almeno due proposte'
                          : 'Tieni ancora una proposta',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              );
              final compareButton = FilledButton.icon(
                key: const ValueKey('new-trip-compare'),
                onPressed: controller.canCompare
                    ? controller.openComparison
                    : null,
                icon: const Icon(Icons.compare_arrows),
                label: Text('Confronta (${controller.shortlistIds.length})'),
              );
              if (stackVertically) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [status, const SizedBox(height: 8), compareButton],
                );
              }
              return Row(
                children: [
                  Expanded(child: status),
                  const SizedBox(width: 10),
                  compareButton,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Comparison extends StatelessWidget {
  const _Comparison({required this.controller});

  final NewTripPrototypeController controller;

  @override
  Widget build(BuildContext context) {
    final proposals = controller.comparisonProposals;
    final cheapest = proposals.reduce(
      (left, right) => left.cost.total <= right.cost.total ? left : right,
    );
    final simplest = proposals.reduce(
      (left, right) => left.travelMinutes <= right.travelMinutes ? left : right,
    );
    final bestFit = proposals.reduce(
      (left, right) => left.fitScore >= right.fitScore ? left : right,
    );
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Text(
                '${proposals.length} possibilità, criterio per criterio',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Nessun punteggio opaco: costi, date e compromessi restano leggibili.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              _ComparisonSection(
                icon: Icons.payments_outlined,
                title: 'Costo',
                proposals: proposals,
                bestId: cheapest.id,
                bestLabel: 'Miglior prezzo',
                valueFor: (proposal) =>
                    '${_priceLabel(proposal)} · ${_groupPriceLabel(proposal, controller.travelers)}\n'
                    'Viaggio €${proposal.cost.transport} · soggiorno €${proposal.cost.stay} · sul posto €${proposal.cost.local}',
              ),
              _ComparisonSection(
                icon: Icons.event_available_outlined,
                title: 'Quando',
                proposals: proposals,
                valueFor: (proposal) =>
                    '${proposal.bestDateLabel}\n${proposal.alternativeDates.isEmpty ? 'Nessuna alternativa equivalente' : proposal.alternativeDates.join(' · ')}',
              ),
              _ComparisonSection(
                icon: Icons.route_outlined,
                title: 'Come arrivare',
                proposals: proposals,
                bestId: simplest.id,
                bestLabel: 'Meno spostamenti',
                valueFor: (proposal) =>
                    '${_travelTime(proposal.travelMinutes)} · ${proposal.changesCount == 0 ? 'diretto' : '${proposal.changesCount} cambio'} · ${proposal.arrivalTransport.label}',
              ),
              _ComparisonSection(
                icon: Icons.luggage_outlined,
                title: 'Cosa ottieni',
                proposals: proposals,
                valueFor: (proposal) =>
                    '${proposal.durationDays} giorni · ${proposal.journey.stops.join(' · ')}\n${proposal.journey.summary}',
              ),
              _ComparisonSection(
                icon: Icons.auto_awesome_outlined,
                title: 'Compatibilità e compromessi',
                proposals: proposals,
                bestId: bestFit.id,
                bestLabel: 'Più coerente',
                valueFor: (proposal) =>
                    '${proposal.matchReasons.join(' ')}\nCompromesso: ${proposal.compromise}',
              ),
              const SizedBox(height: 4),
              Text(
                'Quale portiamo avanti?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (final proposal in proposals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('choose-${proposal.id}'),
                      onTap: () => controller.chooseProposal(proposal.id),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Scegli ${proposal.journey.title}',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection({
    required this.icon,
    required this.title,
    required this.proposals,
    required this.valueFor,
    this.bestId,
    this.bestLabel,
  });

  final IconData icon;
  final String title;
  final List<PrototypeTravelProposal> proposals;
  final String Function(PrototypeTravelProposal) valueFor;
  final String? bestId;
  final String? bestLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < proposals.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: proposals[index].id == bestId
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    child: Text('${index + 1}'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                proposals[index].journey.title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            if (proposals[index].id == bestId &&
                                bestLabel != null)
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(bestLabel!),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(valueFor(proposals[index])),
                      ],
                    ),
                  ),
                ],
              ),
              if (index != proposals.length - 1) const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedProposal extends StatelessWidget {
  const _SelectedProposal({required this.controller, required this.onFinish});

  final NewTripPrototypeController controller;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final proposal = controller.selectedProposal!;
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(proposal.heroAsset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Hai scelto',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                proposal.journey.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                proposal.journey.summary,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    icon: Icons.event_outlined,
                    label: proposal.bestDateLabel,
                  ),
                  _InfoPill(
                    icon: Icons.payments_outlined,
                    label: _priceLabel(proposal),
                  ),
                  _InfoPill(
                    icon: Icons.verified_outlined,
                    label: proposal.confidence.label,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Il prezzo non è bloccato. Nella versione reale verrà verificato prima di scegliere trasporto e alloggio.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.selectedAlternatives.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  'Alternative conservate',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final alternative in controller.selectedAlternatives)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bookmark_outline),
                    title: Text(alternative.journey.title),
                    subtitle: Text(_priceLabel(alternative)),
                  ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const ValueKey('new-trip-finish'),
                onPressed: onFinish,
                icon: const Icon(Icons.check),
                label: const Text('Chiudi anteprima'),
              ),
              const SizedBox(height: 8),
              Text(
                'Anteprima: nessun viaggio è stato salvato.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatefulWidget {
  const _NoResults({required this.controller});

  final NewTripPrototypeController controller;

  @override
  State<_NoResults> createState() => _NoResultsState();
}

class _NoResultsState extends State<_NoResults> {
  int _relaxationIndex = 0;

  @override
  Widget build(BuildContext context) {
    const relaxations = <(String, String, IconData)>[
      (
        '+1 giorno',
        'Può sbloccare itinerari con trasferimenti più comodi.',
        Icons.more_time,
      ),
      (
        'Aeroporto vicino',
        'Amplia la partenza senza cambiare destinazione.',
        Icons.connecting_airports,
      ),
      (
        '+€100',
        'Può rendere disponibili Parigi e l’Atlantico.',
        Icons.savings_outlined,
      ),
    ];
    final relaxation = relaxations[_relaxationIndex];
    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.search_off_outlined, size: 58),
              const SizedBox(height: 18),
              Text(
                'Nessuna combinazione abbastanza buona',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Cambiamo un solo vincolo alla volta, così sai cosa ha davvero sbloccato una proposta.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      widget.controller.retryWithRelaxation(relaxation.$1),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 84),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(relaxation.$3),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  relaxation.$1,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(relaxation.$2),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _relaxationIndex =
                        (_relaxationIndex + 1) % relaxations.length;
                  }),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Mostra un’altra modifica'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showProposalDetails(
  BuildContext context,
  NewTripPrototypeController controller,
  PrototypeTravelProposal proposal,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: FractionallySizedBox(
          heightFactor: .88,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text(
                proposal.journey.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              Text(
                proposal.journey.summary,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              _DetailBlock(
                title: 'Migliore combinazione',
                body: '${proposal.bestDateLabel} · ${_priceLabel(proposal)}',
              ),
              _DetailBlock(
                title: 'Alternative',
                body: proposal.alternativeDates.isEmpty
                    ? 'Nessuna alternativa equivalente nelle preferenze attuali.'
                    : proposal.alternativeDates.join('\n'),
              ),
              _DetailBlock(
                title: 'Assunzioni del costo',
                body:
                    'Trasporto €${proposal.cost.transport}\nAlloggio €${proposal.cost.stay}\nSpese locali €${proposal.cost.local}',
              ),
              _DetailBlock(
                title: 'Perché funziona',
                body: proposal.matchReasons.join('\n'),
              ),
              _DetailBlock(title: 'Compromesso', body: proposal.compromise),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  controller.chooseProposal(proposal.id);
                  Navigator.of(sheetContext).pop();
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Scegli questa proposta'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    controller.shortlistIsFull &&
                        !controller.isShortlisted(proposal.id)
                    ? null
                    : () {
                        controller.toggleShortlist(proposal.id);
                        Navigator.of(sheetContext).pop();
                      },
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Tieni per il confronto'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .68),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _stepIcon(NewTripPrototypeStep step) => switch (step) {
  NewTripPrototypeStep.origin => Icons.location_on_outlined,
  NewTripPrototypeStep.dates => Icons.event_available_outlined,
  NewTripPrototypeStep.company => Icons.groups_outlined,
  NewTripPrototypeStep.transport => Icons.commute_outlined,
  NewTripPrototypeStep.budget => Icons.payments_outlined,
  NewTripPrototypeStep.travelStyle => Icons.auto_awesome_outlined,
  NewTripPrototypeStep.pace => Icons.speed_outlined,
  NewTripPrototypeStep.walking => Icons.directions_walk_outlined,
};

String _priceLabel(PrototypeTravelProposal proposal) => proposal.hasPriceRange
    ? '€${proposal.cost.total}–€${proposal.priceRangeMax} p.p.'
    : '€${proposal.cost.total} p.p.';

String _groupPriceLabel(PrototypeTravelProposal proposal, int travelers) {
  final minimum = proposal.groupTotal(travelers);
  final maximum = proposal.priceRangeMax == null
      ? null
      : proposal.priceRangeMax! * travelers;
  return maximum == null ? '€$minimum gruppo' : '€$minimum–€$maximum gruppo';
}

String _travelTime(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest min';
  return rest == 0 ? '${hours}h' : '${hours}h $rest';
}
