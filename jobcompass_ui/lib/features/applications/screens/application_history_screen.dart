import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/application.dart';
import '../../../models/application_stats.dart';
import '../../../providers/application_provider.dart';
import '../../job/screens/job_details_screen.dart';
import '../../job/widgets/job_comment_section.dart';
import '../../job/widgets/job_match_score.dart';
import '../models/application_status.dart';
import '../services/application_sort_service.dart';

class ApplicationHistoryScreen extends ConsumerStatefulWidget {
  const ApplicationHistoryScreen({super.key});

  @override
  ConsumerState<ApplicationHistoryScreen> createState() =>
      _ApplicationHistoryScreenState();
}

class _ApplicationHistoryScreenState
    extends ConsumerState<ApplicationHistoryScreen> {
  final Set<int> _updatingApplicationIds = <int>{};
  final ApplicationSortService _sortService = const ApplicationSortService();

  Future<void> _openJob(Application application) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailsScreen(job: application.toJob()),
      ),
    );
  }

  Future<void> _refreshApplications() async {
    await ref.read(applicationProvider.notifier).refresh();

    await ref.read(applicationStatsProvider.future);
  }

  Future<bool> _updateAnalyticsTotals(Map<String, int?> totals) {
    return ref
        .read(applicationStatsProvider.notifier)
        .updateAnalyticsTotals(totals);
  }

  Future<void> _updateApplicationStatus(
    Application application,
    String status,
  ) async {
    if (_updatingApplicationIds.contains(application.id) ||
        application.status == status) {
      return;
    }

    setState(() {
      _updatingApplicationIds.add(application.id);
    });

    final success = await ref
        .read(applicationProvider.notifier)
        .updateStatus(applicationId: application.id, status: status);

    if (!mounted) {
      return;
    }

    setState(() {
      _updatingApplicationIds.remove(application.id);
    });

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('failed_status'))));
    }
  }

  Future<void> _archiveApplication(Application application) async {
    if (_updatingApplicationIds.contains(application.id)) {
      return;
    }

    setState(() {
      _updatingApplicationIds.add(application.id);
    });

    final success = await ref
        .read(applicationProvider.notifier)
        .archive(application.id);

    if (!mounted) {
      return;
    }

    setState(() {
      _updatingApplicationIds.remove(application.id);
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('failed_archive_application'))),
      );
    }
  }

  Future<void> _unarchiveApplication(Application application) async {
    final success = await ref
        .read(applicationProvider.notifier)
        .unarchive(application.id);

    if (!mounted || !success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('failed_unarchive_application'))),
        );
      }
      return;
    }
  }

  Future<void> _openArchiveSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final archivedAsync = ref.watch(archivedApplicationsProvider);

            return _ArchivedApplicationsSheet(
              applicationsAsync: archivedAsync,
              sortService: _sortService,
              onOpen: (application) => _openJob(application),
              onRestore: (application) => _unarchiveApplication(application),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(applicationProvider);
    final statsAsync = ref.watch(applicationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('crm'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: applicationsAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _refreshApplications,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('retry')),
                  ),
                ],
              ),
            ),
          );
        },
        data: (applications) {
          final sortedApplications = _sortService.sort(applications);

          if (sortedApplications.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshApplications,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                children: [
                  _ApplicationDashboard(
                    statsAsync: statsAsync,
                    onUpdateAnalytics: _updateAnalyticsTotals,
                    onOpenArchive: _openArchiveSheet,
                  ),
                  const SizedBox(height: 80),
                  const Icon(Icons.send_outlined, size: 64),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      context.tr('crm_empty_title'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        context.tr('crm_empty_description'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshApplications,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10),
              itemCount: sortedApplications.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _ApplicationDashboard(
                      statsAsync: statsAsync,
                      onUpdateAnalytics: _updateAnalyticsTotals,
                      onOpenArchive: _openArchiveSheet,
                    ),
                  );
                }

                final application = sortedApplications[index - 1];

                return _ApplicationCard(
                  application: application,
                  isUpdating: _updatingApplicationIds.contains(application.id),
                  onStatusSelected: (status) {
                    _updateApplicationStatus(application, status);
                  },
                  onOpen: () {
                    _openJob(application);
                  },
                  onArchive: () {
                    _archiveApplication(application);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationDashboard extends StatelessWidget {
  final AsyncValue<ApplicationStats> statsAsync;
  final Future<bool> Function(Map<String, int?> totals) onUpdateAnalytics;
  final Future<void> Function() onOpenArchive;

  const _ApplicationDashboard({
    required this.statsAsync,
    required this.onUpdateAnalytics,
    required this.onOpenArchive,
  });

  Future<void> _openAnalyticsEditor(
    BuildContext context,
    ApplicationStats stats,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return _AnalyticsEditorDialog(stats: stats, onSave: onUpdateAnalytics);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () {
        return const Card(
          key: ValueKey('application-dashboard-loading'),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (error, stackTrace) {
        return Card(
          key: ValueKey('application-dashboard-error'),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              context.tr('failed_stats'),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      data: (stats) {
        final analyticsMetrics = [
          _DashboardMetric(
            key: 'analytics-total-applications',
            label: context.tr('total_applications'),
            value: stats.totalApplications,
            icon: Icons.send_outlined,
          ),
          _DashboardMetric(
            key: 'analytics-total-screenings',
            label: context.tr('total_screenings'),
            value: stats.totalScreenings,
            icon: Icons.fact_check_outlined,
          ),
          _DashboardMetric(
            key: 'analytics-total-interviews',
            label: context.tr('total_interviews'),
            value: stats.totalInterviews,
            icon: Icons.groups_outlined,
          ),
          _DashboardMetric(
            key: 'analytics-total-offers',
            label: context.tr('total_offers'),
            value: stats.totalOffers,
            icon: Icons.celebration_outlined,
          ),
          _DashboardMetric(
            key: 'analytics-total-rejected',
            label: context.tr('total_rejected'),
            value: stats.totalRejected,
            icon: Icons.cancel_outlined,
          ),
        ];

        final inProgressMetrics = [
          _DashboardMetric(
            key: 'in-progress-active',
            label: context.tr('active_processes'),
            value: stats.activeProcesses,
            icon: Icons.autorenew,
          ),
          _DashboardMetric(
            key: 'in-progress-screening',
            label: context.tr('screening'),
            value: stats.screeningInProgress,
            icon: Icons.fact_check_outlined,
          ),
          _DashboardMetric(
            key: 'in-progress-interview',
            label: context.tr('interview'),
            value: stats.interviewInProgress,
            icon: Icons.record_voice_over_outlined,
          ),
          _DashboardMetric(
            key: 'in-progress-technical-interview',
            label: context.tr('technical_interview'),
            value: stats.technicalInterviewInProgress,
            icon: Icons.code,
          ),
          _DashboardMetric(
            key: 'in-progress-offer',
            label: context.tr('offer'),
            value: stats.offerInProgress,
            icon: Icons.workspace_premium_outlined,
          ),
        ];

        return Column(
          key: const ValueKey('application-dashboard'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardSectionHeader(
              title: context.tr('analytics'),
              subtitle: context.tr('historical_totals'),
              action: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    key: const ValueKey('analytics-archive-button'),
                    tooltip: context.tr('archive'),
                    onPressed: onOpenArchive,
                    icon: const Icon(Icons.archive_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    key: const ValueKey('analytics-edit-button'),
                    tooltip: context.tr('edit_analytics'),
                    onPressed: () {
                      _openAnalyticsEditor(context, stats);
                    },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _DashboardMetricGrid(metrics: analyticsMetrics),
            const SizedBox(height: 20),
            _DashboardSectionHeader(
              title: context.tr('in_progress'),
              subtitle: context.tr('automatic_statuses'),
            ),
            const SizedBox(height: 12),
            _DashboardMetricGrid(metrics: inProgressMetrics),
          ],
        );
      },
    );
  }
}

class _DashboardMetric {
  final String key;
  final String label;
  final int value;
  final IconData icon;

  const _DashboardMetric({
    required this.key,
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _DashboardSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const _DashboardSectionHeader({
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

class _DashboardMetricGrid extends StatelessWidget {
  final List<_DashboardMetric> metrics;

  const _DashboardMetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        const minimumCardWidth = 150.0;
        final availableCardWidth =
            (constraints.maxWidth - spacing * (metrics.length - 1)) /
            metrics.length;
        final fitsWithoutScrolling = availableCardWidth >= minimumCardWidth;

        final cards = metrics.map((metric) {
          return SizedBox(
            width: fitsWithoutScrolling ? availableCardWidth : minimumCardWidth,
            child: _ApplicationMetricCard(
              metricKey: metric.key,
              label: metric.label,
              value: metric.value,
              icon: metric.icon,
            ),
          );
        }).toList();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                if (index > 0) const SizedBox(width: spacing),
                cards[index],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsEditorDialog extends StatefulWidget {
  final ApplicationStats stats;
  final Future<bool> Function(Map<String, int?> totals) onSave;

  const _AnalyticsEditorDialog({required this.stats, required this.onSave});

  @override
  State<_AnalyticsEditorDialog> createState() => _AnalyticsEditorDialogState();
}

class _AnalyticsEditorDialogState extends State<_AnalyticsEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _controllers = {
      'total_applications': TextEditingController(
        text: widget.stats.totalApplications.toString(),
      ),
      'total_screenings': TextEditingController(
        text: widget.stats.totalScreenings.toString(),
      ),
      'total_interviews': TextEditingController(
        text: widget.stats.totalInterviews.toString(),
      ),
      'total_offers': TextEditingController(
        text: widget.stats.totalOffers.toString(),
      ),
      'total_rejected': TextEditingController(
        text: widget.stats.totalRejected.toString(),
      ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _submit({required bool resetToAutomatic}) async {
    if (!resetToAutomatic && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final totals = {
      for (final entry in _controllers.entries)
        entry.key: resetToAutomatic ? null : int.parse(entry.value.text),
    };

    final success = await widget.onSave(totals);

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop();

      return;
    }

    setState(() {
      _isSaving = false;
      _errorMessage = 'Failed to save Analytics totals';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('analytics-editor-dialog'),
      title: Text(context.tr('edit_analytics')),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('analytics_editor_description')),
                const SizedBox(height: 20),
                _AnalyticsTotalField(
                  fieldKey: 'total-applications',
                  label: context.tr('total_applications'),
                  controller: _controllers['total_applications']!,
                ),
                const SizedBox(height: 12),
                _AnalyticsTotalField(
                  fieldKey: 'total-screenings',
                  label: context.tr('total_screenings'),
                  controller: _controllers['total_screenings']!,
                ),
                const SizedBox(height: 12),
                _AnalyticsTotalField(
                  fieldKey: 'total-interviews',
                  label: context.tr('total_interviews'),
                  controller: _controllers['total_interviews']!,
                ),
                const SizedBox(height: 12),
                _AnalyticsTotalField(
                  fieldKey: 'total-offers',
                  label: context.tr('total_offers'),
                  controller: _controllers['total_offers']!,
                ),
                const SizedBox(height: 12),
                _AnalyticsTotalField(
                  fieldKey: 'total-rejected',
                  label: context.tr('total_rejected'),
                  controller: _controllers['total_rejected']!,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('analytics-reset-button'),
          onPressed: _isSaving
              ? null
              : () {
                  _submit(resetToAutomatic: true);
                },
          child: Text(context.tr('use_automatic')),
        ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          key: const ValueKey('analytics-save-button'),
          onPressed: _isSaving
              ? null
              : () {
                  _submit(resetToAutomatic: false);
                },
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('save')),
        ),
      ],
    );
  }
}

class _AnalyticsTotalField extends StatelessWidget {
  final String fieldKey;
  final String label;
  final TextEditingController controller;

  const _AnalyticsTotalField({
    required this.fieldKey,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('analytics-$fieldKey-field'),
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final parsedValue = int.tryParse(value ?? '');

        if (parsedValue == null || parsedValue < 0) {
          return context.tr('enter_non_negative');
        }

        return null;
      },
    );
  }
}

class _ApplicationMetricCard extends StatelessWidget {
  final String metricKey;
  final String label;
  final int value;
  final IconData icon;

  const _ApplicationMetricCard({
    required this.metricKey,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: Card(
        key: ValueKey('application-metric-$metricKey'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Application application;
  final bool isUpdating;
  final ValueChanged<String> onStatusSelected;
  final VoidCallback onOpen;
  final VoidCallback onArchive;

  const _ApplicationCard({
    required this.application,
    required this.isUpdating,
    required this.onStatusSelected,
    required this.onOpen,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('application-card-${application.id}'),
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactLayout = constraints.maxWidth < 680;
              final metadata =
                  [
                        application.jobCompany,
                        application.jobLocation,
                        application.jobWorkFormat,
                        if (!compactLayout)
                          'Applied ${_formatDate(application.createdAt)}',
                      ]
                      .where(
                        (value) => value != null && value.trim().isNotEmpty,
                      )
                      .join(' • ');

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          application.jobTitle.isEmpty
                              ? context.tr('untitled_vacancy')
                              : application.jobTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          metadata.isEmpty
                              ? context.tr('details_not_specified')
                              : metadata,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  JobMatchScore(job: application.toJob()),
                  const SizedBox(width: 6),
                  JobCommentSection(
                    jobSource: application.jobSource,
                    jobExternalId: application.jobExternalId,
                    compact: true,
                  ),
                  if (isUpdating)
                    const SizedBox(
                      key: ValueKey('application-status-progress'),
                      width: 36,
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    _buildStatusMenu(context, compactLayout: compactLayout),
                  IconButton(
                    tooltip: context.tr('open_vacancy'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new, size: 20),
                  ),
                  IconButton(
                    tooltip: context.tr('archive_application'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: isUpdating ? null : onArchive,
                    icon: const Icon(Icons.archive_outlined, size: 20),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMenu(BuildContext context, {required bool compactLayout}) {
    final statusLabel = applicationStatusLabel(application.status, context);

    return PopupMenuButton<String>(
      key: ValueKey('application-status-menu-${application.id}'),
      tooltip: context.tr('change_status'),
      padding: EdgeInsets.zero,
      onSelected: onStatusSelected,
      itemBuilder: (context) {
        return applicationStatuses.map((status) {
          return CheckedPopupMenuItem<String>(
            value: status,
            checked: application.status == status,
            child: Text(applicationStatusLabel(status, context)),
          );
        }).toList();
      },
      child: Semantics(
        container: true,
        label: statusLabel,
        button: true,
        child: SizedBox(
          width: compactLayout ? 112 : 156,
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    key: ValueKey('application-status-label-${application.id}'),
                    statusLabel,
                    maxLines: 1,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    return '$day.$month.$year';
  }
}

class _ArchivedApplicationsSheet extends StatelessWidget {
  final AsyncValue<List<Application>> applicationsAsync;
  final ApplicationSortService sortService;
  final Future<void> Function(Application application) onOpen;
  final Future<void> Function(Application application) onRestore;

  const _ArchivedApplicationsSheet({
    required this.applicationsAsync,
    required this.sortService,
    required this.onOpen,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('archive'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('archived_applications_description'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: applicationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Center(child: Text(context.tr('failed_load_archive'))),
                  data: (applications) {
                    final archivedApplications = sortService.sort(applications);

                    if (archivedApplications.isEmpty) {
                      return Center(
                        child: Text(context.tr('archive_is_empty')),
                      );
                    }

                    return ListView.builder(
                      itemCount: archivedApplications.length,
                      itemBuilder: (context, index) {
                        final application = archivedApplications[index];
                        final metadata =
                            [application.jobCompany, application.jobLocation]
                                .where(
                                  (value) =>
                                      value != null && value.trim().isNotEmpty,
                                )
                                .join(' • ');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => onOpen(application),
                            title: Text(
                              application.jobTitle.isEmpty
                                  ? context.tr('untitled_vacancy')
                                  : application.jobTitle,
                            ),
                            subtitle: metadata.isEmpty
                                ? null
                                : Text(
                                    metadata,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  tooltip: context.tr('restore_from_archive'),
                                  onPressed: () => onRestore(application),
                                  icon: const Icon(Icons.unarchive_outlined),
                                ),
                                IconButton(
                                  tooltip: context.tr('open_vacancy'),
                                  onPressed: () => onOpen(application),
                                  icon: const Icon(Icons.open_in_new),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
