import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/url_launcher_utils.dart';
import '../../../models/applied_job.dart';
import '../../../providers/applied_jobs_provider.dart';

class ApplicationHistoryScreen extends ConsumerWidget {
  const ApplicationHistoryScreen({super.key});

  Future<void> _openJob(BuildContext context, AppliedJob job) async {
    final opened = await openExternalUrl(job.url);

    if (!context.mounted) {
      return;
    }

    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to open vacancy')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appliedJobs = ref.watch(appliedJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Application History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: appliedJobs.when(
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
                    onPressed: () {
                      ref.invalidate(appliedJobsProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(appliedJobsProvider);
                await ref.read(appliedJobsProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.send_outlined, size: 64),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No applications yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
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
            onRefresh: () async {
              ref.invalidate(appliedJobsProvider);
              await ref.read(appliedJobsProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final job = items[index];

                return _ApplicationCard(
                  job: job,
                  onOpen: () => _openJob(context, job),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final AppliedJob job;
  final VoidCallback onOpen;

  const _ApplicationCard({required this.job, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title.isEmpty ? 'Untitled vacancy' : job.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              job.company.isEmpty ? 'Company not specified' : job.company,
              style: const TextStyle(fontSize: 16),
            ),
            if (job.createdAt != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 18),
                  const SizedBox(width: 6),
                  Text('Applied ${_formatDate(job.createdAt!)}'),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: job.url.isEmpty ? null : onOpen,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Vacancy'),
              ),
            ),
          ],
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
