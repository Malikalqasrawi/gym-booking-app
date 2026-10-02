import 'package:flutter/material.dart';

/// Asks for a required piece of text, e.g. a reply or a reason. Returns it trimmed, or null when
/// the user backs out.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  required String label,
  required String action,
  required int maxLength,
  String? message,
  String? initialText,
  bool destructive = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: title,
      label: label,
      action: action,
      maxLength: maxLength,
      message: message,
      initialText: initialText,
      destructive: destructive,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.action,
    required this.maxLength,
    required this.message,
    required this.initialText,
    required this.destructive,
  });

  final String title;
  final String label;
  final String action;
  final int maxLength;
  final String? message;
  final String? initialText;
  final bool destructive;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final _controller = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = _controller.text.trim();

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message != null) ...[Text(widget.message!), const SizedBox(height: 12)],
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: widget.maxLength,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: widget.label, border: const OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
        FilledButton(
          onPressed: text.isEmpty ? null : () => Navigator.pop(context, text),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44), // not full-width inside a dialog
            backgroundColor: widget.destructive ? scheme.error : null,
            foregroundColor: widget.destructive ? scheme.onError : null,
          ),
          child: Text(widget.action),
        ),
      ],
    );
  }
}
