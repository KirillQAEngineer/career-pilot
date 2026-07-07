import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/job.dart';
import '../../../providers/job_interaction_provider.dart';
import '../../job/screens/job_details_screen.dart';

class JobCard extends ConsumerStatefulWidget {
  final Job job;

  const JobCard({
    super.key,
    required this.job,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job saved'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save job'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedJobs = ref.watch(jobInteractionProvider);
    final isSaved = savedJobs.contains(job.url);

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isSaved ? 'Saved' : 'Save job',
                  onPressed: isSaved || isSaving
                      ? null
                      : saveJob,
                  icon: isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isSaved
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              job.company,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(job.location),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: (job.score / 100).clamp(0.0, 1.0),
                minHeight: 10,
                color: matchColor,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              '${job.score.toStringAsFixed(0)}% Match',
              style: TextStyle(
                color: matchColor,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            Text(job.whyMatch),

            if (job.missingSkills.isNotEmpty) ...[
              const SizedBox(height: 18),

              const Text(
                'Missing skills',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.missingSkills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSaved || isSaving
                        ? null
                        : saveJob,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                    label: Text(
                      isSaved ? 'Saved' : 'Save',
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JobDetailsScreen(
                            job: job,
                          ),
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