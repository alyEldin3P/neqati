import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/app_text.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText('إدارة العروض'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText('شاشة إدارة العروض قيد التطوير'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement offer creation
              },
              child: AppText('إضافة عرض جديد'),
            ),
          ],
        ),
      ),
    );
  }
}
