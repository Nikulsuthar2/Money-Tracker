import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/core/widgets/scaffold_with_navbar.dart';
import 'package:money_manager/features/dashboard/presentation/dashboard_page.dart';
import 'package:money_manager/features/transactions/presentation/transactions_page.dart';
import 'package:money_manager/features/analytics/presentation/insights_page.dart';
import 'package:money_manager/features/settings/presentation/settings_page.dart';
import 'package:money_manager/features/accounts/presentation/add_account_page.dart';
import 'package:money_manager/features/transactions/presentation/add_transaction_page.dart';
import 'package:money_manager/features/categories/presentation/categories_page.dart';
import 'package:money_manager/features/categories/presentation/add_category_page.dart';
import 'package:money_manager/features/transactions/presentation/transaction_details_page.dart';
import 'package:money_manager/features/categories/domain/category.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';
import 'package:money_manager/features/people/presentation/person_details_page.dart';
import 'package:money_manager/features/transactions/presentation/advanced_split_page.dart';
import 'package:money_manager/features/transactions/presentation/expense_details_page.dart';
import 'package:money_manager/features/transactions/domain/timeline_entry.dart';
import 'package:money_manager/features/people/domain/person.dart';
import 'package:money_manager/features/accounts/domain/account.dart';
import 'package:money_manager/features/accounts/presentation/account_details_page.dart';
import 'package:money_manager/features/accounts/presentation/investment_account_details_page.dart';
import 'package:money_manager/features/people/presentation/people_page.dart';
import 'package:money_manager/features/accounts/presentation/accounts_page.dart' as accounts_page_import;
import 'package:money_manager/features/more/presentation/more_page.dart';
import 'package:money_manager/features/goals/domain/goal.dart';
import 'package:money_manager/features/goals/presentation/goals_page.dart';
import 'package:money_manager/features/goals/presentation/add_goal_page.dart';
import 'package:money_manager/features/goals/presentation/goal_details_page.dart';
import 'package:money_manager/features/budgets/presentation/budgets_page.dart';
import 'package:money_manager/features/budgets/presentation/add_edit_budget_page.dart';
import 'package:money_manager/features/budgets/presentation/budget_details_page.dart';
import 'package:money_manager/features/budgets/domain/budget.dart';
import 'package:money_manager/features/analytics/presentation/spend_analysis_page.dart';

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
                path: '/analytics', // keeping path same for now, or change to /insights
                builder: (context, state) => const InsightsPage(),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MorePage(),
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
        path: '/expense-details',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final entry = state.extra as ExpenseOnlyTimelineEntry;
          return ExpenseDetailsPage(entry: entry);
        },
      ),
      GoRoute(
        path: '/transaction-details',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final tx = state.extra as Transaction;
          return TransactionDetailsPage(transaction: tx);
        },
      ),
      GoRoute(
        path: '/parties',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PeoplePage(),
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
        path: '/investment-account',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final account = state.extra as Account;
          return InvestmentAccountDetailsPage(account: account);
        },
      ),
      GoRoute(
        path: '/person-details/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final person = state.extra as Person;
          return PersonDetailsPage(person: person);
        },
      ),
      GoRoute(
        path: '/advanced-split',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return AdvancedSplitPage(
            initialItems: data['initialItems'] as List<AdvancedExpenseItem>,
            people: data['people'] as List<Person>,
            categories: data['categories'] as List<Category>,
          );
        },
      ),
      GoRoute(
        path: '/accounts',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const accounts_page_import.AccountsPage(),
      ),
      GoRoute(
        path: '/goals',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GoalsPage(),
      ),
      GoRoute(
        path: '/add-goal',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final goal = state.extra as Goal?;
          return AddGoalPage(goalToEdit: goal);
        },
      ),
      GoRoute(
        path: '/goal-details',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final goal = state.extra as Goal;
          return GoalDetailsPage(goal: goal);
        },
      ),
      GoRoute(
        path: '/budgets',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BudgetsPage(),
      ),
      GoRoute(
        path: '/budgets/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AddEditBudgetPage(budget: state.extra as Budget?),
      ),
      GoRoute(
        path: '/spend-analysis',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SpendAnalysisPage(),
      ),
      GoRoute(
        path: '/budgets/details/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return BudgetDetailsPage(budgetId: id);
        },
      ),

    ],
  );
});

