import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/llm_model.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({
    super.key,
    required this.models,
    required this.selected,
    required this.loading,
    required this.onChanged,
  });

  final List<LlmModel> models;
  final String? selected;
  final bool loading;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 170,
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (models.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('No models found', style: TextStyle(color: Color(0xFF996A11))),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: models.any((m) => m.name == selected) ? selected : models.first.name,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: models
              .map(
                (m) => DropdownMenuItem(
                  value: m.name,
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 18, color: AppColors.blue),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 210),
                        child: Text(m.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
