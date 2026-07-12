import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/url_launcher_utils.dart';
import '../../../models/application.dart';
import '../../../providers/application_provider.dart';

class ApplicationHistoryScreen extends ConsumerWidget {
  const ApplicationHistoryScreen({super.key});

  Future<void> _openJob(BuildContext context, Application application) async {
    final opened = await openExternalUrl(application.jobUrl);

    if (!context.mounted) {
      return;
    }

    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to open vacancy')));
    }
  }

  Future<void> _refreshApplications(WidgetRef ref) async {
    await ref.read(applicationProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(applicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: applicationsAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
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
                    onPressed: () {
                      ref.read(applicationProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (applications) {
          if (applications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _refreshApplications(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.send_outlined, size: 64),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No applications yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Jobs you apply to will appear here.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refreshApplications(ref),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];

                return _ApplicationCard(
                  application: application,
                  onOpen: () {
                    _openJob(context, application);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Application application;
  final VoidCallback onOpen;

  const _ApplicationCard({required this.application, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final location = application.jobLocation?.trim() ?? '';
    final workFormat = application.jobWorkFormat?.trim() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              application.jobTitle.isEmpty
                  ? 'Untitled vacancy'
                  : application.jobTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              application.jobCompany.isEmpty
                  ? 'Company not specified'
                  : application.jobCompany,
              style: const TextStyle(fontSize: 16),
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(location)),
                ],
              ),
            ],
            if (workFormat.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.work_outline, size: 18),
                  const SizedBox(width: 6),
                  Text(workFormat),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Text('Applied ${_formatDate(application.createdAt)}'),
              ],
            ),
            const SizedBox(height: 10),
            Chip(label: Text(_statusLabel(application.status))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: application.jobUrl.isEmpty ? null : onOpen,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Vacancy'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    final normalizedStatus = status.trim().toLowerCase();

    return switch (normalizedStatus) {
      'applied' => 'Applied',
      'interview' => 'Interview',
      'offer' => 'Offer',
      'rejected' => 'Rejected',
      _ => status.isEmpty ? 'Applied' : status,
    };
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    return '$day.$month.$year';
  }
}
