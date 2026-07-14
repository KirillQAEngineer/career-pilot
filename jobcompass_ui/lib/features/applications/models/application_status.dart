import 'package:flutter/widgets.dart';

import '../../../core/localization/app_localizations.dart';

const applicationStatuses = <String>[
  'applied',
  'screening',
  'interview',
  'technical_interview',
  'offer',
  'rejected',
];

String applicationStatusLabel(String status, [BuildContext? context]) {
  final normalizedStatus = status.trim().toLowerCase();

  final key = switch (normalizedStatus) {
    'applied' => 'applied',
    'screening' => 'screening',
    'interview' => 'interview',
    'technical_interview' => 'technical_interview',
    'offer' => 'offer',
    'rejected' => 'rejected',
    _ => null,
  };

  if (key == null) {
    return status.isEmpty ? (context?.tr('applied') ?? 'Applied') : status;
  }

  return context?.tr(key) ??
      switch (key) {
        'applied' => 'Applied',
        'screening' => 'Screening',
        'interview' => 'Interview',
        'technical_interview' => 'Technical Interview',
        'offer' => 'Offer',
        'rejected' => 'Rejected',
        _ => status,
      };
}
