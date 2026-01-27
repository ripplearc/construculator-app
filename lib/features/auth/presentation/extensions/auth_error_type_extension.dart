// coverage:ignore-file

import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/widgets.dart';

extension AuthErrorTypeExtension on AuthErrorType {
  String? localizedMessage(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case AuthErrorType.userNotFound:
        return l10n.userNotFoundError;
      case AuthErrorType.invalidCredentials:
        return l10n.invalidCredentialsError;
      case AuthErrorType.unknownError:
        return l10n.unknownError;
      case AuthErrorType.serverError:
        return l10n.serverError;
      case AuthErrorType.registrationFailure:
        return l10n.registrationFailedError;
      case AuthErrorType.networkError:
        return l10n.networkError;
      case AuthErrorType.rateLimited:
        return l10n.rateLimitError;
      case AuthErrorType.connectionError:
        return l10n.connectionError;
      case AuthErrorType.timeout:
        return l10n.timeoutError;
      case AuthErrorType.emailRequired:
        return l10n.emailRequiredError;
      case AuthErrorType.invalidEmail:
        return l10n.invalidEmailError;
      case AuthErrorType.passwordRequired:
        return l10n.passwordRequiredError;
      case AuthErrorType.passwordTooShort:
        return l10n.passwordTooShortError;
      case AuthErrorType.passwordMissingUppercase:
        return l10n.passwordMissingUppercaseError;
      case AuthErrorType.passwordMissingLowercase:
        return l10n.passwordMissingLowercaseError;
      case AuthErrorType.passwordMissingNumber:
        return l10n.passwordMissingNumberError;
      case AuthErrorType.passwordMissingSpecialChar:
        return l10n.passwordMissingSpecialCharError;
      case AuthErrorType.passwordsDoNotMatch:
        return l10n.passwordsDoNotMatchError;
      case AuthErrorType.roleRequired:
        return l10n.roleRequiredError;
      case AuthErrorType.firstNameRequired:
        return l10n.firstNameRequired;
      case AuthErrorType.lastNameRequired:
        return l10n.lastNameRequired;
      case AuthErrorType.otpRequired:
        return l10n.otpRequiredError;
      case AuthErrorType.invalidOtp:
        return l10n.invalidOtpError;
      case AuthErrorType.phoneRequired:
        return l10n.phoneRequiredError;
      case AuthErrorType.invalidPhone:
        return l10n.invalidPhoneError;
      case AuthErrorType.uniqueViolation:
        return l10n.duplicateErrorMessage;
      case AuthErrorType.samePassword:
        return l10n.samePasswordErrorMessage;
    }
  }
}
