import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../firebase_auth_service.dart';
import 'welcome_screen.dart';

class AuthHomeScreen extends StatelessWidget {
  const AuthHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final title = (displayName != null && displayName.isNotEmpty)
        ? 'Welcome, $displayName'
        : 'Welcome to Highway TollPay';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              user?.email ?? 'You are signed in.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: const Text(
                'Firebase authentication is connected. From here we can add the rest of your toll dashboard next.',
                style: TextStyle(height: 1.55),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await FirebaseAuthService.instance.signOut();
                  if (!context.mounted) {
                    return;
                  }

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
