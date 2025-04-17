import 'package:flutter/material.dart';
import 'package:main_draft1/main.dart';
import 'package:main_draft1/screens/plans.dart';

class SubscriptionCheck {
  static Future<bool> hasActiveSubscription(BuildContext context) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await supabase
          .from('tbl_subscription')
          .select('*')
          .eq('user_id', userId)
          .order('expiry_date', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final subscription = response[0];
        final endDate = DateTime.parse(subscription['expiry_date']);

        if (endDate.isAfter(DateTime.now())) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  static Future<void> checkAndPromptForSubscription(
      BuildContext context) async {
    final hasSubscription = await hasActiveSubscription(context);

    if (!hasSubscription) {
      // Only show the dialog if the user doesn't have an active subscription
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Subscription Required'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 48,
                  color: Colors.amber,
                ),
                SizedBox(height: 16),
                Text(
                  'Unlock premium features by subscribing to one of our plans',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Plans'),
              ),
            ],
          ),
        );
      }
    }
  }
}
