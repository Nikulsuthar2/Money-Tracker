import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavingsSettings {
  final bool isEnabled;
  final double percentage;
  final int? accountId;

  SavingsSettings({this.isEnabled = false, this.percentage = 10.0, this.accountId});

  SavingsSettings copyWith({bool? isEnabled, double? percentage, int? accountId}) {
    return SavingsSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      percentage: percentage ?? this.percentage,
      accountId: accountId ?? this.accountId,
    );
  }
}

class SavingsNotifier extends StateNotifier<SavingsSettings> {
  SavingsNotifier() : super(SavingsSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SavingsSettings(
      isEnabled: prefs.getBool('savings_enabled') ?? false,
      percentage: prefs.getDouble('savings_percentage') ?? 10.0,
      accountId: prefs.getInt('savings_account_id'),
    );
  }

  Future<void> setEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('savings_enabled', isEnabled);
    state = state.copyWith(isEnabled: isEnabled);
  }

  Future<void> setPercentage(double percentage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('savings_percentage', percentage);
    state = state.copyWith(percentage: percentage);
  }

  Future<void> setAccountId(int? accountId) async {
    final prefs = await SharedPreferences.getInstance();
    if (accountId == null) {
      await prefs.remove('savings_account_id');
    } else {
      await prefs.setInt('savings_account_id', accountId);
    }
    state = state.copyWith(accountId: accountId);
  }
}

final savingsProvider = StateNotifierProvider<SavingsNotifier, SavingsSettings>((ref) {
  return SavingsNotifier();
});
