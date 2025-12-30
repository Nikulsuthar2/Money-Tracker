import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/ledger/application/ledger_providers.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/ledger/presentation/widgets/ledger_entry_compact_tile.dart';

class GlobalLedgerPage extends ConsumerWidget {
  const GlobalLedgerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allLedgerEntriesProvider);
    final theme = Theme.of(context);
    final currencySymbol = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Ledger'),
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No ledger entries yet'));
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (c, i) => Divider(height: 1, indent: 16, endIndent: 16, color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return LedgerEntryCompactTile(entry: entry, currencySymbol: currencySymbol);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
