import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:careerpilot_ui/models/job.dart';
import 'package:careerpilot_ui/providers/jobs_provider.dart';
import 'package:careerpilot_ui/features/feed/widgets/job_card.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final TextEditingController searchController = TextEditingController();

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
      final title = job.title.toLowerCase();
      final company = job.company.toLowerCase();
      final location = job.location.toLowerCase();

      if (query.isNotEmpty) {
        final q = query.toLowerCase();

        final matchesSearch =
            title.contains(q) ||
            company.contains(q) ||
            location.contains(q);

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

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CareerPilot',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearchDialog();
            },
          ),
        ],
      ),
      body: jobsAsync.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredJobs.map(
                    (job) => JobCard(job: job),
                  ),
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