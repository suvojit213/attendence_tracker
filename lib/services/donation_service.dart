import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DonationService {
  static const String _lastShownKey = 'last_donation_popup_shown';
  static const String _showCountKey = 'donation_popup_show_count';
  static const int _maxShowsPerMonth = 4;

  Future<void> showDonationPopupIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownString = prefs.getString(_lastShownKey);
    final showCount = prefs.getInt(_showCountKey) ?? 0;

    final now = DateTime.now();
    DateTime? lastShownDate;

    if (lastShownString != null) {
      lastShownDate = DateTime.tryParse(lastShownString);
    }

    bool shouldShow = false;

    if (lastShownDate == null || lastShownDate.month != now.month || lastShownDate.year != now.year) {
      // New month or never shown, reset count and show
      await prefs.setInt(_showCountKey, 0);
      shouldShow = true;
    } else if (showCount < _maxShowsPerMonth) {
      // Same month, but less than max shows
      final daysSinceLastShow = now.difference(lastShownDate).inDays;
      if (daysSinceLastShow >= 7) { // Show roughly once a week
        shouldShow = true;
      }
    }

    if (shouldShow) {
      _showDonationDialog(context, prefs, showCount);
    }
  }

  void _showDonationDialog(BuildContext context, SharedPreferences prefs, int currentShowCount) {
    showDialog(
      context: context,
      barrierDismissible: true, // User can dismiss easily
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Support Development'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                  'Developing an application of this quality typically costs around ₹10,000-₹15,000 INR. However, I am providing this app to you completely free of charge.',
                ),
                const SizedBox(height: 10),
                const Text(
                  'If you find it useful and wish to support its continuous improvement, you can donate:',
                ),
                const SizedBox(height: 10),
                SelectableText(
                  'UPI ID: suvojeetsengupta2.wallet@phonepe',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your support motivates monthly updates and new features!',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Maybe Later'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Donate Now'),
              onPressed: () {
                _launchUPI();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) async {
      // This block executes after the dialog is dismissed
      await prefs.setString(_lastShownKey, DateTime.now().toIso8601String());
      await prefs.setInt(_showCountKey, currentShowCount + 1);
    });
  }

  Future<void> _launchUPI() async {
    final uri = Uri.parse('upi://pay?pa=suvojeetsengupta2.wallet@phonepe&pn=Suvojeet%20Sengupta&cu=INR');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle error: could not launch UPI app
      debugPrint('Could not launch UPI app');
    }
  }
}
