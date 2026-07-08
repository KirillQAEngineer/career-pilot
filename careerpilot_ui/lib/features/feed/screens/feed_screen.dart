import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:careerpilot_ui/features/feed/widgets/job_card.dart';
import 'package:careerpilot_ui/models/job.dart';
import 'package:careerpilot_ui/providers/job_interaction_provider.dart';
import 'package:careerpilot_ui/providers/jobs_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final TextEditingController searchController = TextEditingController();

  final Set<String> _dislikingUrls = <String>{};
  final Set<String> _hiddenUrls = <String>{};

  String query = '';

  bool remoteOnly = false;
  bool backendOnly = false;
  bool pythonOnly = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Job> filterJobs(List<Job> jobs) {
    return jobs.where((job) {
      if (_hiddenUrls.contains(job.url)) {
        return false;
      }

      final title = job.title.toLowerCase();
      final company = job.company.toLowerCase();
      final location = job.location.toLowerCase();

      if (query.isNotEmpty) {
        final q = query.toLowerCase();

        final matchesSearch =
            title.contains(q) || company.contains(q) || location.contains(q);

        if (!matchesSearch) {
          return false;
        }
      }

      if (remoteOnly && !location.contains('remote')) {
        return false;
      }

      if (backendOnly && !title.contains('backend')) {
        return false;
      }

      if (pythonOnly && !title.contains('python')) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> _dislikeJob(Job job) async {
    if (_dislikingUrls.contains(job.url)) {
      return;
    }

    setState(() {
      _dislikingUrls.add(job.url);
    });

    final success = await ref
        .read(jobInteractionProvider.notifier)
        .dislikeJob(job);

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        _dislikingUrls.remove(job.url);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to skip job')));

      return;
    }

    setState(() {
      _dislikingUrls.remove(job.url);
      _hiddenUrls.add(job.url);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Job skipped')));
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CareerPilot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: showSearchDialog,
          ),
        ],
      ),
      body: jobsAsync.when(
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
                      ref.invalidate(jobsProvider);
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
          final filteredJobs = filterJobs(items);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(jobsProvider);
              await ref.read(jobsProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Remote'),
                      selected: remoteOnly,
                      onSelected: (selected) {
                        setState(() {
                          remoteOnly = selected;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Backend'),
                      selected: backendOnly,
                      onSelected: (selected) {
                        setState(() {
                          backendOnly = selected;
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Python'),
                      selected: pythonOnly,
                      onSelected: (selected) {
                        setState(() {
                          pythonOnly = selected;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (query.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Search: "$query"',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          searchController.clear();

                          setState(() {
                            query = '';
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (filteredJobs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: Text(
                        'No jobs found',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  )
                else
                  ...filteredJobs.map((job) {
                    final isDisliking = _dislikingUrls.contains(job.url);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        JobCard(job: job),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 8,
                            right: 8,
                            bottom: 16,
                          ),
                          child: OutlinedButton.icon(
                            onPressed: isDisliking
                                ? null
                                : () => _dislikeJob(job),
                            icon: isDisliking
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.close),
                            label: Text(isDisliking ? 'Skipping...' : 'Skip'),
                          ),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> showSearchDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Search jobs'),
          content: TextField(
            controller: searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Python, Google, Remote...',
            ),
            onSubmitted: (value) {
              setState(() {
                query = value.trim();
              });

              Navigator.pop(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                searchController.clear();

                setState(() {
                  query = '';
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  query = searchController.text.trim();
                });

                Navigator.pop(dialogContext);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}
