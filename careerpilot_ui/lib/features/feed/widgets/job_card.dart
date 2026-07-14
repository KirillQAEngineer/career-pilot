import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/job.dart';
import '../../../providers/job_interaction_provider.dart';
import '../../job/screens/job_details_screen.dart';
import '../../job/widgets/job_metadata.dart';

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
      ).showSnackBar(const SnackBar(content: Text('Job saved')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save job')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedJobs = ref.watch(jobInteractionProvider);
    final isSaved = savedJobs.contains(job.url);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              job.title.isEmpty ? 'Untitled vacancy' : job.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              job.company.isEmpty ? 'Company not specified' : job.company,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            JobMetadata(
              location: job.location,
              workFormat: job.workFormat,
              publishedAt: job.publishedAt,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: (job.score / 100).clamp(0.0, 1.0),
                      minHeight: 7,
                      color: matchColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${job.score.toStringAsFixed(0)}% Match',
                  style: TextStyle(
                    color: matchColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (job.whyMatch.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(job.whyMatch),
            ],
            if (job.missingSkills.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Missing skills:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: job.missingSkills
                          .map(
                            (skill) => Chip(
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              label: Text(skill),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('feed-skip-${job.stableKey}'),
                    onPressed: widget.isSkipping ? null : widget.onSkip,
                    icon: widget.isSkipping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close),
                    label: Text(widget.isSkipping ? 'Skipping...' : 'Skip'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaved || isSaving ? null : saveJob,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                          ),
                    label: Text(isSaved ? 'Saved' : 'Save'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailsScreen(job: job),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
