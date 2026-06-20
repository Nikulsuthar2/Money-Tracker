import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

final securityProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  return SecurityNotifier();
});

class SecurityState {
  final bool isBiometricEnabled;
  final bool isAuthenticated;

  SecurityState({this.isBiometricEnabled = false, this.isAuthenticated = false});

  SecurityState copyWith({bool? isBiometricEnabled, bool? isAuthenticated}) {
    return SecurityState(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  SecurityNotifier() : super(SecurityState()) {
    _loadSettings();
  }

  static const _key = 'biometric_enabled';
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_key) ?? false;
    // accurate initial state: if enabled, we are NOT authenticated yet
    state = state.copyWith(isBiometricEnabled: enabled, isAuthenticated: !enabled); 
  }

  Future<void> toggleBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
       // Check availability before enabling
       final canCheck = await auth.canCheckBiometrics;
       final isDeviceSupported = await auth.isDeviceSupported();
       
       if (!canCheck || !isDeviceSupported) {
         throw Exception('Biometric authentication not available on this device');
       }
       
       // Verify identity to enable
       final didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to enable biometric lock',
        );
        
        if (didAuthenticate) {
          await prefs.setBool(_key, true);
          state = state.copyWith(isBiometricEnabled: true);
        }
    } else {
      await prefs.setBool(_key, false);
      state = state.copyWith(isBiometricEnabled: false, isAuthenticated: true);
    }
  }

  Future<void> authenticate() async {
    if (!state.isBiometricEnabled) {
      state = state.copyWith(isAuthenticated: true);
      return;
    }

    try {
     // Attempt to use direct parameters if options fails, or minimal call
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access Money Tracker',
      );
      state = state.copyWith(isAuthenticated: didAuthenticate);
    } catch (e) {
      // Handle error or fallback
      state = state.copyWith(isAuthenticated: false);
    }
  }

  void lock() {
    if (state.isBiometricEnabled) {
      state = state.copyWith(isAuthenticated: false);
    }
  }
}

