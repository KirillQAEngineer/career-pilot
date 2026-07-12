import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/url_launcher_utils.dart';
import '../../../models/job.dart';
import '../../../providers/application_provider.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final Job job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  ConsumerState<JobDetailsScreen> createState() {
    return _JobDetailsScreenState();
  }
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  bool _isApplying = false;

  Future<void> _apply() async {
    if (_isApplying) {
      return;
    }

    setState(() {
      _isApplying = true;
    });

    final success = await ref
        .read(applicationProvider.notifier)
        .apply(widget.job);

    if (!mounted) {
      return;
    }

    setState(() {
      _isApplying = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save application')),
      );

      return;
    }

    final opened = await openExternalUrl(widget.job.url);

    if (!mounted) {
      return;
    }

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Application saved, but the vacancy could not be opened',
          ),
        ),
      );
    }
  }

  Future<void> _openVacancy() async {
    final opened = await openExternalUrl(widget.job.url);

    if (!mounted) {
      return;
    }

    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to open vacancy')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final applicationsAsync = ref.watch(applicationProvider);

    final isApplied = applicationsAsync.maybeWhen(
      data: (applications) {
        return applications.any(
          (application) => application.stableJobKey == job.stableKey,
        );
      },
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Vacancy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            job.title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(job.company, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 8),
              Expanded(child: Text(job.location)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${job.score.toStringAsFixed(0)}% Match',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: job.score / 100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 28),
          const Text(
            'Why this matches',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(job.whyMatch),
          if (job.missingSkills.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Missing skills',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.missingSkills
                  .map((skill) => Chip(label: Text(skill)))
                  .toList(),
            ),
          ],
          const SizedBox(height: 36),
          FilledButton.icon(
            onPressed: _isApplying || isApplied ? null : _apply,
            icon: _isApplying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isApplied ? Icons.check : Icons.send_outlined),
            label: Text(
              _isApplying
                  ? 'Applying...'
                  : isApplied
                  ? 'Applied'
                  : 'Apply',
            ),
          ),
          if (isApplied) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openVacancy,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Vacancy Again'),
            ),
          ],
        ],
      ),
    );
  }
}
