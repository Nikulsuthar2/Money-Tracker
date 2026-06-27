import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_chart.dart';
import 'package:money_manager/features/accounts/presentation/widgets/holdings_card.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:gap/gap.dart';

class AccountAnalyticsTab extends ConsumerStatefulWidget {
  final Account account;
  final List<Transaction> transactions;

  const AccountAnalyticsTab({
    super.key,
    required this.account,
    required this.transactions,
  });

  @override
  ConsumerState<AccountAnalyticsTab> createState() => _AccountAnalyticsTabState();
}

class _AccountAnalyticsTabState extends ConsumerState<AccountAnalyticsTab> {
  String _period = 'Month'; // Month, Year, All
  DateTime _selectedDate = DateTime.now();

  void _prevPeriod() {
    setState(() {
      if (_period == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
      } else if (_period == 'Year') {
        _selectedDate = DateTime(_selectedDate.year - 1);
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_period == 'Month') {
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
      } else if (_period == 'Year') {
        _selectedDate = DateTime(_selectedDate.year + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);

    List<Transaction> timeFilteredTransactions = widget.transactions;
    if (_period == 'Month') {
      timeFilteredTransactions = widget.transactions.where((t) => t.date.year == _selectedDate.year && t.date.month == _selectedDate.month).toList();
    } else if (_period == 'Year') {
      timeFilteredTransactions = widget.transactions.where((t) => t.date.year == _selectedDate.year).toList();
    }

    String dateLabel = '';
    if (_period == 'Month') dateLabel = DateFormat('MMMM yyyy').format(_selectedDate);
    if (_period == 'Year') dateLabel = DateFormat('yyyy').format(_selectedDate);

    // Calculate dynamic stats
    double totalIn = 0;
    double totalOut = 0;
    double netIn = 0;
    double netSpend = 0;
    for (final t in timeFilteredTransactions) {
      if (t.skipFromStats) continue;
      if (t.type == TransactionType.income && t.toAccountId == widget.account.id) {
        totalIn += t.amount;
        netIn += t.amount;
      }
      if (t.type == TransactionType.expense && t.fromAccountId == widget.account.id) {
        totalOut += t.amount;
        netSpend += t.amount;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Period Selector
        SizedBox(
          width: double.infinity,
          height: 48,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Month', label: Text('Month')),
              ButtonSegment(value: 'Year', label: Text('Year')),
              ButtonSegment(value: 'All', label: Text('All')),
            ],
            selected: {_period},
            showSelectedIcon: false,
            onSelectionChanged: (newSelection) {
              setState(() {
                _period = newSelection.first;
              });
            },
          ),
        ),
        
        if (_period != 'All') ...[
          const Gap(16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _prevPeriod, icon: const Icon(Icons.chevron_left)),
                Text(dateLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                IconButton(onPressed: _nextPeriod, icon: const Icon(Icons.chevron_right)),
              ],
            ),
          ),
        ],
        const Gap(24),

        // Holdings Card
        if (!widget.account.isCash) ...[
          HoldingsCard(account: widget.account),
          const Gap(16),
        ],
        
        // Stats Block
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _StatColumn(label: 'Total In', amount: totalIn, color: Colors.teal, currency: currency)),
                  Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                  Expanded(child: _StatColumn(label: 'Total Out', amount: totalOut, color: Colors.red, currency: currency)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              Row(
                children: [
                  Expanded(child: _StatColumn(label: 'Net Income', amount: netIn, color: Colors.teal, currency: currency, isBold: true)),
                  Container(width: 1, height: 40, color: theme.colorScheme.outlineVariant),
                  Expanded(child: _StatColumn(label: 'Net Spend', amount: netSpend, color: Colors.red, currency: currency, isBold: true)),
                ],
              ),
            ],
          ),
        ),
        const Gap(16),

        // Chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: AccountChart(
            transactions: timeFilteredTransactions,
            accountId: widget.account.id,
            currency: currency,
            period: _period,
            focusedDate: _selectedDate,
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String currency;
  final bool isBold;

  const _StatColumn({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const Gap(4),
        Text(
          '$currency${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
