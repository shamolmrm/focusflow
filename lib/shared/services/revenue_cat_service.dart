import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const _androidKey = 'goog_your_revenuecat_api_key';
  static const _iosKey = 'appl_your_revenuecat_api_key';

  static const monthlyId = 'focusflow_pro_monthly';
  static const annualId = 'focusflow_pro_annual';
  static const lifetimeId = 'focusflow_pro_lifetime';

  static Future<void> initialize() async {
    await Purchases.setLogLevel(LogLevel.debug);
    final config = PurchasesConfiguration(
      Platform.isAndroid ? _androidKey : _iosKey,
    );
    await Purchases.configure(config);
  }

  static Future<bool> get isPro async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('pro');
    } catch (_) {
      return false;
    }
  }

  static Future<List<Package>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> purchase(Package package) async {
    try {
      await Purchases.purchasePackage(package);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.containsKey('pro');
    } catch (_) {
      return false;
    }
  }

  static Future<void> login(String userId) async {
    await Purchases.logIn(userId);
  }

  static Future<void> logout() async {
    await Purchases.logOut();
  }
}
