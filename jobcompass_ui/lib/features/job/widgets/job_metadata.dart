import 'package:flutter/material.dart';

class JobMetadata extends StatelessWidget {
  final String? location;
  final String? workFormat;
  final DateTime? publishedAt;

  const JobMetadata({
    super.key,
    this.location,
    this.workFormat,
    this.publishedAt,
  });

  bool get _hasLocation {
    return location != null && location!.trim().isNotEmpty;
  }

  bool get _hasWorkFormat {
    return workFormat != null && workFormat!.trim().isNotEmpty;
  }

  bool get _hasPublishedAt {
    return publishedAt != null;
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    if (_hasLocation) {
      items.add(
        _MetadataItem(icon: Icons.location_on_outlined, text: location!.trim()),
      );
    }

    if (_hasWorkFormat) {
      items.add(
        _MetadataItem(
          icon: _workFormatIcon(workFormat!),
          text: workFormat!.trim(),
        ),
      );
    }

    if (_hasPublishedAt) {
      items.add(
        _MetadataItem(
          icon: Icons.calendar_today_outlined,
          text: _formatDate(publishedAt!),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 16, runSpacing: 10, children: items);
  }

  IconData _workFormatIcon(String value) {
    switch (value.trim().toLowerCase()) {
      case 'remote':
        return Icons.home_work_outlined;
      case 'hybrid':
        return Icons.sync_alt;
      case 'onsite':
      case 'on-site':
        return Icons.business_outlined;
      default:
        return Icons.work_outline;
    }
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    return '$day.$month.$year';
  }
}

class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetadataItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
