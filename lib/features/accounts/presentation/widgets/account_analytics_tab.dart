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

  void _showPeriodSelectorSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Select Period', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Month'),
              onTap: () {
                setState(() => _period = 'Month');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Year'),
              onTap: () {
                setState(() => _period = 'Year');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.all_inclusive),
              title: const Text('All Time'),
              onTap: () {
                setState(() => _period = 'All');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
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

    String dateLabel = 'All Time';
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
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filledTonal(
                onPressed: _period == 'All' ? null : _prevPeriod, 
                icon: const Icon(Icons.chevron_left),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                iconSize: 20,
              ),
              Expanded(
                child: InkWell(
                  onTap: () => _showPeriodSelectorSheet(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _period,
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const Gap(2),
                          Text(
                            dateLabel,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _period == 'All' ? null : _nextPeriod, 
                icon: const Icon(Icons.chevron_right),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                padding: EdgeInsets.zero,
                iconSize: 20,
              ),
            ],
          ),
        ),
        const Gap(16),

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
