import 'package:flutter/material.dart';

class TermsDialog extends StatelessWidget {
  const TermsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Privacy Policy & Terms of Service',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  '''
1. Introduction
Welcome to Vega Coach. By downloading, accessing, or using our mobile application, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree, please do not use the application.

2. Data Collection and Usage
To provide and improve our services (including AI chat and screenshot analysis), we collect the following information:

• Account Information: Name, email address, and profile picture provided during Google or Email signup.
• User Content: Screenshots uploaded for analysis and messages sent within the AI chat.
• Device Data: Standard crash logs and diagnostic data to ensure app stability.

We do not sell your personal data to third parties. Data is strictly used to facilitate app functionality and enhance your user experience within the Valorant Mobile ecosystem.

3. User Conduct and Account Security
• You are responsible for maintaining the confidentiality of your account credentials.
• You agree not to upload any inappropriate, illegal, or unauthorized content through the screenshot analysis or chat features.
• We reserve the right to suspend or terminate accounts that violate community guidelines or attempt to exploit the application's API.

4. Third-Party Services & AI
Vega Coach utilizes third-party APIs for AI processing (chat and image analysis). By using these features, you acknowledge that your uploaded images and text inputs are processed by these secure third-party services exclusively for generating your requested results.

5. Modification of Terms
We reserve the right to update these terms at any time to reflect changes in our services or Play Store compliance requirements. Continued use of the app constitutes acceptance of the new terms.

Contact Us
For any questions regarding your privacy or these terms, please contact us at vegaesportsnetwork0@gmail.com.
''',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
