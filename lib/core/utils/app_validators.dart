class AppValidators {
  // Validate empty field
  static String? validateEmptyField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال $fieldName';
    }
    return null;
  }

  // Validate phone number (Saudi Arabia format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }

    // Saudi Arabia phone number format (05xxxxxxxx)
    // final RegExp phoneRegex = RegExp(r'^05\d{8}$');
    // if (!phoneRegex.hasMatch(value.trim())) {
    //   return 'يرجى إدخال رقم هاتف صحيح (05xxxxxxxx)';
    // }

    return null;
  }

  // Validate Saudi National ID
  static String? validateNationalId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الهوية الوطنية';
    }

    // National ID must be exactly 14 digits
    final RegExp idRegex = RegExp(r'^\d{14}$');
    if (!idRegex.hasMatch(value.trim())) {
      return 'يرجى إدخال رقم هوية وطنية صحيح (14 رقم)';
    }

    return null;
  }

  // Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال كلمة المرور';
    }

    if (value.length < 6) {
      return 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل';
    }

    return null;
  }

  // Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }

    if (value != password) {
      return 'كلمة المرور غير متطابقة';
    }

    return null;
  }

  // Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }

    // Email regex pattern
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    return null;
  }

  // Validate position (مقاول, مهندس, فني)
  static String? validatePosition(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى اختيار المنصب';
    }

    final validPositions = ['مقاول', 'مهندس', 'فني'];
    if (!validPositions.contains(value.trim())) {
      return 'يرجى اختيار منصب صحيح (مقاول، مهندس، فني)';
    }

    return null;
  }
}
