import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class ModelSettingsScreen extends StatefulWidget {
  const ModelSettingsScreen({super.key});

  @override
  State<ModelSettingsScreen> createState() => _ModelSettingsScreenState();
}

class _ModelSettingsScreenState extends State<ModelSettingsScreen> {
  double _temperature = 0.7;
  double _topP = 0.9;
  int _contextLength = 4096;
  bool _streaming = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Model Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Local UI settings for model generation. Backend wiring follows in a later step.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 26),
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Temperature', _temperature.toStringAsFixed(1)),
                    Slider(
                      value: _temperature,
                      min: 0,
                      max: 2,
                      divisions: 20,
                      onChanged: (v) => setState(() => _temperature = v),
                    ),
                    const Divider(height: 30),
                    _label('Top P', _topP.toStringAsFixed(1)),
                    Slider(
                      value: _topP,
                      min: 0.1,
                      max: 1,
                      divisions: 9,
                      onChanged: (v) => setState(() => _topP = v),
                    ),
                    const Divider(height: 30),
                    DropdownButtonFormField<int>(
                      value: _contextLength,
                      decoration: const InputDecoration(
                        labelText: 'Context length',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 2048, child: Text('2,048')),
                        DropdownMenuItem(value: 4096, child: Text('4,096')),
                        DropdownMenuItem(value: 8192, child: Text('8,192')),
                        DropdownMenuItem(value: 16384, child: Text('16,384')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _contextLength = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Streaming responses'),
                      subtitle:
                          const Text('UI preference; backend streaming comes later.'),
                      value: _streaming,
                      onChanged: (v) => setState(() => _streaming = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String name, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(value, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
