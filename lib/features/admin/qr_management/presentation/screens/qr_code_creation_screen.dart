import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:neqati/core/presentation/widgets/app_container.dart';
import 'package:neqati/core/presentation/widgets/app_text.dart';
import 'package:neqati/core/utils/app_colors.dart';
import 'package:neqati/core/utils/app_dimensions.dart';
import 'package:neqati/core/const/branches.dart';
import 'package:neqati/features/admin/qr_management/cubit/qr_management_cubit.dart';
import 'package:neqati/features/admin/qr_management/cubit/qr_management_state.dart';

class QRCodeCreationScreen extends StatefulWidget {
  const QRCodeCreationScreen({Key? key}) : super(key: key);

  @override
  State<QRCodeCreationScreen> createState() => _QRCodeCreationScreenState();
}

class _QRCodeCreationScreenState extends State<QRCodeCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pointsController = TextEditingController();
  final _expiryDurationController = TextEditingController(
    text: '30',
  ); // Default 30 days
  Branch _selectedBranch = Branch.riyadh; // Default to first branch
  String? _qrCodeData;
  String? _qrCodeId;
  bool _isLoading = false;

  @override
  void dispose() {
    _pointsController.dispose();
    _expiryDurationController.dispose();
    super.dispose();
  }

  void _createQRCode() {
    if (_formKey.currentState!.validate()) {
      final points = int.parse(_pointsController.text.trim());
      final branch = _selectedBranch.name;
      final expiryDuration = int.parse(_expiryDurationController.text.trim());

      context.read<QrManagementCubit>().createQRCode(
        points: points,
        branch: branch,
        expiryDuration: expiryDuration,
      );
    }
  }

  void _resetForm() {
    setState(() {
      _pointsController.clear();
      _selectedBranch = Branch.riyadh;
      _expiryDurationController.text = '30';
      _qrCodeData = null;
      _qrCodeId = null;
    });
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ البيانات إلى الحافظة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.title('إنشاء رمز QR', color: AppColors.white),
        backgroundColor: AppColors.deepTeal,
        centerTitle: true,
      ),
      body: BlocConsumer<QrManagementCubit, QrManagementState>(
        listener: (context, state) {
          if (state is QrManagementLoading) {
            setState(() {
              _isLoading = true;
            });
          } else {
            setState(() {
              _isLoading = false;
            });

            if (state is QrCodeCreated) {
              setState(() {
                _qrCodeData = state.qrCodeData;
                _qrCodeId = state.qrCodeId;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إنشاء رمز QR بنجاح')),
              );
            } else if (state is QrManagementError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.medium),
            child: Column(
              children: [
                if (_qrCodeData == null)
                  _buildQRCodeForm()
                else
                  _buildQRCodeResult(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQRCodeForm() {
    return AppContainer(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.subtitle('إنشاء رمز QR جديد', color: AppColors.deepTeal),
            const SizedBox(height: AppDimensions.medium),

            // Points field
            TextFormField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'النقاط',
                hintText: 'أدخل عدد النقاط',
                prefixIcon: const Icon(Icons.star),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.small),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال عدد النقاط';
                }
                final points = int.tryParse(value);
                if (points == null || points <= 0) {
                  return 'الرجاء إدخال عدد صحيح موجب';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.medium),

            // Branch dropdown
            _buildBranchDropdown(),
            const SizedBox(height: AppDimensions.medium),

            // Expiry duration field
            TextFormField(
              controller: _expiryDurationController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'مدة الصلاحية (بالأيام)',
                hintText: 'أدخل مدة الصلاحية بالأيام',
                prefixIcon: const Icon(Icons.timer),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.small),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال مدة الصلاحية';
                }
                final duration = int.tryParse(value);
                if (duration == null || duration <= 0) {
                  return 'الرجاء إدخال عدد صحيح موجب';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.large),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createQRCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.medium,
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : AppText(
                          'إنشاء رمز QR',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRCodeResult() {
    return Column(
      children: [
        AppContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppText.subtitle(
                'تم إنشاء رمز QR بنجاح',
                color: AppColors.deepTeal,
              ),
              const SizedBox(height: AppDimensions.medium),

              // QR Code
              Container(
                padding: const EdgeInsets.all(AppDimensions.medium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.small),
                ),
                child: QrImageView(
                  data: _qrCodeData!,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppDimensions.medium),

              // QR Code ID
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText('معرف الرمز: $_qrCodeId'),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyToClipboard(_qrCodeId!),
                  ),
                ],
              ),

              // QR Code Data
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AppText(
                      'بيانات الرمز: ${_qrCodeData!.length > 20 ? _qrCodeData!.substring(0, 20) + '...' : _qrCodeData}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyToClipboard(_qrCodeData!),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.medium),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resetForm,
                icon: const Icon(Icons.refresh),
                label: AppText('إنشاء رمز جديد', color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.medium,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.medium),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.list),
                label: AppText('عرض الرموز', color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.medium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBranchDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(AppDimensions.small),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.medium),
      child: Row(
        children: [
          const Icon(Icons.store, color: Colors.grey),
          const SizedBox(width: AppDimensions.small),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Branch>(
                value: _selectedBranch,
                isExpanded: true,
                items:
                    Branch.values.map((Branch branch) {
                      return DropdownMenuItem<Branch>(
                        value: branch,
                        child: AppText(branch.name, textAlign: TextAlign.right),
                      );
                    }).toList(),
                onChanged: (Branch? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedBranch = newValue;
                    });
                  }
                },
                hint: AppText(
                  'اختر الفرع',
                  color: Colors.grey,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
