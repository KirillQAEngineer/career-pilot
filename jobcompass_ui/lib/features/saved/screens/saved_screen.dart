import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/saved_job.dart';
import '../../../providers/job_interaction_provider.dart';
import '../../../providers/saved_jobs_provider.dart';
import '../../feed/models/job_filters.dart';
import '../../feed/services/job_filter_service.dart';
import '../../feed/widgets/job_filter_popups.dart';
import '../../job/screens/job_details_screen.dart';
import '../../job/widgets/job_comment_section.dart';
import '../../job/widgets/job_match_score.dart';
import '../../../core/localization/app_localizations.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  final TextEditingController _searchController = TextEditingController();

  final JobFilterService _filterService = const JobFilterService();

  final Set<String> _removingJobKeys = <String>{};

  JobFilters _filters = const JobFilters();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedJob> _filterJobs(List<SavedJob> jobs) {
    return _filterService.apply(jobs: jobs, filters: _filters);
  }

  void _updateQuery(String value) {
    setState(() {
      _filters = _filters.copyWith(query: value.trim());
    });
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _filters = _filters.copyWith(query: '');
    });
  }

  void _clearStructuredFilters() {
    setState(() {
      _filters = _filters.clearStructuredFilters();
    });
  }

  Future<void> _openWorkFormatFilter(BuildContext buttonContext) async {
    final renderBox = buttonContext.findRenderObject() as RenderBox;

    final position = renderBox.localToGlobal(Offset(0, renderBox.size.height));

    final result = await showWorkFormatFilterPopup(
      context: context,
      position: position,
      currentValues: _filters.workFormats,
      values: JobFilterService.supportedWorkFormats,
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
      _filters = _filters.copyWith(publicationDate: result);
    });
  }

  Future<void> _removeJob(SavedJob job) async {
    final jobKey = job.stableKey;

    if (_removingJobKeys.contains(jobKey)) {
      return;
    }

    setState(() {
      _removingJobKeys.add(jobKey);
    });

    final success = await ref
        .read(jobInteractionProvider.notifier)
        .unsaveJob(job.url);

    if (!mounted) {
      return;
    }

    setState(() {
      _removingJobKeys.remove(jobKey);
    });

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('failed_remove_job'))));

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr('job_removed'))));
  }

  Future<void> _refreshSavedJobs() async {
    ref.invalidate(savedJobsProvider);
    await ref.read(savedJobsProvider.future);
  }

  void _openJob(SavedJob job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job.toJob())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedJobs = ref.watch(savedJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('saved'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: savedJobs.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return _SavedErrorState(
            error: error,
            onRetry: () {
              ref.invalidate(savedJobsProvider);
            },
          );
        },
        data: (items) {
          if (items.isEmpty) {
            return _SavedEmptyState(onRefresh: _refreshSavedJobs);
          }

          final filteredJobs = _filterJobs(items);

          return RefreshIndicator(
            onRefresh: _refreshSavedJobs,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10),
              children: [
                TextField(
                  controller: _searchController,
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
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Builder(
                        builder: (buttonContext) {
                          return FilterChip(
                            label: Text(
                              _filters.workFormats.isEmpty
                                  ? context.tr('work_format')
                                  : '${context.tr('work_format')} (${_filters.workFormats.length})',
                            ),
                            selected: _filters.workFormats.isNotEmpty,
                            onSelected: (_) {
                              _openWorkFormatFilter(buttonContext);
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Builder(
                        builder: (buttonContext) {
                          return FilterChip(
                            label: Text(
                              publicationDateLabel(
                                _filters.publicationDate,
                                context,
                              ),
                            ),
                            selected:
                                _filters.publicationDate !=
                                PublicationDateFilter.anyTime,
                            onSelected: (_) {
                              _openPublicationDateFilter(buttonContext);
                            },
                          );
                        },
                      ),
                      if (_filters.hasStructuredFilters) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _clearStructuredFilters,
                          icon: const Icon(Icons.restart_alt),
                          label: Text(context.tr('reset')),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (filteredJobs.isEmpty)
                  const _NoSavedJobsFoundState()
                else
                  ...filteredJobs.map((job) {
                    final isRemoving = _removingJobKeys.contains(job.stableKey);

                    return _SavedJobCard(
                      job: job,
                      isRemoving: isRemoving,
                      onRemove: () => _removeJob(job),
                      onOpen: () => _openJob(job),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SavedErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _SavedErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
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
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _SavedEmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 180),
          Icon(Icons.bookmark_border, size: 64),
          SizedBox(height: 16),
          Center(
            child: Text(
              context.tr('no_saved_jobs_yet'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                context.tr('saved_from_feed'),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSavedJobsFoundState extends StatelessWidget {
  const _NoSavedJobsFoundState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 100),
      child: Center(
        child: Text(
          context.tr('no_saved_jobs'),
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class _SavedJobCard extends StatelessWidget {
  final SavedJob job;
  final bool isRemoving;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  const _SavedJobCard({
    required this.job,
    required this.isRemoving,
    required this.onRemove,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = [
      job.company,
      job.location,
      job.workFormat,
      if (job.createdAt != null) 'Saved ${_formatDate(job.createdAt!)}',
    ].where((value) => value != null && value.trim().isNotEmpty).join(' • ');

    return Card(
      key: ValueKey('saved-job-${job.stableKey}'),
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title.isEmpty
                          ? context.tr('untitled_vacancy')
                          : job.title,
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
              JobMatchScore(job: job.toJob()),
              const SizedBox(width: 6),
              JobCommentSection(
                jobSource: job.source,
                jobExternalId: job.externalId,
                compact: true,
              ),
              IconButton(
                tooltip: isRemoving
                    ? context.tr('removing_saved')
                    : context.tr('remove_saved'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                visualDensity: VisualDensity.compact,
                onPressed: isRemoving ? null : onRemove,
                icon: isRemoving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_remove_outlined, size: 20),
              ),
              IconButton(
                key: ValueKey('saved-open-${job.stableKey}'),
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
