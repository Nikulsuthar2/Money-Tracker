import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/features/subscriptions/domain/subscription.dart';
import 'package:money_manager/features/transactions/data/transactions_repository.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/core/providers/currency_provider.dart';

class SubscriptionDetailsPage extends ConsumerWidget {
  final Subscription subscription;

  const SubscriptionDetailsPage({super.key, required this.subscription});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final transactionsAsync = ref.watch(transactionsStreamProvider); // Or specific query

    return Scaffold(
      appBar: AppBar(
        title: Text(subscription.name),
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          final history = _generateHistory(subscription, allTransactions);
          
          final totalPaid = history.where((h) => h.status == _PaymentStatus.paid).length * subscription.amount;
          final lastPayment = history.where((h) => h.status == _PaymentStatus.paid).map((h) => h.date).fold<DateTime?>(null, (prev, curr) => prev == null || curr.isAfter(prev) ? curr : prev);
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
               // Header Card
               Card(
                 elevation: 0,
                 color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                 child: Padding(
                   padding: const EdgeInsets.all(20),
                   child: Column(
                     children: [
                       Text(subscription.name, style: Theme.of(context).textTheme.headlineSmall),
                       const Gap(8),
                       Text('$currency${subscription.amount.toStringAsFixed(2)} / ${subscription.repeat.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                       const Gap(24),
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Paid', style: TextStyle(fontSize: 12)),
                                Text('$currency${totalPaid.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                             Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Last Payment', style: TextStyle(fontSize: 12)),
                                Text(lastPayment != null ? DateFormat.yMMMd().format(lastPayment) : 'Never', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                         ],
                       )
                     ],
                   ),
                 ),
               ),
               const Gap(24),
               const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
               const Gap(8),
               
               ...history.map((h) {
                  Color statusColor;
                  IconData statusIcon;
                  String statusText;

                  switch(h.status) {
                    case _PaymentStatus.paid:
                      statusColor = Colors.green;
                      statusIcon = Icons.check_circle;
                      statusText = 'Paid';
                      break;
                    case _PaymentStatus.missed:
                      statusColor = Colors.red;
                      statusIcon = Icons.error;
                      statusText = 'Missed';
                      break;
                    case _PaymentStatus.due:
                      statusColor = Colors.orange;
                      statusIcon = Icons.schedule;
                      statusText = 'Due';
                      break;
                    case _PaymentStatus.future:
                       statusColor = Colors.grey;
                       statusIcon = Icons.circle_outlined;
                       statusText = 'Upcoming';
                  }

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    child: ListTile(
                       leading: Icon(statusIcon, color: statusColor),
                       title: Text(DateFormat.yMMMd().format(h.date)),
                       subtitle: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12)),
                       trailing: h.status == _PaymentStatus.missed || h.status == _PaymentStatus.due
                         ? FilledButton.tonal(
                             child: const Text('Pay Now'),
                             onPressed: () {
                                 // Pay Logic
                                 final defaults = {
                                    'amount': subscription.amount,
                                    'note': 'Subscription: ${subscription.name}',
                                    'type': TransactionType.expense,
                                    'categoryId': subscription.categoryId,
                                    'accountId': subscription.accountId,
                                    'subscriptionId': subscription.id,
                                 };
                                 context.push('/add-transaction', extra: defaults);
                             },
                           )
                         : null,
                    ),
                  );
               }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  List<_HistoryItem> _generateHistory(Subscription s, List<Transaction> allTransactions) {
      final items = <_HistoryItem>[];
      
      // Get transactions linked to this subscription
      final linkedTxs = allTransactions.where((t) => t.subscriptionId == s.id).toList();
      
      // Determine range: StartDate -> Today + 6 Months (Projection)
      // Limit past to maybe 2 years or start date
      
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      DateTime current = s.startDate;
      final limit = todayDate.add(const Duration(days: 180)); // 6 months future
      
      // Safety break
      int loops = 0;
      
      while (current.isBefore(limit) && loops < 500) {
         _PaymentStatus status;
         
         // 1. Check if ANY transaction matches this specific date (approx match?)
         // Ideally subscription matches are loose on date? OR strict?
         // If we use 'Pay Now' it sets the date.
         // Let's check if there is a transaction roughly in the same period?
         // Simpler: Check if there is a linked transaction with close date (+/- 3 days for daily? Month matches for monthly?)
         
         final match = linkedTxs.where((t) => _isMatch(s.repeat, current, t.date));
         
         if (match.isNotEmpty) {
            status = _PaymentStatus.paid;
         } else {
            if (current.isBefore(todayDate)) {
               status = _PaymentStatus.missed;
            } else if (current.isAtSameMomentAs(todayDate)) {
               status = _PaymentStatus.due;
            } else {
               status = _PaymentStatus.future;
            }
         }
         
         items.add(_HistoryItem(current, status));

         current = _calculateNextDate(current, s.repeat);
         loops++;
      }
      
      // Reverse order (newest first)
      return items.reversed.toList();
  }

  bool _isMatch(SubscriptionRepeat repeat, DateTime expected, DateTime actual) {
      // Logic to determine if a transaction belongs to this expected date
      // Monthly: Same Month & Year?
      // Daily: Same Day?
      // Weekly: Same Week?
      
      final d1 = DateTime(expected.year, expected.month, expected.day);
      final d2 = DateTime(actual.year, actual.month, actual.day);
      
      if (repeat == SubscriptionRepeat.daily) {
         return d1.isAtSameMomentAs(d2);
      } else if (repeat == SubscriptionRepeat.monthly) {
         return d1.year == d2.year && d1.month == d2.month;
      } else if (repeat == SubscriptionRepeat.yearly) {
         return d1.year == d2.year;
      } else if (repeat == SubscriptionRepeat.weekly) {
          final diff = d1.difference(d2).inDays.abs();
          return diff < 4; // Within 3 days
      }
      return false;
  }

   DateTime _calculateNextDate(DateTime current, SubscriptionRepeat repeat) {
    switch (repeat) {
      case SubscriptionRepeat.daily: return current.add(const Duration(days: 1));
      case SubscriptionRepeat.weekly: return current.add(const Duration(days: 7));
      case SubscriptionRepeat.monthly: return DateTime(current.year, current.month + 1, current.day);
      case SubscriptionRepeat.yearly: return DateTime(current.year + 1, current.month, current.day);
    }
  }
}

enum _PaymentStatus { paid, missed, due, future }

class _HistoryItem {
  final DateTime date;
  final _PaymentStatus status;
  _HistoryItem(this.date, this.status);
}
