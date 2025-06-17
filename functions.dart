bool isValidEmailFormat(String email) {
  if (email.isEmpty) return false;
  // Basic regex for email format validation
  return RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  ).hasMatch(email);
}

PasswordValidationResult checkPasswordStrength(String password) {
  final errors = <String>[];
  PasswordStrength strength = PasswordStrength.none;
  if (password.length < 8) {
    errors.add('At least 8 characters.');
  }
  if (!password.contains(RegExp(r'[A-Z]'))) {
    errors.add('An uppercase letter.');
  }
  if (!password.contains(RegExp(r'[a-z]'))) {
    errors.add('A lowercase letter.');
  }
  if (!password.contains(RegExp(r'[0-9]'))) {
    errors.add('A digit.');
  }
  if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    errors.add('A special character.');
  }

  int score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[a-z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

  if (errors.isEmpty && password.isNotEmpty) {
    strength = PasswordStrength.strong;
  } else if (score >= 3 && password.isNotEmpty) {
    strength = PasswordStrength.medium;
  } else if (password.isNotEmpty) {
    strength = PasswordStrength.weak;
  } else {
    strength = PasswordStrength.none;
  }
  return PasswordValidationResult(strength, errors);
}

class PasswordValidationResult {
  final PasswordStrength strength;
  final List<String> errors;

  PasswordValidationResult(this.strength, this.errors);
}

enum PasswordStrength { none, weak, medium, strong }
