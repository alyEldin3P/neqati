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

    // // Saudi Arabia phone number format (05xxxxxxxx or 5xxxxxxxx)
    if (value.length != 11) {
      return 'يرجى إدخال رقم هاتف صحيح';
    }

    return null;
  }

  // Validate Saudi National ID
  static String? validateNationalId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال رقم الهوية الوطنية';
    }

    // Saudi National ID is 10 digits
    final RegExp idRegex = RegExp(r'^\d{10}$');
    if (!idRegex.hasMatch(value.trim())) {
      return 'يرجى إدخال رقم هوية وطنية صحيح (10 أرقام)';
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
