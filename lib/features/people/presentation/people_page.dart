import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/features/people/application/people_balances_provider.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/people/domain/person.dart';
import 'package:money_manager/features/people/data/people_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/core/widgets/custom_refresh_indicator.dart';

class PeoplePage extends ConsumerWidget {
  const PeoplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(peopleBalancesProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People & Debts'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(peopleBalancesProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () => _showAddPersonDialog(context, ref),
        child: const Icon(Icons.person_add),
      ),
      body: CustomRefreshIndicator(
        onRefresh: () async {
          ref.invalidate(peopleBalancesProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: balancesAsync.when(
          data: (people) {
          if (people.isEmpty) {
            return const Center(
              child: Text('No people added yet.\nSplit a transaction or add a settlement to see balances.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            );
          }

          double totalOwedToMe = 0;
          double totalIOwe = 0;
          for (var p in people) {
            if (p.balance > 0) totalOwedToMe += p.balance;
            if (p.balance < 0) totalIOwe += p.balance.abs();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Gap(16),
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.green.withValues(alpha: 0.1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('Owed to me', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            const Gap(8),
                            Text('$currency${totalOwedToMe.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Card(
                      color: Colors.red.withValues(alpha: 0.1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text('I Owe', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            const Gap(8),
                            Text('$currency${totalIOwe.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(24),
              const Text('Friends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Gap(16),
              ...people.map((p) => _PersonTile(personBalance: p, currency: currency)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      )),
    );
  }

  Future<void> _showAddPersonDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Friend'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final person = Person()..name = name;
                await ref.read(peopleRepositoryProvider).addPerson(person);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final PersonWithBalance personBalance;
  final String currency;

  const _PersonTile({required this.personBalance, required this.currency});

  @override
  Widget build(BuildContext context) {
    final balance = personBalance.balance;
    final color = balance == 0 ? Colors.grey : (balance > 0 ? Colors.green : Colors.red);
    final statusText = balance == 0 ? 'Settled Up' : (balance > 0 ? 'Owes you' : 'You owe');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onTap: () => context.push('/person-details/${personBalance.person.id}', extra: personBalance.person),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          child: Text(personBalance.person.name.isNotEmpty ? personBalance.person.name[0].toUpperCase() : '?'),
        ),
        title: Text(personBalance.person.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(statusText, style: TextStyle(color: color, fontSize: 12)),
            Text(
              '$currency${balance.abs().toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
