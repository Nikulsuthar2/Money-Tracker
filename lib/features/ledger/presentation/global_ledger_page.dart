import 'package:flutter/material.dart';
import 'dart:io';
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
        actions: [
           if (!Platform.isAndroid)
             IconButton(icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(allLedgerEntriesProvider)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
           ref.invalidate(allLedgerEntriesProvider);
           await Future.delayed(const Duration(milliseconds: 300));
        },
        child: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No ledger entries yet'));
          }
          // Using a Local State for Reordering visually before saving?
          // Actually, ReorderableListView requires a StatefulWidget or a way to update the list locally.
          // Since data comes from a Stream, updating Isar will trigger a refresh.
          // But optimal UX updates UI immediately.
          // For simplicity in this agentic context: We Update Isar, which updates Stream.
          // Isar update might be slightly laggy visually, but robust.
          
          return ReorderableListView.builder(
            itemCount: entries.length,
            onReorder: (oldIndex, newIndex) {
               if (oldIndex < newIndex) {
                 newIndex -= 1;
               }
               final item = entries.removeAt(oldIndex);
               entries.insert(newIndex, item);
               
               // Update Sort Orders
               // We assign simple indices as sort orders for the whole list
               // or just update affected. Re-indexing whole list is safest.
               for (int i = 0; i < entries.length; i++) {
                  entries[i].sortOrder = i.toDouble();
               }
               
               // Save to DB
               ref.read(ledgerServiceProvider).updateLedgerEntries(entries);
            },
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                 key: ValueKey(entry.id), // Important for ReorderableListView
                 contentPadding: EdgeInsets.zero,
                 title: LedgerEntryCompactTile(entry: entry, currencySymbol: currencySymbol),
                 trailing: ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                 ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      ),
    );
  }
}
