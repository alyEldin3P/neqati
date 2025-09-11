import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/app_text.dart';

class GiftsScreen extends StatelessWidget {
  const GiftsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText('إدارة الهدايا'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText('شاشة إدارة الهدايا قيد التطوير'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement gift creation
              },
              child: AppText('إضافة هدية جديدة'),
            ),
          ],
        ),
      ),
    );
  }
}
