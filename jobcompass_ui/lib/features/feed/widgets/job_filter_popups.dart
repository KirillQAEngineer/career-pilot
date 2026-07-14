import 'package:flutter/material.dart';

import 'package:jobcompass_ui/features/feed/models/job_filters.dart';
import 'package:jobcompass_ui/core/localization/app_localizations.dart';

Future<Set<String>?> showWorkFormatFilterPopup({
  required BuildContext context,
  required Offset position,
  required Set<String> currentValues,
  required List<String> values,
}) {
  final selectedValues = <String>{...currentValues};

  return showMenu<Set<String>>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: [
      PopupMenuItem<Set<String>>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: StatefulBuilder(
          builder: (context, setPopupState) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: values.map((value) {
                    final isSelected = selectedValues.contains(value);

                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(value),
                      value: isSelected,
                      onChanged: (selected) {
                        setPopupState(() {
                          if (selected ?? false) {
                            selectedValues.add(value);
                          } else {
                            selectedValues.remove(value);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
      PopupMenuItem<Set<String>>(
        value: selectedValues,
        child: Center(child: Text(context.tr('apply'))),
      ),
    ],
  );
}

Future<PublicationDateFilter?> showPublicationDateFilterPopup({
  required BuildContext context,
  required Offset position,
  required PublicationDateFilter currentValue,
}) {
  return showMenu<PublicationDateFilter>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      position.dx,
      position.dy,
    ),
    items: [
      _publicationDateItem(
        context: context,
        value: PublicationDateFilter.last24Hours,
        currentValue: currentValue,
      ),
      _publicationDateItem(
        context: context,
        value: PublicationDateFilter.last7Days,
        currentValue: currentValue,
      ),
      _publicationDateItem(
        context: context,
        value: PublicationDateFilter.last30Days,
        currentValue: currentValue,
      ),
    ],
  );
}

CheckedPopupMenuItem<PublicationDateFilter> _publicationDateItem({
  required BuildContext context,
  required PublicationDateFilter value,
  required PublicationDateFilter currentValue,
}) {
  return CheckedPopupMenuItem<PublicationDateFilter>(
    value: value,
    checked: currentValue == value,
    child: Text(publicationDateLabel(value, context)),
  );
}

String publicationDateLabel(
  PublicationDateFilter value, [
  BuildContext? context,
]) {
  return switch (value) {
    PublicationDateFilter.anyTime =>
      context?.tr('publication_date') ?? 'Publication date',
    PublicationDateFilter.last24Hours =>
      context?.tr('last_24_hours') ?? 'Last 24 hours',
    PublicationDateFilter.last7Days =>
      context?.tr('last_7_days') ?? 'Last 7 days',
    PublicationDateFilter.last30Days =>
      context?.tr('last_30_days') ?? 'Last 30 days',
  };
}
