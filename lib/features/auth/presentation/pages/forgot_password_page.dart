import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_header.dart';
import 'package:construculator/features/auth/presentation/widgets/otp_quick_sheet/otp_verification_sheet.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/mixins/localization_mixin.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
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

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with LocalizationMixin {
  final TextEditingController _emailController = TextEditingController();
  final focusNode = FocusNode();
  List<String>? _emailErrorList;
  final AppRouter _router = Modular.get<AppRouter>();

  void _handleFailure(Failure failure) {
    if (failure is AuthFailure) {
      if (failure.errorType == AuthErrorType.rateLimited) {
        CoreToast.showError(
          context,
          l10n?.tooManyAttempts,
          '${l10n?.continueButton}',
        );
      } else {
        CoreToast.showError(
          context,
          failure.errorType.localizedMessage(context),
          '${l10n?.continueButton}',
        );
      }
    } else {
      CoreToast.showError(
        context,
        l10n?.unexpectedErrorMessage,
        '${l10n?.continueButton}',
      );
    }
  }

  void _handleFieldValidation(ForgotPasswordFormFieldValidated state) {
    setState(() {
      List<String>? errorList;

      if (!state.isValid) {
        if (state.validator != null) {
          // Field has AuthValidation error
          final errorMessage = state.validator?.localizedMessage(context);
          errorList = errorMessage != null ? [errorMessage] : null;
        }
      } else {
        errorList = null;
      }

      // Update the appropriate error list
      switch (state.field) {
        case ForgotPasswordFormField.email:
          _emailErrorList = errorList;
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _emailController.addListener(() {
      BlocProvider.of<ForgotPasswordBloc>(context).add(
        ForgotPasswordFormFieldChanged(
          field: ForgotPasswordFormField.email,
          value: _emailController.text,
        ),
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
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
            _showEmailVerificationQuickSheet(context, _emailController.text);
          } else if (state is ForgotPasswordFailure) {
            _handleFailure(state.failure);
          }
          if (state is ForgotPasswordFormFieldValidated) {
            _handleFieldValidation(state);
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
                AuthHeader(
                  title: '${l10n?.forgotPasswordTitle}',
                  description: '${l10n?.forgotPasswordDescription}',
                ),
                const SizedBox(height: CoreSpacing.space10),
                CoreTextField(
                  focusNode: focusNode,
                  controller: _emailController,
                  label: '${l10n?.emailLabel}',
                  hintText: '${l10n?.emailHint}',
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
                  label: state is ForgotPasswordLoading
                      ? '${l10n?.sendingOtpButton}'
                      : '${l10n?.continueButton}',
                  centerAlign: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtpVerificationSheet(BuildContext callingContext, String email) {
    return BlocProvider.value(
      value: BlocProvider.of<OtpVerificationBloc>(callingContext),
      child: BlocConsumer<OtpVerificationBloc, OtpVerificationState>(
        listener: (context, state) {
          if (state is OtpVerificationSuccess) {
            _router.navigate(fullSetNewPasswordRoute, arguments: email);
          }
          if (state is OtpVerificationFailure) {
            _handleFailure(state.failure);
          }
          if (state is OtpVerificationOtpResendSuccess) {
            CoreToast.showSuccess(
              context,
              l10n?.otpResendSuccess,
              '${l10n?.continueButton}',
            );
          }
          if (state is OtpVerificationResendFailure) {
            _handleFailure(state.failure);
          }
        },
        builder: (context, state) {
          return OtpVerificationQuickSheet(
            note: '${l10n?.otpVerificationNote}',
            contact: email,
            isResending: state is OtpVerificationResendLoading,
            isVerifying: state is OtpVerificationLoading,
            verifyButtonDisabled:
                state is OtpVerificationInitial ||
                (state is OtpVerificationOtpChangeSuccess &&
                    state.otpInvalid) ||
                state is OtpVerificationLoading ||
                state is OtpVerificationResendLoading,
            onResend: () {
              BlocProvider.of<OtpVerificationBloc>(
                callingContext,
              ).add(OtpVerificationResendRequested(contact: email));
            },
            onEdit: () {
              Navigator.pop(context);
              BlocProvider.of<ForgotPasswordBloc>(
                callingContext,
              ).add(ForgotPasswordEditEmailRequested());
              focusNode.requestFocus();
            },
            onVerify: () {
              final otp =
                  state is OtpVerificationOtpChangeSuccess ? state.otp : '';
              BlocProvider.of<OtpVerificationBloc>(
                callingContext,
              ).add(OtpVerificationSubmitted(contact: email, otp: otp));
            },
            onChanged: (otp) {
              BlocProvider.of<OtpVerificationBloc>(
                callingContext,
              ).add(OtpVerificationOtpChanged(otp: otp));
            },
          );
        },
      ),
    );
  }

  void _showEmailVerificationQuickSheet(
    BuildContext callingContext,
    String email,
  ) {
    showModalBottomSheet(
      context: callingContext,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOtpVerificationSheet(callingContext, email),
    );
  }
}
