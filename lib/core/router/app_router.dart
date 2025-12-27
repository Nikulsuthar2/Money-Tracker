import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/widgets/scaffold_with_navbar.dart';
import 'package:money_manager/features/dashboard/presentation/dashboard_page.dart';
import 'package:money_manager/features/transactions/presentation/transactions_page.dart';
import 'package:money_manager/features/subscriptions/presentation/subscriptions_page.dart';
import 'package:money_manager/features/analytics/presentation/analytics_page.dart';
import 'package:money_manager/features/settings/presentation/settings_page.dart';
import 'package:money_manager/features/accounts/presentation/add_account_page.dart';
import 'package:money_manager/features/transactions/presentation/add_transaction_page.dart';
import 'package:money_manager/features/categories/presentation/categories_page.dart';
import 'package:money_manager/features/categories/presentation/add_category_page.dart';
import 'package:money_manager/features/transactions/presentation/transaction_details_page.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/transactions/presentation/all_transactions_table_page.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/presentation/account_details_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final sectionNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavbar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          // Accounts branch removed - merged into Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/transactions',
                builder: (context, state) => const TransactionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subscriptions',
                builder: (context, state) => const SubscriptionsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),

        ],
      ),
      GoRoute(
        path: '/add-account',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final account = state.extra as Account?;
          return AddAccountPage(accountToEdit: account);
        },
      ),
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
        return AddTransactionPage(extra: state.extra);
      },
      ),
      GoRoute(
        path: '/add-category',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final category = state.extra as Category?;
          return AddCategoryPage(categoryToEdit: category);
        },
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/transaction-details',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final transaction = state.extra as Transaction;
          return TransactionDetailsPage(transaction: transaction);
        },
      ),
      GoRoute(
        path: '/account-details',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final account = state.extra as Account;
          return AccountDetailsPage(account: account);
        },
      ),
      GoRoute(
        path: '/transactions-table',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AllTransactionsTablePage(),
      ),
      GoRoute(
        path: '/subscriptions',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SubscriptionsPage(),
      ),
    ],
  );
});
