import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/url_launcher_utils.dart';
import '../../../features/billing/screens/analytics_paywall_screen.dart';
import '../../../models/application.dart';
import '../../../models/job.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/account_provider.dart';
import '../../../providers/job_details_provider.dart';
import '../widgets/job_comment_section.dart';

enum _JobDecision { yes, no }

class JobDetailsScreen extends ConsumerStatefulWidget {
  final Job job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  bool _isOpening = false;
  bool _isSubmittingDecision = false;
  bool _didOpenVacancy = false;
  bool _isEditingDecision = false;
  _JobDecision? _localDecision;

  bool _isLoadingCoverLetter = false;
  bool _isLoadingTailoredResume = false;

  String? _coverLetterError;
  String? _tailoredResumeError;

  bool _coverLetterRequested = false;
  bool _tailoredResumeRequested = false;

  String? _generatedCoverLetter;
  String? _generatedTailoredResume;

  Future<void> _loadCoverLetter() async {
    setState(() {
      _coverLetterRequested = true;
      _isLoadingCoverLetter = true;
      _coverLetterError = null;
    });

    try {
      final api = ref.read(jobDetailsApiProvider);
      final coverLetter = await api.fetchCoverLetter(widget.job);

      if (!mounted) {
        return;
      }

      setState(() {
        _generatedCoverLetter = coverLetter;
        _isLoadingCoverLetter = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingCoverLetter = false;
        _coverLetterError = context.tr('failed_generate_cover_letter');
      });
    }
  }

  Future<void> _loadTailoredResume() async {
    setState(() {
      _tailoredResumeRequested = true;
      _isLoadingTailoredResume = true;
      _tailoredResumeError = null;
    });

    try {
      final api = ref.read(jobDetailsApiProvider);
      final resume = await api.fetchTailoredResume(widget.job);

      if (!mounted) {
        return;
      }

      setState(() {
        _generatedTailoredResume = resume;
        _isLoadingTailoredResume = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoadingTailoredResume = false;
        _tailoredResumeError = context.tr('failed_generate_resume');
      });
    }
  }

  Future<void> _openVacancy({required bool markOpened}) async {
    if (_isOpening) {
      return;
    }

    setState(() {
      _isOpening = true;
    });

    final opened = await openExternalUrl(widget.job.url);

    if (!mounted) {
      return;
    }

    setState(() {
      _isOpening = false;
      if (opened && markOpened) {
        _didOpenVacancy = true;
      }
    });

    if (!opened) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('failed_open'))));
    }
  }

  Application? _findMatchingApplication(List<Application> applications) {
    for (final application in applications) {
      if (application.hasStableIdentity && widget.job.hasStableIdentity) {
        if (application.stableJobKey == widget.job.stableKey) {
          return application;
        }
        continue;
      }

      if (application.normalizedJobUrl.isNotEmpty &&
          application.normalizedJobUrl == widget.job.normalizedUrl) {
        return application;
      }

      if (application.identityFingerprint == widget.job.identityFingerprint &&
          (!application.hasStableIdentity || !widget.job.hasStableIdentity)) {
        return application;
      }
    }

    return null;
  }

  Future<void> _setDecision(
    _JobDecision decision,
    Application? existingApplication,
  ) async {
    if (_isSubmittingDecision) {
      return;
    }

    setState(() {
      _isSubmittingDecision = true;
    });

    var success = true;

    if (decision == _JobDecision.yes) {
      if (existingApplication == null) {
        final hasAnalyticsAccess =
            ref.read(currentUserProvider).value?.hasAnalyticsAccess ?? false;

        if (!hasAnalyticsAccess) {
          setState(() {
            _isSubmittingDecision = false;
          });
          await Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const AnalyticsPaywallScreen()),
          );
          return;
        }

        success = await ref
            .read(applicationProvider.notifier)
            .apply(widget.job);
      }
    } else if (existingApplication != null) {
      success = await ref
          .read(applicationProvider.notifier)
          .archive(existingApplication.id);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmittingDecision = false;
      if (success) {
        _localDecision = decision;
        _isEditingDecision = false;
      }
    });

    if (!success) {
      final message = decision == _JobDecision.yes
          ? context.tr('failed_application')
          : context.tr('failed_archive_application');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAnalyticsAccess =
        ref.watch(currentUserProvider).value?.hasAnalyticsAccess ?? false;
    final applicationsAsync = hasAnalyticsAccess
        ? ref.watch(applicationProvider)
        : const AsyncData<List<Application>>([]);
    final matchAsync = widget.job.score > 0
        ? AsyncValue.data(widget.job.score.round().clamp(0, 100))
        : ref.watch(jobMatchProvider(widget.job));

    final currentApplications = applicationsAsync.maybeWhen(
      data: (applications) => applications,
      orElse: () => const <Application>[],
    );
    final existingApplication = _findMatchingApplication(currentApplications);
    final effectiveDecision =
        _localDecision ??
        (existingApplication != null ? _JobDecision.yes : null);
    final shouldShowQuestion = _didOpenVacancy || effectiveDecision != null;
    final showPrimaryOpenButton = !_didOpenVacancy && effectiveDecision == null;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('vacancy'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.job.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(widget.job.company, style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.job.location)),
            ],
          ),
          const SizedBox(height: 20),
          _DetailCard(
            child: matchAsync.when(
              loading: () => Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(context.tr('loading_match')),
                ],
              ),
              error: (error, stackTrace) => _InlineError(
                message: context.tr('failed_load_match'),
                actionLabel: context.tr('retry'),
                onPressed: () {
                  ref.invalidate(jobMatchProvider(widget.job));
                },
              ),
              data: (score) {
                final normalizedScore = score.clamp(0, 100).toDouble();
                final color = _matchColor(normalizedScore);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${normalizedScore.round()}% ${context.tr('match')}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: normalizedScore / 100,
                        minHeight: 7,
                        color: color,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (showPrimaryOpenButton)
            FilledButton.icon(
              onPressed: _isOpening
                  ? null
                  : () => _openVacancy(markOpened: true),
              icon: _isOpening
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.open_in_new),
              label: Text(
                _isOpening
                    ? context.tr('opening_vacancy')
                    : context.tr('open_vacancy_first'),
              ),
            ),
          if (!showPrimaryOpenButton) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _isOpening
                  ? null
                  : () => _openVacancy(markOpened: false),
              icon: const Icon(Icons.open_in_new),
              label: Text(context.tr('open_again')),
            ),
          ],
          if (shouldShowQuestion) ...[
            const SizedBox(height: 16),
            _DetailCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('did_you_apply_question'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (effectiveDecision == null || _isEditingDecision)
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _isSubmittingDecision
                                ? null
                                : () => _setDecision(
                                    _JobDecision.yes,
                                    existingApplication,
                                  ),
                            child: Text(context.tr('yes')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmittingDecision
                                ? null
                                : () => _setDecision(
                                    _JobDecision.no,
                                    existingApplication,
                                  ),
                            child: Text(context.tr('no')),
                          ),
                        ),
                      ],
                    ),
                  if (effectiveDecision != null) ...[
                    if (effectiveDecision == _JobDecision.yes &&
                        !_isEditingDecision)
                      _DecisionSummary(
                        icon: Icons.check_circle_outline,
                        text: context.tr('application_yes_status'),
                      ),
                    if (effectiveDecision == _JobDecision.no &&
                        !_isEditingDecision)
                      _DecisionSummary(
                        icon: Icons.remove_circle_outline,
                        text: context.tr('application_no_status'),
                      ),
                    if (!_isEditingDecision) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _isSubmittingDecision
                            ? null
                            : () {
                                setState(() {
                                  _isEditingDecision = true;
                                });
                              },
                        child: Text(context.tr('change_decision')),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SectionCard(
            title: context.tr('comment'),
            child: _buildCommentContent(context),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: context.tr('short_cover_letter'),
            child: _buildCoverLetterContent(context),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: context.tr('tailored_resume'),
            child: _buildTailoredResumeContent(context),
          ),
        ],
      ),
    );
  }

  Color _matchColor(double score) {
    if (score >= 85) {
      return Colors.green;
    }
    if (score >= 70) {
      return Colors.blue;
    }
    if (score >= 50) {
      return Colors.orange;
    }
    return Colors.red;
  }

  Widget _buildCommentContent(BuildContext context) {
    if (widget.job.hasStableIdentity) {
      return JobCommentSection(
        jobSource: widget.job.source,
        jobExternalId: widget.job.externalId,
      );
    }

    return Text(context.tr('comment_unavailable'));
  }

  Widget _buildCoverLetterContent(BuildContext context) {
    if (!_coverLetterRequested) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          onPressed: _loadCoverLetter,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text(context.tr('generate_cover_letter')),
        ),
      );
    }

    if (_isLoadingCoverLetter) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_coverLetterError != null) {
      return _InlineError(
        message: _coverLetterError!,
        actionLabel: context.tr('retry'),
        onPressed: () {
          _loadCoverLetter();
        },
      );
    }

    final coverLetter = (_generatedCoverLetter ?? '').trim();

    if (coverLetter.isEmpty) {
      return Text(context.tr('cover_letter_unavailable'));
    }

    return SelectableText(coverLetter);
  }

  Widget _buildTailoredResumeContent(BuildContext context) {
    if (!_tailoredResumeRequested) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('tailored_resume_description')),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _loadTailoredResume,
            icon: const Icon(Icons.description_outlined),
            label: Text(context.tr('generate_resume')),
          ),
        ],
      );
    }

    if (_isLoadingTailoredResume) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tailoredResumeError != null) {
      return _InlineError(
        message: _tailoredResumeError!,
        actionLabel: context.tr('retry'),
        onPressed: () {
          _loadTailoredResume();
        },
      );
    }

    final resume = (_generatedTailoredResume ?? '').trim();

    if (resume.isEmpty) {
      return Text(context.tr('resume_generation_unavailable'));
    }

    return SelectableText(resume);
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;

  const _DetailCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _InlineError({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.error_outline,
          size: 18,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}

class _DecisionSummary extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DecisionSummary({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
