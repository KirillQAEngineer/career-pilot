import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:careerpilot_ui/features/feed/widgets/job_card.dart';
import 'package:careerpilot_ui/models/job.dart';
import 'package:careerpilot_ui/providers/job_interaction_provider.dart';
import 'package:careerpilot_ui/providers/jobs_provider.dart';
import 'package:careerpilot_ui/providers/profile_provider.dart';

import 'package:careerpilot_ui/features/feed/models/job_filters.dart';
import 'package:careerpilot_ui/features/feed/services/job_filter_service.dart';
import 'package:careerpilot_ui/features/feed/widgets/job_filter_popups.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CareerPilot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: profileAsync.when(
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
                  const Icon(Icons.description_outlined, size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    'Upload your resume first',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CareerPilot needs your resume to build a personalized job feed.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(profileProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check again'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (profile) {
          if (profile == null) {
            return const _ResumeRequiredState();
          }

          return const _JobsFeedContent();
        },
      ),
    );
  }
}

class _ResumeRequiredState extends StatelessWidget {
  const _ResumeRequiredState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.description_outlined, size: 72),
              SizedBox(height: 24),
              Text(
                'Upload your resume first',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'CareerPilot uses your resume to understand your experience, skills, and preferred roles before building your personalized job feed.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Open Profile and upload your resume to get started.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobsFeedContent extends ConsumerStatefulWidget {
  const _JobsFeedContent();

  @override
  ConsumerState<_JobsFeedContent> createState() => _JobsFeedContentState();
}

class _JobsFeedContentState extends ConsumerState<_JobsFeedContent> {
  final TextEditingController searchController = TextEditingController();

  final Set<String> _dislikingJobKeys = <String>{};
  final Set<String> _hiddenJobKeys = <String>{};

  final JobFilterService _filterService = const JobFilterService();

  JobFilters _filters = const JobFilters();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Job> filterJobs(List<Job> jobs) {
    return _filterService.apply(
      jobs: jobs,
      filters: _filters,
      hiddenJobKeys: _hiddenJobKeys,
    );
  }

  Future<void> _openWorkFormatFilter(
    List<Job> jobs,
    BuildContext buttonContext,
  ) async {
    final renderBox = buttonContext.findRenderObject() as RenderBox;

    final position = renderBox.localToGlobal(Offset(0, renderBox.size.height));

    final result = await showWorkFormatFilterPopup(
      context: context,
      position: position,
      currentValues: _filters.workFormats,
      values: _filterService.workFormats(jobs),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _filters = _filters.copyWith(workFormats: result);
    });
  }

  Future<void> _openPublicationDateFilter(BuildContext buttonContext) async {
    final renderBox = buttonContext.findRenderObject() as RenderBox;

    final position = renderBox.localToGlobal(Offset(0, renderBox.size.height));

    final result = await showPublicationDateFilterPopup(
      context: context,
      position: position,
      currentValue: _filters.publicationDate,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _filters = _filters.copyWith(
        publicationDate: result == _filters.publicationDate
            ? PublicationDateFilter.anyTime
            : result,
      );
    });
  }

  Future<void> _dislikeJob(Job job) async {
    final jobKey = job.stableKey;

    if (_dislikingJobKeys.contains(jobKey)) {
      return;
    }

    setState(() {
      _dislikingJobKeys.add(jobKey);
    });

    final success = await ref
        .read(jobInteractionProvider.notifier)
        .dislikeJob(job);

    if (!mounted) {
      return;
    }

    if (!success) {
      setState(() {
        _dislikingJobKeys.remove(jobKey);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to skip job')));

      return;
    }

    setState(() {
      _dislikingJobKeys.remove(jobKey);
      _hiddenJobKeys.add(jobKey);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Job skipped')));
  }

  void _updateQuery(String value) {
    setState(() {
      _filters = _filters.copyWith(query: value.trim());
    });
  }

  void _clearSearch() {
    searchController.clear();

    setState(() {
      _filters = _filters.copyWith(query: '');
    });
  }

  void _clearStructuredFilters() {
    if (!_filters.hasStructuredFilters) {
      return;
    }

    setState(() {
      _filters = _filters.clearStructuredFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(jobsProvider);

    return jobsAsync.when(
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
              TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onChanged: _updateQuery,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _filters.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Builder(
                    builder: (buttonContext) {
                      return FilterChip(
                        label: const Text('Work format'),
                        selected: _filters.workFormats.isNotEmpty,
                        onSelected: (_) {
                          _openWorkFormatFilter(items, buttonContext);
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (buttonContext) {
                      return FilterChip(
                        label: const Text('Publication date'),
                        selected:
                            _filters.publicationDate !=
                            PublicationDateFilter.anyTime,
                        onSelected: (_) {
                          _openPublicationDateFilter(buttonContext);
                        },
                      );
                    },
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _filters.hasStructuredFilters
                        ? _clearStructuredFilters
                        : null,
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Clear filters'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                  final isDisliking = _dislikingJobKeys.contains(job.stableKey);

                  return JobCard(
                    job: job,
                    isSkipping: isDisliking,
                    onSkip: () => _dislikeJob(job),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
