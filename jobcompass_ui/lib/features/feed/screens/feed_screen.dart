import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jobcompass_ui/features/feed/widgets/job_card.dart';
import 'package:jobcompass_ui/models/job.dart';
import 'package:jobcompass_ui/providers/job_interaction_provider.dart';
import 'package:jobcompass_ui/providers/jobs_provider.dart';
import 'package:jobcompass_ui/providers/profile_provider.dart';

import 'package:jobcompass_ui/features/feed/models/job_filters.dart';
import 'package:jobcompass_ui/features/feed/services/job_filter_service.dart';
import 'package:jobcompass_ui/features/feed/widgets/job_filter_popups.dart';
import 'package:jobcompass_ui/core/localization/app_localizations.dart';

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
          'JobCompass',
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
                  Text(
                    context.tr('upload_resume_first'),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('feed_resume_description'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(profileProvider);
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('check_again')),
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
            children: [
              Icon(Icons.description_outlined, size: 72),
              SizedBox(height: 24),
              Text(
                context.tr('upload_resume_first'),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                context.tr('feed_resume_long_description'),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                context.tr('open_profile_upload'),
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
  bool _isRefreshing = false;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
      ).showSnackBar(SnackBar(content: Text(context.tr('failed_skip'))));

      return;
    }

    setState(() {
      _dislikingJobKeys.remove(jobKey);
      _hiddenJobKeys.add(jobKey);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('job_skipped'))));
  }

  void _updateQuery(String value) {
    final query = value.trim();

    setState(() {
      _filters = _filters.copyWith(query: query);
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(jobsProvider.notifier).search(query);
    });
  }

  void _clearSearch() {
    searchController.clear();

    setState(() {
      _filters = _filters.copyWith(query: '');
    });

    _searchDebounce?.cancel();
    ref.read(jobsProvider.notifier).search('');
  }

  void _clearStructuredFilters() {
    if (!_filters.hasStructuredFilters) {
      return;
    }

    setState(() {
      _filters = _filters.clearStructuredFilters();
    });
  }

  Future<void> _refreshJobs() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    final success = await ref.read(jobsProvider.notifier).refresh();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRefreshing = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('refresh_jobs_failed'))),
      );
    }
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
                  onPressed: _isRefreshing ? null : _refreshJobs,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(context.tr('retry')),
                ),
              ],
            ),
          ),
        );
      },
      data: (items) {
        final filteredJobs = filterJobs(items);
        final sources =
            items
                .map((job) => job.source.trim())
                .where((source) => source.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        return RefreshIndicator(
          onRefresh: _refreshJobs,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            children: [
              _FeedStatsBlock(
                visibleJobs: filteredJobs.length,
                sources: sources,
                onRefresh: _refreshJobs,
                isRefreshing: _isRefreshing,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                onChanged: _updateQuery,
                decoration: InputDecoration(
                  hintText: context.tr('search'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _filters.query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.tr('clear_search'),
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
                        label: Text(context.tr('work_format')),
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
                        label: Text(context.tr('publication_date')),
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
                    label: Text(context.tr('clear_filters')),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (filteredJobs.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Center(
                    child: Text(
                      context.tr('no_jobs_found'),
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

class _FeedStatsBlock extends StatelessWidget {
  const _FeedStatsBlock({
    required this.visibleJobs,
    required this.sources,
    required this.onRefresh,
    required this.isRefreshing,
  });

  final int visibleJobs;
  final List<String> sources;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final previewSources = sources.take(5).join(', ');
    final remainingSources = sources.length > 5
        ? ' +${sources.length - 5}'
        : '';
    final sourceText = sources.isEmpty
        ? context.tr('sources_unknown')
        : '$previewSources$remainingSources';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: DefaultTextStyle(
        style: textTheme.bodySmall!.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('${context.tr('jobs_visible')}: $visibleJobs'),
            Text(
              '${context.tr('job_sources')}: $sourceText',
              overflow: TextOverflow.ellipsis,
            ),
            IconButton(
              tooltip: context.tr('refresh_jobs'),
              onPressed: isRefreshing ? null : onRefresh,
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              icon: isRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}
