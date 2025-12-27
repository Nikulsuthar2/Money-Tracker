import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:money_manager/core/database/isar_service.dart';
import 'package:money_manager/features/subscriptions/domain/subscription.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/data/accounts_repository.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/categories/application/categories_providers.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

// Repository for Subscriptions (inline for now or separate file)
// Repository for Subscriptions (inline for now or separate file)
class SubscriptionsRepository {
  final Isar isar;
  SubscriptionsRepository(this.isar);

  Stream<List<Subscription>> watchSubscriptions() {
    return isar.subscriptions.where().watch(fireImmediately: true);
  }

  Future<void> addSubscription(Subscription subscription) async {
    await isar.writeTxn(() async {
      await isar.subscriptions.put(subscription);
    });
  }
  
  Future<void> updateSubscription(Subscription subscription) async {
    await isar.writeTxn(() async {
      await isar.subscriptions.put(subscription);
    });
  }

  Future<void> deleteSubscription(Id id) async {
    await isar.writeTxn(() async {
      await isar.subscriptions.delete(id);
    });
  }
}

final subscriptionsRepositoryProvider = Provider((ref) => SubscriptionsRepository(IsarService.isar));

final subscriptionsStreamProvider = StreamProvider((ref) {
  return ref.watch(subscriptionsRepositoryProvider).watchSubscriptions();
});


class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(subscriptionsStreamProvider);
    final currency = ref.watch(currencyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: subsAsync.when(
        data: (subs) {
          if (subs.isEmpty) return const Center(child: Text('No subscriptions'));
          return ListView.separated(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 80),
            itemCount: subs.length,
            separatorBuilder: (_,__) => const Gap(8),
            itemBuilder: (context, index) {
               final s = subs[index];
               return Card(
                 child: ListTile(
                   onTap: () {
                      showDialog(context: context, builder: (c) => AddSubscriptionDialog(subscriptionToEdit: s));
                   },
                   title: Text(s.name),
                   subtitle: Text('${s.repeat.name} • Next: ${DateFormat.yMMMd().format(s.startDate)}'), // Simple logic
                   trailing: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text('$currency${s.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                       PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const Row(children: [Icon(Icons.payment, color: Colors.green), Gap(8), Text('Pay Now')]),
                            onTap: () {
                              // Pay Logic
                              if (s.accountId != null && s.categoryId != null) {
                                 // Auto-create
                                 // We need access to TransactionsRepository here. 
                                 // Ideally we should use a provider method, but for now we can navigate to AddTransaction
                                 // with pre-filled values for review. This is safer.
                                 context.push('/add-transaction', extra: Transaction()
                                    ..amount = s.amount
                                    ..note = 'Subscription: ${s.name}'
                                    ..type = TransactionType.expense
                                    ..categoryId = s.categoryId
                                    ..fromAccountId = s.accountId
                                    ..date = DateTime.now()
                                 );
                              } else {
                                 // Navigate to Add Transaction with available info
                                 context.push('/add-transaction', extra: Transaction()
                                    ..amount = s.amount
                                    ..note = 'Subscription: ${s.name}'
                                    ..type = TransactionType.expense
                                    ..date = DateTime.now()
                                 );
                              }
                            },
                          ),
                          PopupMenuItem(
                            child: const Row(children: [Icon(Icons.edit), Gap(8), Text('Edit')]),
                            onTap: () => showDialog(context: context, builder: (c) => AddSubscriptionDialog(subscriptionToEdit: s)),
                          ),
                          PopupMenuItem(
                            child: const Row(children: [Icon(Icons.delete, color: Colors.red), Gap(8), Text('Delete')]),

                            onTap: () {
                               Future.delayed(Duration.zero, () {
                                 if (context.mounted) {
                                   showDialog(context: context, builder: (d) => AlertDialog(
                                      title: const Text('Delete Subscription?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
                                        TextButton(onPressed: () async {
                                            await ref.read(subscriptionsRepositoryProvider).deleteSubscription(s.id);
                                            if (context.mounted) Navigator.pop(d);
                                        }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                      ],
                                    ));
                                 }
                               });
                            },
                          ),
                        ],
                      ),
                     ],
                   ),
                 ),
               );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add Subscription Dialog or Page
          showDialog(context: context, builder: (c) => const AddSubscriptionDialog());
        },
        icon: const Icon(Icons.playlist_add),
        label: const Text('New Subscription'),
      ),
    );
  }
}

class AddSubscriptionDialog extends ConsumerStatefulWidget {
  const AddSubscriptionDialog({super.key, this.subscriptionToEdit});
  final Subscription? subscriptionToEdit;

  @override
  ConsumerState<AddSubscriptionDialog> createState() => _AddSubscriptionDialogState();
}

class _AddSubscriptionDialogState extends ConsumerState<AddSubscriptionDialog> {
   final _nameController = TextEditingController();
   final _amountController = TextEditingController();
   SubscriptionRepeat _repeat = SubscriptionRepeat.monthly;
   DateTime _startDate = DateTime.now();
   int? _accountId;
   int? _categoryId;

   @override
  void initState() {
    super.initState();
    if (widget.subscriptionToEdit != null) {
      final s = widget.subscriptionToEdit!;
      _nameController.text = s.name;
      _amountController.text = s.amount.toString();
      _repeat = s.repeat;
      _startDate = s.startDate;
      _accountId = s.accountId;
      _categoryId = s.categoryId;
    }
  }

   @override
   Widget build(BuildContext context) {
      final accountsAsync = ref.watch(accountsRepositoryProvider).watchActiveAccounts();
      final categoriesAsync = ref.watch(categoriesStreamProvider);

      return AlertDialog(
        title: Text(widget.subscriptionToEdit == null ? 'Add Subscription' : 'Edit Subscription'),
        content: SingleChildScrollView(
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const Gap(8),
                TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const Gap(16),
                DropdownButtonFormField<SubscriptionRepeat>(
                   initialValue: _repeat,
                   decoration: const InputDecoration(labelText: 'Repeat', border: OutlineInputBorder()),
                   items: SubscriptionRepeat.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                   onChanged: (v) => setState(() => _repeat = v!),
                ),
                const Gap(16),
                // Account Selection
                StreamBuilder<List<Account>>(
                  stream: accountsAsync, 
                  builder: (context, snapshot) {
                    final accounts = snapshot.data ?? [];
                    return DropdownButtonFormField<int>(
                      initialValue: _accountId,
                      decoration: const InputDecoration(labelText: 'Pay From (Account)', border: OutlineInputBorder()),
                      items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                      onChanged: (v) => setState(() => _accountId = v),
                    );
                  }
                ),
                const Gap(16),
                // Category Selection
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<int>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_,__) => const SizedBox(),
                ),
                const Gap(16),
                ListTile(
                  title: Text('Start Date: ${DateFormat.yMMMd().format(_startDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                     final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                     if(d!=null) setState(() => _startDate = d);
                  },
                )
             ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
               final name = _nameController.text;
               final amount = double.tryParse(_amountController.text) ?? 0;
               if (name.isNotEmpty && amount > 0) {
                 final sub = widget.subscriptionToEdit ?? Subscription();
                 sub
                   ..name = name
                   ..amount = amount
                   ..repeat = _repeat
                   ..startDate = _startDate
                   ..accountId = _accountId
                   ..categoryId = _categoryId
                   ..isActive = true;
                 
                 if (widget.subscriptionToEdit != null) {
                    await ref.read(subscriptionsRepositoryProvider).updateSubscription(sub);
                 } else {
                    await ref.read(subscriptionsRepositoryProvider).addSubscription(sub);
                 }
                 
                 if (mounted) context.pop();
               }
            },
            child: const Text('Save'),
          ),
        ],
      );
   }
}
