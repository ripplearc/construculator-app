import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/widgets/otp_verification_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/toast/toast.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/presentation/bloc/forgot_password_bloc/forgot_password_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final focusNode = FocusNode();
  List<String>? _emailErrorList;
  AppLocalizations? l10n;
  final CToast _toast = Modular.get<CToast>();
  final AppRouter _router = Modular.get<AppRouter>();

  void _handleFailure(Failure failure) {
    if (failure is AuthFailure) {
      if (failure.errorType == AuthErrorType.rateLimited) {
        _toast.showError(context, l10n?.tooManyAttempts);
      } else {
        _toast.showError(context, failure.errorType.localizedMessage(context));
      }
    } else {
      _toast.showError(context, l10n?.unexpectedErrorMessage);
    }
  }

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      final emailValidationResult = AuthValidation.validateEmail(
        _emailController.text,
      );
      if (emailValidationResult != null) {
        setState(() {
          final error = emailValidationResult.localizedMessage(context);
          if (error != null) {
            setState(() {
              _emailErrorList = [error];
            });
          }
        });
      } else {
        setState(() {
          _emailErrorList = null;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    l10n = AppLocalizations.of(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _toast.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context) {
    if (focusNode.hasFocus) {
      focusNode.unfocus();
    }
    BlocProvider.of<ForgotPasswordBloc>(
      context,
    ).add(ForgotPasswordSubmitted(_emailController.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreBackgroundColors.pageBackground,
      appBar: AppBar(
        backgroundColor: CoreBackgroundColors.pageBackground,
        elevation: 0,
      ),
      body: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            showEmailVerificationBottomSheet(context, _emailController.text);
          } else if (state is ForgotPasswordFailure) {
            _handleFailure(state.failure);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: CoreSpacing.space6,
              vertical: CoreSpacing.space6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n?.forgotPasswordTitle}',
                  style: CoreTypography.headlineLargeSemiBold(),
                ),
                const SizedBox(height: CoreSpacing.space2),
                Text(
                  '${l10n?.forgotPasswordDescription}',
                  style: CoreTypography.bodyLargeRegular(),
                ),
                const SizedBox(height: CoreSpacing.space10),
                CoreTextField(
                  focusNode: focusNode,
                  controller: _emailController,
                  label: '${l10n?.emailLabel}',
                  hintText: '${l10n?.enterEmailHint}',
                  keyboardType: TextInputType.emailAddress,
                  errorTextList: _emailErrorList,
                ),
                const SizedBox(height: CoreSpacing.space10),
                CoreButton(
                  onPressed: () => _onSubmit(context),
                  isDisabled:
                      state is ForgotPasswordLoading ||
                      _emailController.text.isEmpty ||
                      _emailErrorList != null,
                  label:
                      state is ForgotPasswordLoading
                          ? '${l10n?.sendingOtpButton}'
                          : '${l10n?.sendResetLinkButton}',
                  centerAlign: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void showEmailVerificationBottomSheet(
    BuildContext callingContext,
    String email,
  ) {
    String otp = '';
    showModalBottomSheet(
      context: callingContext,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return BlocProvider.value(
          value: BlocProvider.of<OtpVerificationBloc>(callingContext),
          child: BlocConsumer<OtpVerificationBloc, OtpVerificationState>(
            listener: (context, state) {
              if (state is OtpVerificationOtpChangeUpdated) {
                otp = state.otp;
              }
              if (state is OtpVerificationSuccess) {
                Navigator.pop(context);
                _router.pushNamed(fullSetNewPasswordRoute, arguments: email);
              }
              if (state is OtpVerificationFailure) {
                _handleFailure(state.failure);
              }
              if (state is OtpVerificationOtpResent) {
                _toast.showSuccess(context, l10n?.otpResendSuccess);
              }
              if (state is OtpVerificationResendFailure) {
                _handleFailure(state.failure);
              }
            },
            builder: (context, state) {
              return OtpVerificationBottomSheet(
                note: '${l10n?.otpVerificationNote}',
                contact: email,
                isResending: state is OtpVerificationResendLoading,
                isVerifying: state is OtpVerificationLoading,
                verifyButtonDisabled:
                    otp.isEmpty ||
                    state is OtpVerificationLoading ||
                    state is OtpVerificationResendLoading,
                onResend: () {
                  BlocProvider.of<OtpVerificationBloc>(
                    context,
                  ).add(OtpVerificationResendRequested(contact: email));
                },
                onEdit: () {
                  Navigator.pop(context);
                  BlocProvider.of<ForgotPasswordBloc>(
                    callingContext,
                  ).add(ForgotPasswordEditEmail());
                  focusNode.requestFocus();
                },
                onVerify: () {
                  BlocProvider.of<OtpVerificationBloc>(
                    context,
                  ).add(OtpVerificationSubmitted(contact: email, otp: otp));
                },
                onChanged: (otp) {
                  final otpValidator = AuthValidation.validateOtp(otp);
                  if (otpValidator == null) {
                    BlocProvider.of<OtpVerificationBloc>(
                      context,
                    ).add(OtpVerificationOtpChanged(otp: otp));
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
