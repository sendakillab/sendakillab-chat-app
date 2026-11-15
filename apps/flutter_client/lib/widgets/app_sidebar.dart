import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'brand_mark.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.onNewChat,
    required this.selectedIndex,
    required this.onSelect,
  });

  final VoidCallback onNewChat;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.history_rounded, 'Chat History'),
    (Icons.view_in_ar_rounded, 'Model Library'),
    (Icons.attach_file_rounded, 'Files & Images'),
    (Icons.tune_rounded, 'Model Settings'),
    (Icons.person_outline_rounded, 'Profile'),
    (Icons.monitor_heart_outlined, 'Admin / Health'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 245,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: BrandMark(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onNewChat,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Chat'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _NavItem(
                      icon: _items[i].$1,
                      label: _items[i].$2,
                      selected: selectedIndex == i,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFDCEAF5),
                  child: Text(
                    'S',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Local Developer',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'SendakilLab • Phase 01',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.paleBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.blue : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.navy
                        : AppColors.textPrimary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
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
