import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/settings/data/backup_service.dart';
import 'package:money_manager/core/database/isar_service.dart';
import 'package:money_manager/core/theme/theme_provider.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/settings/application/security_provider.dart';
import 'package:money_manager/core/providers/savings_provider.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gap/gap.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // General Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('General', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Categories'),
            subtitle: const Text('Manage your categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/categories'),
          ),
          
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text('Currency'),
            subtitle: Text('Selected: ${ref.watch(currencyProvider)} ${currencyNames[ref.watch(currencyProvider)] ?? ''}'),
            onTap: () {
               showDialog(context: context, builder: (c) => SimpleDialog(
                 title: const Text('Select Currency'),
                 children: supportedCurrencies.map((cur) => SimpleDialogOption(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                   onPressed: () {
                     ref.read(currencyProvider.notifier).setCurrency(cur);
                     Navigator.pop(c);
                   },
                   child: Row(
                     children: [
                       Text(cur, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       const Gap(16),
                       Text(currencyNames[cur] ?? '', style: const TextStyle(fontSize: 16)),
                     ],
                   ),
                 )).toList(),
               ));
            },
          ),

          const Divider(),
          const _AppearanceSelector(),
          const Divider(),

          const _SavingsSection(), 
          const Divider(),
          const _SecuritySection(),
          const Divider(),

          // Data
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Data Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Export Data'),
            subtitle: const Text('Save backup to file'),
            onTap: () async {
              try {
                await BackupService().exportData();
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export initiated. Check Downloads/Documents.')));
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export Failed: $e')));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Data'),
            subtitle: const Text('Restore from backup file'),
            onTap: () async {
               try {
                await BackupService().importData();
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import Successful. Please restart app.')));
                }
              } catch (e) {
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Failed: $e')));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset Data', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(context: context, builder: (c) => AlertDialog(
                title: const Text('Reset All Data?'),
                content: const Text('This will delete ALL accounts, transactions, and categories. This cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                  TextButton(onPressed: () async {
                      await IsarService.clearAll();
                      if (context.mounted) {
                        Navigator.pop(c);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data has been reset.')));
                      }
                  }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ));
            },
            ),
          
          const Divider(),
          // About
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
               final version = snapshot.data?.version ?? '...';
               final buildNumber = snapshot.data?.buildNumber ?? '...';
               return ListTile(
                 leading: const Icon(Icons.info_outline),
                 title: const Text('App Version'),
                 subtitle: Text('v$version ($buildNumber)'),
               );
            },
          ),
           ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source Code'),
            subtitle: const Text('View on GitHub'),
            onTap: () async {
               final url = Uri.parse('https://github.com/Nikulsuthar2/Money-Tracker'); 
               try {
                 if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
                 }
               } catch (e) {
                 if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
               }
            },
          ),
           const ListTile(
            leading: Icon(Icons.person),
            title: Text('Developer'),
            subtitle: Text('Google Antigravity & Nikul Suthar'), 
          ),
        ],
      ),
    );
  }
}

class _AppearanceSelector extends ConsumerWidget {
  const _AppearanceSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final dynamicColor = ref.watch(dynamicColorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('System')),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
            ],
            selected: {themeMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              ref.read(themeModeProvider.notifier).setTheme(newSelection.first);
            },
            showSelectedIcon: false,
          ),
        ),
        const Gap(8),
        SwitchListTile(
          title: const Text('Dynamic Color'),
          subtitle: const Text('Use wallpaper colors'),
          value: dynamicColor,
          onChanged: (v) => ref.read(dynamicColorProvider.notifier).toggle(v),
        ),
      ],
    );
  }
}



class _SavingsSection extends ConsumerWidget {
  const _SavingsSection();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(savingsProvider);
    final notifier = ref.read(savingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Automation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        SwitchListTile(
          title: const Text('Auto-Savings'),
          subtitle: Text(settings.isEnabled 
            ? 'Saving ${settings.percentage.toStringAsFixed(0)}% of income' 
            : 'Automatically save a % of income'),
          value: settings.isEnabled,
          onChanged: (v) {
             if (v) {
               _showConfigDialog(context, ref);
             } else {
               notifier.setEnabled(false);
             }
          },
        ),
        if (settings.isEnabled)
          ListTile(
            title: const Text('Configure Savings'),
            leading: const Icon(Icons.savings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showConfigDialog(context, ref),
          ),
      ],
    );
  }

  void _showConfigDialog(BuildContext context, WidgetRef ref) async {
      final settings = ref.read(savingsProvider);
      final accountsRepo = ref.read(accountsRepositoryProvider);
      final accounts = await accountsRepo.getAllAccounts();
      
      if (context.mounted) {
         showDialog(context: context, builder: (c) => _SavingsConfigDialog(initialSettings: settings, accounts: accounts));
      }
  }
}

class _SavingsConfigDialog extends StatefulWidget {
  final SavingsSettings initialSettings;
  final List<Account> accounts;

  const _SavingsConfigDialog({required this.initialSettings, required this.accounts});

  @override
  State<_SavingsConfigDialog> createState() => _SavingsConfigDialogState();
}

class _SavingsConfigDialogState extends State<_SavingsConfigDialog> {
  late double _percentage;
  int? _accountId;

  @override
  void initState() {
    super.initState();
    _percentage = widget.initialSettings.percentage;
    _accountId = widget.initialSettings.accountId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Auto-Savings Setup'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           const Text('Select percentage of Income to save:'),
           const Gap(16),
           Row(
             children: [
               Expanded(child: Slider(
                 value: _percentage, 
                 min: 1, 
                 max: 50, 
                 divisions: 49,
                 label: '${_percentage.round()}%',
                 onChanged: (v) => setState(() => _percentage = v),
               )),
               Text('${_percentage.round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
             ],
           ),
           const Gap(24),
           DropdownButtonFormField<int>(
             decoration: const InputDecoration(labelText: 'Transfer to Account', border: OutlineInputBorder()),
             value: _accountId,
             items: widget.accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
             onChanged: (v) => setState(() => _accountId = v),
           ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
            if (_accountId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select account')));
              return;
            }
            final ref = ProviderScope.containerOf(context);
            ref.read(savingsProvider.notifier).setPercentage(_percentage);
            ref.read(savingsProvider.notifier).setAccountId(_accountId);
            ref.read(savingsProvider.notifier).setEnabled(true);
            Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    );
  }
}

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(securityProvider);
    final notifier = ref.read(securityProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Security', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        SwitchListTile(
          title: const Text('Biometric Lock'),
          subtitle: const Text('Require optional fingerprint/face to open'),
          value: securityState.isBiometricEnabled,
          onChanged: (v) async {
             try {
               await notifier.toggleBiometric(v);
             } catch (e) {
               if (context.mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
               }
             }
          },
        ),
      ],
    );
  }
}
