import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_manager/features/transactions/domain/transaction.dart';

class TransactionFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? monthYear; // e.g. "2026-06"
  final Set<TransactionType> types;
  final Set<int> categoryIds;
  final bool showTransactions;
  final bool showSettlements;
  final bool showFriendPaid;
  final bool showInvestments;

  const TransactionFilters({
    this.startDate,
    this.endDate,
    this.monthYear,
    this.types = const {},
    this.categoryIds = const {},
    this.showTransactions = true,
    this.showSettlements = true,
    this.showFriendPaid = false,
    this.showInvestments = false,
  });

  TransactionFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? monthYear,
    Set<TransactionType>? types,
    Set<int>? categoryIds,
    bool? showTransactions,
    bool? showSettlements,
    bool? showFriendPaid,
    bool? showInvestments,
    bool clearDates = false,
    bool clearMonth = false,
  }) {
    return TransactionFilters(
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      monthYear: clearMonth ? null : (monthYear ?? this.monthYear),
      types: types ?? this.types,
      categoryIds: categoryIds ?? this.categoryIds,
      showTransactions: showTransactions ?? this.showTransactions,
      showSettlements: showSettlements ?? this.showSettlements,
      showFriendPaid: showFriendPaid ?? this.showFriendPaid,
      showInvestments: showInvestments ?? this.showInvestments,
    );
  }
}

class TransactionFiltersNotifier extends StateNotifier<TransactionFilters> {
  TransactionFiltersNotifier() : super(const TransactionFilters());

  void updateFilters(TransactionFilters newFilters) {
    state = newFilters;
  }
  
  void clearFilters() {
    state = const TransactionFilters();
  }
}

final advancedTransactionsFilterProvider = StateNotifierProvider<TransactionFiltersNotifier, TransactionFilters>((ref) {
  return TransactionFiltersNotifier();
});
