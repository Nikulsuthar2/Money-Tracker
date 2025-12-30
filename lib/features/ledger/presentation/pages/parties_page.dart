import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/ledger/application/party_providers.dart';
import 'package:money_manager/features/ledger/application/ledger_providers.dart';
import 'package:money_manager/features/ledger/domain/party.dart';
import 'package:money_manager/features/ledger/data/party_repository.dart';
import 'package:gap/gap.dart';

class PartiesPage extends ConsumerStatefulWidget {
  const PartiesPage({super.key});

  @override
  ConsumerState<PartiesPage> createState() => _PartiesPageState();
}

class _PartiesPageState extends ConsumerState<PartiesPage> {
  @override
  Widget build(BuildContext context) {
    final partiesAsync = ref.watch(partiesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People & Merchants'),
        actions: [
           IconButton(
             tooltip: 'Global Ledger',
             icon: const Icon(Icons.menu_book), // Changed to book/ledger icon
             onPressed: () => context.push('/global-ledger'),
           ),
           IconButton(
             tooltip: 'New Ledger Entry (V2)',
             icon: const Icon(Icons.receipt_long),
             onPressed: () => context.push('/add-ledger-transaction'),
           ),
        ],
      ),
      body: partiesAsync.when(
        data: (parties) {
          if (parties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                   const Gap(16),
                   const Text('No parties found.'),
                   const Gap(8),
                   FilledButton.tonal(
                     onPressed: () => context.push('/add-party'),
                     child: const Text('Add Person / Merchant'),
                   ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
               ref.invalidate(partiesStreamProvider);
               setState(() {});
               await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              itemCount: parties.length,
              itemBuilder: (context, index) {
                final party = parties[index];
                final isMe = party.isMe();
  
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMe ? Theme.of(context).colorScheme.tertiaryContainer : null,
                    child: Text(party.name.isNotEmpty ? party.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(
                      party.name, 
                      style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)
                  ),
                  subtitle: Text(party.type.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  trailing: isMe 
                    ? const Chip(label: Text('ME')) 
                    : FutureBuilder<double>(
                        future: ref.read(ledgerServiceProvider).getOutstandingBalance(party.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2));
                          
                          final balance = snapshot.data ?? 0.0;
                          if (balance.abs() < 0.01) return const Text('Settled', style: TextStyle(color: Colors.grey));
                          
                          final color = balance > 0 ? Colors.green : Colors.red;
                          final text = balance > 0 ? 'Owes You' : 'You Owe';
                          final amount = balance.abs();
                          
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               Text(text, style: TextStyle(fontSize: 10, color: color)),
                               Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                            ],
                          );
                        }
                    ),
                  onTap: () {
                     context.push('/party-details', extra: party);
                  },
                  onLongPress: isMe ? null : () {
                     _showEditPartyDialog(context, party);
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-party'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showEditPartyDialog(BuildContext context, Party party) async {
    final controller = TextEditingController(text: party.name);
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
             if (controller.text.trim().isNotEmpty) {
                final updated = party..name = controller.text.trim();
                await ref.read(partyRepositoryProvider).updateParty(updated);
                if (context.mounted) Navigator.pop(context);
             }
          }, child: const Text('Save')),
        ],
      )
    );
  }
}
