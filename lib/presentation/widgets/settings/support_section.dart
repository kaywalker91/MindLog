import 'package:flutter/material.dart';
import '../help_dialog.dart';
import 'settings_card.dart';
import 'settings_item.dart';
import 'settings_utils.dart';

/// 지원 섹션
class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsSectionHeader(title: '지원'),
        SettingsCard(
          children: [
            SettingsItem(
              icon: Icons.help_outline,
              title: '도움말',
              onTap: () => _showHelpDialog(context),
            ),
            const SettingsDivider(),
            SettingsItem(
              icon: Icons.email_outlined,
              title: '문의하기',
              onTap: () =>
                  launchExternalUrl('mailto:rikygak@gmail.com', context),
            ),
          ],
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const HelpDialog());
  }
}
