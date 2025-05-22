import 'dart:io';
import 'dart:convert';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../models/subscription_model.dart';
import 'api_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final ApiService _apiService = ApiService();
  
  // 구독 상품 ID
  static const String _basicSubscriptionId = 'com.caloriesai.subscription.basic';
  static const String _premiumSubscriptionId = 'com.caloriesai.subscription.premium';

  // 구독 가격
  static const double _basicPrice = 2900.0;
  static const double _premiumPrice = 6900.0;

  // 현재 구독 정보
  Subscription? _currentSubscription;

  // 구독 상품 정보 가져오기
  Future<List<ProductDetails>> getSubscriptionProducts() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      throw Exception('인앱 결제를 사용할 수 없습니다.');
    }

    final Set<String> ids = {
      _basicSubscriptionId,
      _premiumSubscriptionId,
    };

    final ProductDetailsResponse response = 
        await _inAppPurchase.queryProductDetails(ids);

    if (response.notFoundIDs.isNotEmpty) {
      print('찾을 수 없는 상품 ID: ${response.notFoundIDs}');
    }

    return response.productDetails;
  }

  // 구독 구매
  Future<bool> purchaseSubscription(SubscriptionType type) async {
    try {
      final products = await getSubscriptionProducts();
      final productId = type == SubscriptionType.basic 
          ? _basicSubscriptionId 
          : _premiumSubscriptionId;
      
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('상품을 찾을 수 없습니다.'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      if (Platform.isIOS) {
        final bool success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
        return success;
      } else {
        // Android의 경우 Google Play 결제
        final bool success = await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
        return success;
      }
    } catch (e) {
      print('구독 구매 중 오류 발생: $e');
      rethrow;
    }
  }

  // 구독 정보 확인
  Future<Subscription?> getCurrentSubscription() async {
    try {
      final token = await _apiService.getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      final response = await _apiService.get(
        '/subscriptions/current',
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _currentSubscription = Subscription.fromJson(jsonDecode(response.body));
        return _currentSubscription;
      } else {
        return null;
      }
    } catch (e) {
      print('구독 정보 확인 중 오류 발생: $e');
      return null;
    }
  }

  // 구독 상태 확인
  Future<bool> canUploadImage() async {
    if (_currentSubscription == null) {
      await getCurrentSubscription();
    }
    return _currentSubscription?.canUpload ?? false;
  }

  // 구독 사용량 업데이트
  Future<void> updateSubscriptionUsage() async {
    if (_currentSubscription?.type == SubscriptionType.basic) {
      try {
        final token = await _apiService.getToken();
        if (token == null) {
          throw Exception('인증 토큰이 없습니다.');
        }

        await _apiService.post(
          '/subscriptions/usage',
          headers: {'Authorization': 'Bearer $token'},
          data: {'subscriptionId': _currentSubscription!.id},
        );
      } catch (e) {
        print('구독 사용량 업데이트 중 오류 발생: $e');
        rethrow;
      }
    }
  }
} 