import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/job.dart';

class JobDetailsScreen extends StatelessWidget {
  final Job job;

  const JobDetailsScreen({
    super.key,
    required this.job,
  });

  Future<void> _openVacancy() async {
    final uri = Uri.parse(job.url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception("Could not open vacancy");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vacancy"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            job.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            job.company,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),

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
            "${job.score.toStringAsFixed(0)}% Match",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          LinearProgressIndicator(
            value: job.score / 100,
            minHeight: 10,
            borderRadius: BorderRadius.circular(16),
          ),

          const SizedBox(height: 28),

          const Text(
            "Why this matches",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          Text(job.whyMatch),

          if (job.missingSkills.isNotEmpty) ...[
            const SizedBox(height: 28),

            const Text(
              "Missing skills",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 12),

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

          const SizedBox(height: 36),

          FilledButton.icon(
            onPressed: _openVacancy,
            icon: const Icon(Icons.open_in_new),
            label: const Text("Open Vacancy"),
          ),
        ],
      ),
    );
  }
}