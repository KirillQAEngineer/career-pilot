import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/job.dart';
import '../../../providers/job_details_provider.dart';

class JobMatchScore extends ConsumerWidget {
  final Job job;
  final bool compact;

  const JobMatchScore({super.key, required this.job, this.compact = false});

  Color _matchColor(double score) {
    if (score >= 85) return Colors.green;
    if (score >= 70) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double? fallbackScore = job.score > 0
        ? job.score.clamp(0, 100).toDouble()
        : null;
    final matchAsync = fallbackScore == null
        ? ref.watch(jobMatchProvider(job))
        : null;

    final double? matchValue =
        fallbackScore ??
        matchAsync?.maybeWhen(
          data: (value) => value.toDouble().clamp(0, 100),
          orElse: () => null,
        );

    if (compact) {
      return SizedBox(
        width: 52,
        child: Align(
          alignment: Alignment.centerRight,
          child: _CompactMatchValue(
            score: matchValue,
            color: matchValue == null ? null : _matchColor(matchValue),
          ),
        ),
      );
    }

    return SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CompactMatchValue(
            score: matchValue,
            color: matchValue == null ? null : _matchColor(matchValue),
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ((matchValue ?? 0) / 100).clamp(0.0, 1.0),
              minHeight: 4,
              color: matchValue == null ? null : _matchColor(matchValue),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMatchValue extends StatelessWidget {
  final double? score;
  final Color? color;

  const _CompactMatchValue({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = score == null ? '--%' : '${score!.round()}%';

    return Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }
}
