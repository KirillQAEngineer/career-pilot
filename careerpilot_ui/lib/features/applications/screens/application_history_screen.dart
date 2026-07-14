import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/url_launcher_utils.dart';
import '../../../models/application.dart';
import '../../../models/application_stats.dart';
import '../../../providers/application_provider.dart';
import '../../job/widgets/job_metadata.dart';
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
    final opened = await openExternalUrl(application.jobUrl);

    if (!mounted) {
      return;
    }

    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to open vacancy')));
    }
  }

  Future<void> _refreshApplications() async {
    await ref.read(applicationProvider.notifier).refresh();

    await ref.read(applicationStatsProvider.future);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update application status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicationsAsync = ref.watch(applicationProvider);
    final statsAsync = ref.watch(applicationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    label: const Text('Retry'),
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
                padding: const EdgeInsets.all(16),
                children: [
                  _ApplicationDashboard(statsAsync: statsAsync),
                  const SizedBox(height: 80),
                  const Icon(Icons.send_outlined, size: 64),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'No applications yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Jobs you apply to will appear here.',
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
              padding: const EdgeInsets.all(16),
              itemCount: sortedApplications.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _ApplicationDashboard(statsAsync: statsAsync),
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

  const _ApplicationDashboard({required this.statsAsync});

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
        return const Card(
          key: ValueKey('application-dashboard-error'),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Failed to load CRM statistics',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      data: (stats) {
        final metrics = [
          (
            key: 'total',
            label: 'Total Applications',
            value: stats.totalApplications,
            icon: Icons.send_outlined,
          ),
          (
            key: 'active',
            label: 'Active Processes',
            value: stats.activeProcesses,
            icon: Icons.autorenew,
          ),
          (
            key: 'interviews',
            label: 'Interviews',
            value: stats.interviews,
            icon: Icons.groups_outlined,
          ),
          (
            key: 'offers',
            label: 'Offers',
            value: stats.offers,
            icon: Icons.celebration_outlined,
          ),
          (
            key: 'rejected',
            label: 'Rejected',
            value: stats.rejected,
            icon: Icons.cancel_outlined,
          ),
        ];

        return Column(
          key: const ValueKey('application-dashboard'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final cardWidth = width >= 900
                    ? (width - 32) / 3
                    : width >= 560
                    ? (width - 16) / 2
                    : width;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: metrics.map((metric) {
                    return SizedBox(
                      width: cardWidth,
                      child: _ApplicationMetricCard(
                        metricKey: metric.key,
                        label: metric.label,
                        value: metric.value,
                        icon: metric.icon,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
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
    return Card(
      key: ValueKey('application-metric-$metricKey'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(label),
                ],
              ),
            ),
          ],
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

  const _ApplicationCard({
    required this.application,
    required this.isUpdating,
    required this.onStatusSelected,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              application.jobTitle.isEmpty
                  ? 'Untitled vacancy'
                  : application.jobTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              application.jobCompany.isEmpty
                  ? 'Company not specified'
                  : application.jobCompany,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            JobMetadata(
              location: application.jobLocation ?? '',
              workFormat: application.jobWorkFormat,
              publishedAt: _parsePublishedAt(application.jobPublishedAt),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (isUpdating)
                  const SizedBox(
                    key: ValueKey('application-status-progress'),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  PopupMenuButton<String>(
                    key: ValueKey('application-status-menu-${application.id}'),
                    tooltip: 'Change application status',
                    onSelected: onStatusSelected,
                    itemBuilder: (context) {
                      return applicationStatuses.map((status) {
                        return CheckedPopupMenuItem<String>(
                          value: status,
                          checked: application.status == status,
                          child: Text(applicationStatusLabel(status)),
                        );
                      }).toList();
                    },
                    child: Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(applicationStatusLabel(application.status)),
                      avatar: const Icon(Icons.arrow_drop_down, size: 18),
                    ),
                  ),
                const SizedBox(width: 12),
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Applied ${_formatDate(application.createdAt)}'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Spacer(),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: application.jobUrl.isEmpty ? null : onOpen,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parsePublishedAt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    return '$day.$month.$year';
  }
}
