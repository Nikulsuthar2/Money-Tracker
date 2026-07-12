import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/assets/application/assets_providers.dart';
import 'package:money_manager/features/assets/data/assets_repository.dart';
import 'package:money_manager/features/assets/domain/asset_item.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:gap/gap.dart';
import 'dart:ui';

class AssetsPage extends ConsumerStatefulWidget {
  const AssetsPage({super.key});

  @override
  ConsumerState<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends ConsumerState<AssetsPage> {
  
  void _showAddAssetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
              child: const _AddAssetSheet(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsWithBalanceProvider);
    final assetsAsync = ref.watch(assetsStreamProvider);
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Assets'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddAssetSheet,
              tooltip: 'Add Asset',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Liquid Accounts'),
              Tab(text: 'Static Assets'),
            ],
          ),
        ),
        body: accountsAsync.when(
          data: (accounts) {
            double totalAccounts = 0;
            for (var a in accounts) {
              totalAccounts += a.totalContributionToNetWorth;
            }

            return assetsAsync.when(
              data: (assets) {
                double totalAssets = 0;
                for (var a in assets) {
                  totalAssets += a.value;
                }
                
                final grandTotal = totalAccounts + totalAssets;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        color: theme.colorScheme.primaryContainer,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text('Total Net Worth', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8))),
                              const Gap(8),
                              Text('$currency${grandTotal.toStringAsFixed(2)}', 
                                style: theme.textTheme.displaySmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w900
                                )
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Liquid Accounts Tab
                          accounts.isEmpty
                              ? const Center(child: Text('No accounts found'))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: accounts.length,
                                  itemBuilder: (context, index) {
                                    final acc = accounts[index];
                                    return Card(
                                      elevation: 0,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Color(acc.account.color).withOpacity(0.2),
                                          child: Icon(acc.account.flutterIcon, color: Color(acc.account.color)),
                                        ),
                                        title: Text(acc.account.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(acc.account.type.name),
                                        trailing: Text('$currency${acc.totalContributionToNetWorth.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    );
                                  },
                                ),
                          
                          // Static Assets Tab
                          assets.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                                      const Gap(16),
                                      const Text('No static assets added yet', style: TextStyle(color: Colors.grey)),
                                      const Gap(8),
                                      OutlinedButton(
                                        onPressed: _showAddAssetSheet,
                                        child: const Text('Add First Asset'),
                                      )
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: assets.length,
                                  itemBuilder: (context, index) {
                                    final asset = assets[index];
                                    return Card(
                                      elevation: 0,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Color(asset.color).withOpacity(0.2),
                                          child: Icon(asset.flutterIcon, color: Color(asset.color)),
                                        ),
                                        title: Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(asset.type),
                                        trailing: Text('$currency${asset.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        onLongPress: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Asset?'),
                                              content: Text('Are you sure you want to remove ${asset.name}?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                                TextButton(
                                                  onPressed: () {
                                                    ref.read(assetsRepositoryProvider).deleteAssetItem(asset.id);
                                                    Navigator.pop(ctx);
                                                  },
                                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            )
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e,s) => Center(child: Text('Error: $e')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e,s) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _AddAssetSheet extends ConsumerStatefulWidget {
  const _AddAssetSheet();

  @override
  ConsumerState<_AddAssetSheet> createState() => _AddAssetSheetState();
}

class _AddAssetSheetState extends ConsumerState<_AddAssetSheet> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  String _type = 'Property';
  
  final _types = ['Property', 'Vehicle', 'Jewelry', 'Electronics', 'Other'];
  
  IconData _icon = Icons.house;
  int _color = Colors.amber.value;

  final _colors = [
    Colors.amber, Colors.blue, Colors.red, Colors.green, Colors.purple,
    Colors.orange, Colors.teal, Colors.cyan, Colors.indigo, Colors.brown,
  ];

  final _icons = [
    Icons.house, Icons.apartment, Icons.directions_car, Icons.motorcycle,
    Icons.diamond, Icons.watch, Icons.laptop, Icons.phone_android,
    Icons.inventory_2, Icons.account_balance, Icons.savings, Icons.monetization_on
  ];

  void _save() {
    final name = _nameController.text.trim();
    final valStr = _valueController.text.trim();
    if (name.isEmpty || valStr.isEmpty) return;
    final value = double.tryParse(valStr);
    if (value == null) return;
    
    int code = _icon.codePoint;
    String iconDataStr = 'material:$code';

    final asset = AssetItem(
      name: name,
      type: _type,
      value: value,
      iconData: iconDataStr,
      color: _color,
    );
    
    ref.read(assetsRepositoryProvider).addAssetItem(asset);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Add Static Asset', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Gap(16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Asset Name', border: OutlineInputBorder()),
            textInputAction: TextInputAction.next,
          ),
          const Gap(16),
          TextField(
            controller: _valueController,
            decoration: const InputDecoration(labelText: 'Estimated Value', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const Gap(16),
          DropdownButtonFormField<String>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Asset Type', border: OutlineInputBorder()),
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _type = v);
            },
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                     await showDialog(
                       context: context,
                       builder: (context) => AlertDialog(
                         title: const Text('Select Icon'),
                         content: SingleChildScrollView(
                           child: Wrap(
                             spacing: 12,
                             runSpacing: 12,
                             children: _icons.map((ic) => InkWell(
                               onTap: () {
                                   setState(() => _icon = ic);
                                   Navigator.pop(context);
                               },
                               child: Container(
                                 width: 48,
                                 height: 48,
                                 decoration: BoxDecoration(
                                   color: _icon == ic ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
                                   shape: BoxShape.circle,
                                 ),
                                 child: Icon(ic, color: _icon == ic ? Theme.of(context).colorScheme.primary : null),
                               ),
                             )).toList(),
                           ),
                         ),
                       )
                     );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44, 
                          decoration: BoxDecoration(color: Color(_color).withOpacity(0.2), shape: BoxShape.circle),
                          child: Icon(_icon, color: Color(_color)),
                        ),
                        const Gap(12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Icon', style: TextStyle(fontSize: 12)),
                              Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ]
                          )
                        )
                      ]
                    )
                  )
                )
              ),
              const Gap(16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                     await showDialog(
                       context: context,
                       builder: (context) => AlertDialog(
                         title: const Text('Select Color'),
                         content: SingleChildScrollView(
                           child: Wrap(
                             spacing: 12,
                             runSpacing: 12,
                             children: _colors.map((c) => InkWell(
                               onTap: () {
                                   setState(() => _color = c.value);
                                   Navigator.pop(context);
                               },
                               child: Container(
                                 width: 42,
                                 height: 42,
                                 decoration: BoxDecoration(
                                   color: c,
                                   shape: BoxShape.circle,
                                   border: _color == c.value ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                                 ),
                                 child: _color == c.value ? const Icon(Icons.check, color: Colors.white, size: 24) : null,
                               ),
                             )).toList(),
                           ),
                         ),
                       )
                     );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44, 
                          decoration: BoxDecoration(color: Color(_color), shape: BoxShape.circle)
                        ),
                        const Gap(12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Color', style: TextStyle(fontSize: 12)),
                              Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ]
                          )
                        )
                      ]
                    )
                  )
                )
              ),
            ],
          ),
          const Gap(24),
          FilledButton(
            onPressed: _save,
            child: const Text('Save Asset'),
          )
        ],
      ),
    );
  }
}
