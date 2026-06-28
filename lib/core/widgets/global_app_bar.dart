import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_manager/features/accounts/application/accounts_providers.dart';
import 'package:money_manager/core/providers/currency_provider.dart';
import 'dart:ui';

class GlobalAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const GlobalAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsWithBalance = ref.watch(accountsWithBalanceProvider);

    return AppBar(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.7) ?? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      centerTitle: true,
      title: accountsWithBalance.when(
        data: (stats) {
          double totalBalance = 0;
          for (var s in stats) {
            totalBalance += s.totalContributionToNetWorth;
          }
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/accounts'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${ref.watch(currencyProvider)}${totalBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Text('Loading...'),
        error: (_, __) => const Text('Dashboard'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            context.push('/settings');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
