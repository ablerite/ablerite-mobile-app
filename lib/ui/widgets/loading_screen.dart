import 'package:flutter/material.dart';
import 'ablerite_loading_indicator.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17AB77), // Matching brand green
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/ablerite_logo_rounded.png',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 30,
              height: 30,
              child: AbleriteLoadingIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
