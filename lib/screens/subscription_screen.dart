import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final Function(bool) onSubscriptionComplete;

  const SubscriptionScreen({
    Key? key,
    required this.onSubscriptionComplete,
  }) : super(key: key);

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;

  Future<void> _purchaseSubscription(SubscriptionType type) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _subscriptionService.purchaseSubscription(type);
      if (success) {
        widget.onSubscriptionComplete(true);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구독 구매에 실패했습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('구독 서비스'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '구독 서비스를 선택해주세요',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32.0),
                  _buildSubscriptionCard(
                    title: '기본 구독',
                    description: '하루 3회 업로드',
                    price: '2,900원/월',
                    type: SubscriptionType.basic,
                  ),
                  const SizedBox(height: 16.0),
                  _buildSubscriptionCard(
                    title: '프리미엄 구독',
                    description: '무제한 업로드',
                    price: '6,900원/월',
                    type: SubscriptionType.premium,
                    isPremium: true,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSubscriptionCard({
    required String title,
    required String description,
    required String price,
    required SubscriptionType type,
    bool isPremium = false,
  }) {
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: () => _purchaseSubscription(type),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: isPremium ? Colors.amber : Colors.grey,
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: const Text(
                    'BEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 8.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8.0),
              ElevatedButton(
                onPressed: () => _purchaseSubscription(type),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPremium ? Colors.amber : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('구독하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 