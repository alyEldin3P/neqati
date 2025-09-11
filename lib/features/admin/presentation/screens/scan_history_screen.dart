import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/app_text.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText('سجل المسح'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText('سجل عمليات مسح رموز QR قيد التطوير'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement scan history refresh
              },
              child: AppText('تحديث البيانات'),
            ),
          ],
        ),
      ),
    );
  }
}
