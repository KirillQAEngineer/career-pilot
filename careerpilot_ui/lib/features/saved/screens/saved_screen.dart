import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/saved_job.dart';
import '../../../providers/job_interaction_provider.dart';
import '../../../providers/saved_jobs_provider.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  final Set<String> _removingUrls = <String>{};

  Future<void> _removeJob(SavedJob job) async {
    if (_removingUrls.contains(job.url)) {
      return;
    }

    setState(() {
      _removingUrls.add(job.url);
    });

    final success = await ref
        .read(jobInteractionProvider.notifier)
        .unsaveJob(job.url);

    if (!mounted) {
      return;
    }

    setState(() {
      _removingUrls.remove(job.url);
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove saved job'),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job removed from Saved'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedJobs = ref.watch(savedJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Jobs',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: savedJobs.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(savedJobsProvider);
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
                ref.invalidate(savedJobsProvider);
                await ref.read(savedJobsProvider.future);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No saved jobs yet',
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
                        'Jobs saved from the Feed will appear here.',
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
              ref.invalidate(savedJobsProvider);
              await ref.read(savedJobsProvider.future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final job = items[index];
                final isRemoving = _removingUrls.contains(job.url);

                return _SavedJobCard(
                  job: job,
                  isRemoving: isRemoving,
                  onRemove: () => _removeJob(job),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SavedJobCard extends StatelessWidget {
  final SavedJob job;
  final bool isRemoving;
  final VoidCallback onRemove;

  const _SavedJobCard({
    required this.job,
    required this.isRemoving,
    required this.onRemove,
  });

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
              job.title.isEmpty
                  ? 'Untitled vacancy'
                  : job.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              job.company.isEmpty
                  ? 'Company not specified'
                  : job.company,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            if (job.createdAt != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Saved ${_formatDate(job.createdAt!)}',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRemoving
                        ? null
                        : onRemove,
                    icon: isRemoving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.bookmark_remove_outlined,
                          ),
                    label: Text(
                      isRemoving
                          ? 'Removing...'
                          : 'Remove',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: job.url.isEmpty
                        ? null
                        : () {
                            _showJobUrl(
                              context,
                              job.url,
                            );
                          },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open vacancy'),
                  ),
                ),
              ],
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

  void _showJobUrl(
    BuildContext context,
    String url,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Vacancy URL'),
          content: SizedBox(
            width: 600,
            child: SelectableText(url),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}