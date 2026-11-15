import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class MessageComposer extends StatefulWidget {
  const MessageComposer({
    super.key,
    required this.onSend,
    required this.busy,
    required this.enabled,
  });

  final ValueChanged<String> onSend;
  final bool busy;
  final bool enabled;

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.busy || !widget.enabled) return;
    _controller.clear();
    widget.onSend(text);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled && !widget.busy,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: widget.busy ? 'Waiting for the model…' : 'Type a message…',
              prefixIcon: IconButton(
                tooltip: 'Attachments (coming next)',
                onPressed: null,
                icon: const Icon(Icons.attach_file_rounded),
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.all(6),
                child: FilledButton(
                  onPressed: widget.enabled && !widget.busy ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(46, 44),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  child: widget.busy
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
