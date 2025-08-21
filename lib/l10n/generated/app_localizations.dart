import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Label for agree and continue button
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get agreeAndContinueButton;

  /// Text for already have an account
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Text connecting terms and privacy policy
  ///
  /// In en, this message translates to:
  /// **'and acknowledge'**
  String get andAcknowledge;

  /// Title for authentication code bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Authentication Code'**
  String get authenticationCodeTitle;

  /// Error messages for authentication operations
  ///
  /// In en, this message translates to:
  /// **'Authentication Error Messages'**
  String get authErrorMessages;

  /// Label for checking availability button
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checkingAvailabilityButton;

  /// Label for close button on toast notification
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// Hint text for confirm password input field
  ///
  /// In en, this message translates to:
  /// **'Enter Password Confirmation'**
  String get confirmPasswordHint;

  /// Label for confirm password input field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password*'**
  String get confirmPasswordLabel;

  /// Error message shown when confirm password is required
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required'**
  String get confirmPasswordRequired;

  /// Error message for connection errors
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// Label for login button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Text for continue with apple
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Text for continue with email
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// Text for continue with google
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Text for continue with microsoft
  ///
  /// In en, this message translates to:
  /// **'Continue with Microsoft'**
  String get continueWithMicrosoft;

  /// Text for continue with phone
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get continueWithPhone;

  /// Subtitle for create account page
  ///
  /// In en, this message translates to:
  /// **'Email you entered is not registered with us, to create your construculator account enter details below'**
  String get createAccountSubtitle;

  /// Success message shown after registration
  ///
  /// In en, this message translates to:
  /// **'You have successfully registered with Construculator'**
  String get createAccountSuccessMessage;

  /// Title for the create account page
  ///
  /// In en, this message translates to:
  /// **'Create your Account'**
  String get createAccountTitle;

  /// Label for button while account is being created
  ///
  /// In en, this message translates to:
  /// **'Creating Account...'**
  String get creatingAccountButton;

  /// Text asking if user did not receive code
  ///
  /// In en, this message translates to:
  /// **'Did not receive code?'**
  String get didNotReceiveCode;

  /// Text for auth footer on login page
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAndAccountText;

  /// Generic duplicate error message
  ///
  /// In en, this message translates to:
  /// **'Duplicate Error'**
  String get duplicateErrorMessage;

  /// Message shown when email is registered and user needs to login
  ///
  /// In en, this message translates to:
  /// **'Email ID already registered with us. Please '**
  String get emailAlreadyRegistered;

  /// Error message when email is a duplicate
  ///
  /// In en, this message translates to:
  /// **'Email exists'**
  String get emailDuplicateErrorMessage;

  /// Hint text for email input field
  ///
  /// In en, this message translates to:
  /// **'Email ID*'**
  String get emailHint;

  /// Label for email input field
  ///
  /// In en, this message translates to:
  /// **'Email ID'**
  String get emailLabel;

  /// Message shown when email is not registered and user needs to create an account
  ///
  /// In en, this message translates to:
  /// **'Email ID not registered with us. Please '**
  String get emailNotRegistered;

  /// Error message when email is required
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequiredError;

  /// Description text on enter password page
  ///
  /// In en, this message translates to:
  /// **'Enter your password for this account. Your email id is'**
  String get enterPasswordDescription;

  /// Title for enter password page
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPasswordTitle;

  /// Text displayed on login page, instructing user to enter details to login to their account
  ///
  /// In en, this message translates to:
  /// **'Hey, Enter your details to log in to your account'**
  String get enterYourEmailIdToLoginToYourAccount;

  /// Hint text for first name input field
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstNameHint;

  /// Label for first name input field
  ///
  /// In en, this message translates to:
  /// **'First name*'**
  String get firstNameLabel;

  /// Error message shown when first name is required
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get firstNameRequired;

  /// Description text on forgot password page
  ///
  /// In en, this message translates to:
  /// **'An OTP will be sent to your registered email ID to reset your password'**
  String get forgotPasswordDescription;

  /// Link text for forgot password
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// Title for forgot password page
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// Text for hey enter your details to register with us
  ///
  /// In en, this message translates to:
  /// **'Hey, Enter your details to Register with us'**
  String get heyEnterYourDetailsToRegisterWithUs;

  /// Error message for invalid credentials
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get invalidCredentialsError;

  /// Error message when email is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmailError;

  /// Error message when OTP is invalid
  ///
  /// In en, this message translates to:
  /// **'OTP must be exactly 6 digits'**
  String get invalidOtpError;

  /// Error message when phone number is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number in international format (e.g., +1234567890)'**
  String get invalidPhoneError;

  /// Error message shown when the verification code is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code'**
  String get invalidVerificationCode;

  /// Hint text for last name input field
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastNameHint;

  /// Label for last name input field
  ///
  /// In en, this message translates to:
  /// **'Last name*'**
  String get lastNameLabel;

  /// Error message shown when last name is required
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get lastNameRequired;

  /// Label for new registration
  ///
  /// In en, this message translates to:
  /// **'Let\'s Get Started'**
  String get letsGetStarted;

  /// Label for button while logging in
  ///
  /// In en, this message translates to:
  /// **'Logging in...'**
  String get loggingInButton;

  /// Label for log in link
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logginLink;

  /// Error message shown when login fails due to invalid credentials
  ///
  /// In en, this message translates to:
  /// **'Login failed - invalid credentials'**
  String get loginFailedInvalidCredentials;

  /// Success message shown after login
  ///
  /// In en, this message translates to:
  /// **'You have successfully logged in with Construculator'**
  String get loginSuccessMessage;

  /// Hint text for mobile number input field
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumberHint;

  /// Label for mobile number input field
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumberLabel;

  /// Error message for network errors
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// Hint text for new password input field
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordHint;

  /// Label for new password input field
  ///
  /// In en, this message translates to:
  /// **'New Password*'**
  String get newPasswordLabel;

  /// Text for or under login/register form, providing options to continue with other methods
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// Error message shown when OTP is incomplete
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 6-digit OTP.'**
  String get otpIncompleteError;

  /// Note text on OTP verification screen for phone number
  ///
  /// In en, this message translates to:
  /// **'Enter 6 digit code we just texted to your phone number'**
  String get otpPhoneVerificationNote;

  /// Error message when OTP is required
  ///
  /// In en, this message translates to:
  /// **'OTP is required'**
  String get otpRequiredError;

  /// Success message shown after OTP is resent
  ///
  /// In en, this message translates to:
  /// **'OTP Resent!'**
  String get otpResendSuccess;

  /// Note text on OTP verification screen
  ///
  /// In en, this message translates to:
  /// **'Enter 6 digit code we just texted to your email ID'**
  String get otpVerificationNote;

  /// Hint text for password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Password*'**
  String get passwordLabel;

  /// Error message when password is missing lowercase letter
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordMissingLowercaseError;

  /// Error message when password is missing number
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get passwordMissingNumberError;

  /// Error message when password is missing special character
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one special character (!@#\$&*~)'**
  String get passwordMissingSpecialCharError;

  /// Error message when password is missing uppercase letter
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordMissingUppercaseError;

  /// Error message when password is required
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequiredError;

  /// Success message shown after password reset
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset successfully!'**
  String get passwordResetSuccessMessage;

  /// Error message when passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatchError;

  /// Error message when password is too short
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordTooShortError;

  /// Error message when phone is a duplicate
  ///
  /// In en, this message translates to:
  /// **'Phone number exists'**
  String get phoneDuplicateErrorMessage;

  /// Error message when phone number is required
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequiredError;

  /// Link text for privacy policy
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get privacyPolicyLink;

  /// Error message when rate limit is exceeded
  ///
  /// In en, this message translates to:
  /// **'Rate limit exceeded'**
  String get rateLimitError;

  /// Text for register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Error message when registration fails
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailedError;

  /// Error message shown when user registration fails
  ///
  /// In en, this message translates to:
  /// **'Registration failed - please try again'**
  String get registrationFailedTryAgain;

  /// Success message shown after registration
  ///
  /// In en, this message translates to:
  /// **'You have successfully registered with Construculator'**
  String get registrationSuccessMessage;

  /// Error message shown when a request times out
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get requestTimedOut;

  /// Label for resend button
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resendButton;

  /// Label for resending button
  ///
  /// In en, this message translates to:
  /// **'Resending...'**
  String get resendingButtonLabel;

  /// Hint text for role selection field
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleHint;

  /// Label for role selection field
  ///
  /// In en, this message translates to:
  /// **'Role*'**
  String get roleLabel;

  /// Error message shown user does not select professional role
  ///
  /// In en, this message translates to:
  /// **'Professional role is required.'**
  String get roleRequiredError;

  /// Error message shown when roles cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Error loading roles. Please try again.'**
  String get rolesLoadingError;

  /// Error message when new password is same is current password
  ///
  /// In en, this message translates to:
  /// **'Password is the same as current one, please change it.'**
  String get samePasswordErrorMessage;

  /// Title for contry code selector
  ///
  /// In en, this message translates to:
  /// **'Select Country Code'**
  String get selectCountryCode;

  /// Title for role selection modal
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRoleTitle;

  /// Label for button while sending otp
  ///
  /// In en, this message translates to:
  /// **'Sending Otp...'**
  String get sendingOtpButton;

  /// Error message when sending otp fails
  ///
  /// In en, this message translates to:
  /// **'Sending Otp Failed, Please try again.'**
  String get sendingOtpFailed;

  /// Error message for server errors
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// Description text on set new password page
  ///
  /// In en, this message translates to:
  /// **'Your password must minimum of 8 characters, with upper and lowercase and a number or a symbol'**
  String get setNewPasswordDescription;

  /// Title for set new password page
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get setNewPasswordTitle;

  /// Label for set password button
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPasswordButton;

  /// Label for button while setting password
  ///
  /// In en, this message translates to:
  /// **'Setting Password...'**
  String get settingPasswordButton;

  /// Text for terms and conditions agreement
  ///
  /// In en, this message translates to:
  /// **'By selecting agree and continue. I agree to Construculator '**
  String get termsAndConditionsText;

  /// Link text for terms and services
  ///
  /// In en, this message translates to:
  /// **'terms & services'**
  String get termsAndServicesLink;

  /// Error message for request timeouts
  ///
  /// In en, this message translates to:
  /// **'Request timeout'**
  String get timeoutError;

  /// Error message when too many attempts
  ///
  /// In en, this message translates to:
  /// **'Too many attempts, please try again in a minute.'**
  String get tooManyAttempts;

  /// Generic error message for unexpected errors
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred, try again or contact support.'**
  String get unexpectedErrorMessage;

  /// Error message for unknown errors
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// Error message when user is not found
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFoundError;

  /// Label for verifying button
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifyingButtonLabel;

  /// Label for verify OTP button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyOtpButton;

  /// Text for welcome back
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
