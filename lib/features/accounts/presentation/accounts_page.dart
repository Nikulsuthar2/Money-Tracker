import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/presentation/widgets/account_card.dart';
import 'package:gap/gap.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'package:money_manager/core/widgets/custom_refresh_indicator.dart';
import 'package:go_router/go_router.dart';

class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage> {
  String _selectedType = 'All';

  final List<String> _types = [
    'All',
    'Cash',
    'Bank Account',
    'Credit Card',
    'PF Account',
    'Investment',
    'Loan',
    'E-Wallet',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsWithBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('My Accounts'),
        shape: const Border(), // remove default bottom border
        actions: [
          IconButton(
            onPressed: () => context.push('/add-account'),
            icon: const Icon(Icons.add_card),
            color: Theme.of(context).colorScheme.primary,
            tooltip: 'Add Account',
          ),
          const Gap(8),
        ],
      ),
      body: accountsAsync.when(
        data: (accounts) {
          AccountType? targetType;
          switch (_selectedType) {
             case 'Cash': targetType = AccountType.cash; break;
             case 'Bank Account': targetType = AccountType.bank; break;
             case 'Credit Card': targetType = AccountType.creditCard; break;
             case 'PF Account': targetType = AccountType.pf; break;
             case 'Investment': targetType = AccountType.investment; break;
             case 'Loan': targetType = AccountType.loan; break;
             case 'E-Wallet': targetType = AccountType.eWallet; break;
             case 'Other': targetType = AccountType.other; break;
          }

          final filteredAccounts = _selectedType == 'All'
              ? accounts
              : accounts.where((a) => a.account.type == targetType).toList();

          return Column(
            children: [
              const Gap(16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _types.map((type) {
                    final isSelected = _selectedType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = type;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Gap(16),
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withOpacity(0.5),
              ),
              Expanded(
                child: filteredAccounts.isEmpty
                    ? CustomRefreshIndicator(
                        onRefresh: () async {
                           ref.invalidate(accountsWithBalanceProvider);
                           await Future.delayed(const Duration(milliseconds: 300));
                        },
                        child: ListView(
                           children: const [
                              SizedBox(height: 100),
                              Center(child: Text('No accounts found.')),
                           ]
                        )
                      )
                    : CustomRefreshIndicator(
                        onRefresh: () async {
                           ref.invalidate(accountsWithBalanceProvider);
                           await Future.delayed(const Duration(milliseconds: 300));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            top: 10,
                            left: 16,
                            right: 16,
                            bottom: 80,
                          ),
                          itemCount: filteredAccounts.length,
                          itemBuilder: (context, index) {
                            return AccountCard(item: filteredAccounts[index]);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        error: (err, stack) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
