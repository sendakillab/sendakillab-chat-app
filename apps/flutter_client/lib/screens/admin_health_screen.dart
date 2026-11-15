import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

class AdminHealthScreen extends StatefulWidget {
  const AdminHealthScreen({super.key});

  @override
  State<AdminHealthScreen> createState() => _AdminHealthScreenState();
}

class _AdminHealthScreenState extends State<AdminHealthScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _health;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.health();
      if (!mounted) return;
      setState(() => _health = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthy = _error == null && _health != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin / Health',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Runtime status for the local SendakilLab stack.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _loading ? null : _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _StatusCard(
                    title: 'FastAPI',
                    value: _loading
                        ? 'Checking…'
                        : healthy
                            ? 'Healthy'
                            : 'Unavailable',
                    icon: Icons.api_rounded,
                    ok: healthy,
                  ),
                  const _StatusCard(
                    title: 'Frontend',
                    value: 'Running',
                    icon: Icons.web_asset_rounded,
                    ok: true,
                  ),
                  _StatusCard(
                    title: 'API URL',
                    value: AppConfig.apiBaseUrl,
                    icon: Icons.link_rounded,
                    ok: healthy,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFFB64040)),
                          )
                        : SelectableText(
                            const JsonEncoder.withIndent('  ').convert(_health),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              color: AppColors.textPrimary,
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.ok,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.paleBlue,
            child: Icon(icon, color: AppColors.blue),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: ok ? AppColors.teal : const Color(0xFFB64040),
          ),
        ],
      ),
    );
  }
}
