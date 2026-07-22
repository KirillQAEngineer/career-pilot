import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/job.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/job_interaction_provider.dart';
import '../../job/screens/job_details_screen.dart';
import '../../job/widgets/job_comment_section.dart';

class JobCard extends ConsumerStatefulWidget {
  final Job job;
  final bool isSkipping;
  final VoidCallback onSkip;

  const JobCard({
    super.key,
    required this.job,
    required this.isSkipping,
    required this.onSkip,
  });

  @override
  ConsumerState<JobCard> createState() => _JobCardState();
}

class _JobCardState extends ConsumerState<JobCard> {
  bool isSaving = false;

  Job get job => widget.job;

  Color get matchColor {
    if (job.score >= 85) return Colors.green;
    if (job.score >= 70) return Colors.blue;
    if (job.score >= 50) return Colors.orange;
    return Colors.red;
  }

  Future<void> saveJob() async {
    if (isSaving) {
      return;
    }

    final notifier = ref.read(jobInteractionProvider.notifier);

    if (notifier.isSaved(job)) {
      return;
    }

    setState(() {
      isSaving = true;
    });

    final success = await notifier.saveJob(job);

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('job_saved'))));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('could_not_save'))));
    }
  }

  void openJob() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedJobs = ref.watch(jobInteractionProvider);
    final isSaved = savedJobs.contains(job.url);
    final metadata = [
      job.company,
      job.location,
      job.workFormat,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' • ');

    return Card(
      key: ValueKey('feed-job-${job.stableKey}'),
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openJob,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactLayout = constraints.maxWidth < 680;

              return Row(
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
                  if (!compactLayout)
                    SizedBox(
                      width: 76,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${job.score.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: matchColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: (job.score / 100).clamp(0.0, 1.0),
                              minHeight: 4,
                              color: matchColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '${job.score.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: matchColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(width: 6),
                  JobCommentSection(
                    jobSource: job.source,
                    jobExternalId: job.externalId,
                    compact: true,
                  ),
                  IconButton(
                    key: ValueKey('feed-skip-${job.stableKey}'),
                    tooltip: context.tr('skip'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.isSkipping ? null : widget.onSkip,
                    icon: widget.isSkipping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close, size: 20),
                  ),
                  IconButton(
                    tooltip: isSaved
                        ? context.tr('saved_action')
                        : context.tr('save_action'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: isSaved || isSaving ? null : saveJob,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 20,
                          ),
                  ),
                  IconButton(
                    tooltip: context.tr('open_vacancy'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: openJob,
                    icon: const Icon(Icons.open_in_new, size: 20),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
