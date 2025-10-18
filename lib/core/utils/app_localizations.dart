import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to get localized strings
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Singleton factory
  static final AppLocalizations _instance = AppLocalizations(
    const Locale('ar'),
  );

  // Getter for singleton instance
  static AppLocalizations get instance => _instance;

  // Arabic translations
  static final Map<String, String> _localizedValues = {
    // General
    'app_name': 'ابوراية الكل كسبان',
    'loading': 'جاري التحميل...',
    'error': 'حدث خطأ',
    'success': 'تم بنجاح',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'confirm': 'تأكيد',
    'back': 'رجوع',
    'next': 'التالي',
    'done': 'تم',

    // Auth
    'login': 'تسجيل الدخول',
    'register': 'تسجيل جديد',
    'forgot_password': 'نسيت كلمة المرور؟',
    'phone_number': 'رقم الهاتف',
    'password': 'كلمة المرور',
    'confirm_password': 'تأكيد كلمة المرور',
    'name': 'الاسم',
    'address': 'العنوان',
    'national_id': 'رقم الهوية الوطنية',
    'position': 'المنصب',
    'contractor': 'مقاول',
    'engineer': 'مهندس',
    'technician': 'فني',
    'account_not_verified':
        'حسابك قيد المراجعة من قبل الإدارة. يرجى المحاولة لاحقاً.',
    'register_success': 'تم التسجيل بنجاح. يرجى انتظار موافقة الإدارة.',

    // Home
    'home': 'الرئيسية',
    'scan': 'مسح',
    'profile': 'الملف الشخصي',
    'gifts': 'الهدايا',
    'offers': 'العروض',
    'levels': 'المستويات',
    'scan_history': 'سجل المسح',
    'total_points': 'مجموع النقاط',
    'scan_qr': 'مسح رمز QR',
    'scan_success': 'تم المسح بنجاح',
    'points_earned': 'النقاط المكتسبة',

    // Profile
    'edit_profile': 'تعديل الملف الشخصي',
    'current_level': 'المستوى الحالي',
    'points_to_next_level': 'النقاط المتبقية للمستوى التالي',
    'logout': 'تسجيل الخروج',

    // Gifts
    'available_gifts': 'الهدايا المتاحة',
    'required_points': 'النقاط المطلوبة',
    'request_gift': 'طلب الهدية',
    'gift_requested': 'تم طلب الهدية بنجاح',
    'insufficient_points': 'نقاط غير كافية',

    // Offers
    'available_offers': 'العروض المتاحة',
    'no_offers': 'لا توجد عروض متاحة حالياً',

    // Admin
    'admin_panel': 'لوحة الإدارة',
    'users': 'المستخدمين',
    'registration_requests': 'طلبات التسجيل',
    'gift_requests': 'طلبات الهدايا',
    'create_qr': 'إنشاء رمز QR',
    'manage_gifts': 'إدارة الهدايا',
    'manage_offers': 'إدارة العروض',
    'manage_levels': 'إدارة المستويات',
    'approve': 'موافقة',
    'deny': 'رفض',
    'block_user': 'حظر المستخدم',
    'unblock_user': 'إلغاء حظر المستخدم',
    'make_admin': 'تعيين كمدير',
    'remove_admin': 'إزالة صلاحيات المدير',
    'qr_points': 'نقاط الرمز',
    'qr_branch': 'فرع الرمز',
    'qr_expiry': 'مدة الصلاحية (أيام)',
    'create': 'إنشاء',
    'edit': 'تعديل',
    'delete': 'حذف',
    'search': 'بحث',
    'filter': 'تصفية',
    'status': 'الحالة',
    'date': 'التاريخ',
    'active': 'نشط',
    'expired': 'منتهي',
    'scanned': 'تم المسح',
    'pending': 'قيد الانتظار',
    'approved': 'تمت الموافقة',
    'denied': 'مرفوض',
  };

  String translate(String key) {
    return _localizedValues[key] ?? key;
  }
}

// Extension to make it easier to use translations
extension StringTranslationExtension on String {
  String get trans => AppLocalizations.instance.translate(this);
}
