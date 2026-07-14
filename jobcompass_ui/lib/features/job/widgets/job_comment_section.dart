import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jobcompass_ui/models/job_comment.dart';
import 'package:jobcompass_ui/providers/job_comments_provider.dart';
import 'package:jobcompass_ui/core/localization/app_localizations.dart';

class JobCommentSection extends ConsumerStatefulWidget {
  final String jobSource;
  final String jobExternalId;
  final bool compact;

  const JobCommentSection({
    super.key,
    required this.jobSource,
    required this.jobExternalId,
    this.compact = false,
  });

  @override
  ConsumerState<JobCommentSection> createState() => _JobCommentSectionState();
}

class _JobCommentSectionState extends ConsumerState<JobCommentSection> {
  bool _isSaving = false;

  String get _stableKey =>
      JobComment.buildStableKey(widget.jobSource, widget.jobExternalId);

  bool get _hasStableIdentity =>
      widget.jobSource.trim().isNotEmpty &&
      widget.jobExternalId.trim().isNotEmpty;

  Future<void> _editComment(String currentComment) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return _JobCommentDialog(initialComment: currentComment);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final success = await ref
        .read(jobCommentsProvider.notifier)
        .saveComment(
          jobSource: widget.jobSource,
          jobExternalId: widget.jobExternalId,
          comment: result,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    if (!success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('failed_comment'))));

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isEmpty
              ? context.tr('comment_removed')
              : context.tr('comment_saved'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasStableIdentity) {
      return const SizedBox.shrink();
    }

    final commentsAsync = ref.watch(jobCommentsProvider);

    if (widget.compact) {
      return commentsAsync.when(
        loading: () => const _CompactCommentButton(
          comment: '',
          isLoading: true,
          onTap: null,
        ),
        error: (error, stackTrace) => _CompactCommentButton(
          comment: '',
          isError: true,
          onTap: () {
            ref.invalidate(jobCommentsProvider);
          },
        ),
        data: (comments) {
          final comment = comments[_stableKey]?.comment ?? '';

          return _CompactCommentButton(
            key: ValueKey('job-comment-$_stableKey'),
            comment: comment,
            isLoading: _isSaving,
            onTap: _isSaving ? null : () => _editComment(comment),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: commentsAsync.when(
        loading: () =>
            const _CommentTile(comment: '', isLoading: true, onTap: null),
        error: (error, stackTrace) => _CommentTile(
          comment: context.tr('failed_load_comment'),
          isError: true,
          onTap: () {
            ref.invalidate(jobCommentsProvider);
          },
        ),
        data: (comments) {
          final comment = comments[_stableKey]?.comment ?? '';

          return _CommentTile(
            key: ValueKey('job-comment-$_stableKey'),
            comment: comment,
            isLoading: _isSaving,
            onTap: _isSaving ? null : () => _editComment(comment),
          );
        },
      ),
    );
  }
}

class _CompactCommentButton extends StatelessWidget {
  final String comment;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onTap;

  const _CompactCommentButton({
    super.key,
    required this.comment,
    required this.onTap,
    this.isLoading = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasComment = comment.isNotEmpty && !isError;
    final tooltip = isError
        ? context.tr('retry_comment')
        : hasComment
        ? comment
        : context.tr('add_comment');

    return Tooltip(
      message: tooltip,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isError
                    ? Icons.refresh
                    : hasComment
                    ? Icons.comment
                    : Icons.add_comment_outlined,
                color: hasComment
                    ? Theme.of(context).colorScheme.primary
                    : null,
                size: 20,
              ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final String comment;
  final bool isLoading;
  final bool isError;
  final VoidCallback? onTap;

  const _CommentTile({
    super.key,
    required this.comment,
    required this.onTap,
    this.isLoading = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasComment = comment.isNotEmpty && !isError;

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  isError ? Icons.refresh : Icons.comment_outlined,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: hasComment
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('comment'),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            comment,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    : Text(
                        isLoading
                            ? context.tr('loading_comment')
                            : comment.isEmpty
                            ? context.tr('add_comment')
                            : comment,
                      ),
              ),
              if (!isLoading && !isError)
                Icon(hasComment ? Icons.edit_outlined : Icons.add, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobCommentDialog extends StatefulWidget {
  final String initialComment;

  const _JobCommentDialog({required this.initialComment});

  @override
  State<_JobCommentDialog> createState() => _JobCommentDialogState();
}

class _JobCommentDialogState extends State<_JobCommentDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasComment = widget.initialComment.isNotEmpty;

    return AlertDialog(
      key: const ValueKey('job-comment-dialog'),
      title: Text(
        hasComment ? context.tr('edit_comment') : context.tr('add_comment'),
      ),
      content: SizedBox(
        width: 440,
        child: TextField(
          key: const ValueKey('job-comment-field'),
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 7,
          maxLength: 2000,
          decoration: InputDecoration(
            hintText: context.tr('comment_hint'),
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        if (hasComment)
          TextButton(
            key: const ValueKey('job-comment-delete-button'),
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(context.tr('delete')),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          key: const ValueKey('job-comment-save-button'),
          onPressed: () {
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: Text(context.tr('save')),
        ),
      ],
    );
  }
}
