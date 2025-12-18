import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_footer.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_header.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_provider_buttons.dart';
import 'package:construculator/features/auth/presentation/widgets/error_widget_builder.dart';
import 'package:construculator/features/auth/presentation/widgets/otp_quick_sheet/otp_verification_sheet.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/mixins/localization_mixin.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:construculator/features/auth/presentation/bloc/register_with_email_bloc/register_with_email_bloc.dart';

class RegisterWithEmailPage extends StatefulWidget {
  final String email;
  const RegisterWithEmailPage({super.key, required this.email});

  @override
  State<RegisterWithEmailPage> createState() => _RegisterWithEmailPageState();
}

class _RegisterWithEmailPageState extends State<RegisterWithEmailPage>
    with LocalizationMixin {
  final _emailController = TextEditingController();
  final _emailTextFieldFocusNode = FocusNode();

  List<Widget>? _emailErrorWidgetList;
  List<String>? _emailErrorTextList;

  bool _canPressContinue = false;
  final AppRouter _router = Modular.get<AppRouter>();

  void _handleFailure(Failure failure) {
    if (failure is AuthFailure) {
      if (failure.errorType == AuthErrorType.rateLimited) {
        CoreToast.showError(
          context,
          l10n?.tooManyAttempts,
          l10n?.closeLabel ?? '',
        );
      } else {
        CoreToast.showError(
          context,
          failure.errorType.localizedMessage(context),
          l10n?.closeLabel ?? '',
        );
      }
    } else {
      CoreToast.showError(
        context,
        l10n?.unexpectedErrorMessage,
        l10n?.closeLabel ?? '',
      );
    }
  }

  void _handleFieldValidation(RegisterWithEmailFormFieldValidated state) {
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
        case RegisterWithEmailFormField.email:
          _emailErrorTextList = errorList;
          break;
      }

      // Validate form after updating errors
      _validateForm();
    });
  }

  void _validateForm() {
    final valid =
        _emailErrorTextList == null && _emailController.text.isNotEmpty;
    setState(() {
      _canPressContinue = valid;
    });
  }

  Widget _buildOtpVerificationBottomSheet(
    BuildContext callingContext,
    String email,
  ) {
    return BlocProvider.value(
      value: BlocProvider.of<OtpVerificationBloc>(callingContext),
      child: BlocConsumer<OtpVerificationBloc, OtpVerificationState>(
        listener: (context, state) {
          if (state is OtpVerificationSuccess) {
            _router.navigate(fullCreateAccountRoute, arguments: email);
          }
          if (state is OtpVerificationFailure) {
            _handleFailure(state.failure);
          }
          if (state is OtpVerificationOtpResendSuccess) {
            CoreToast.showSuccess(
              context,
              l10n?.otpResendSuccess,
              l10n?.closeLabel ?? '',
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
              BlocProvider.of<RegisterWithEmailBloc>(
                callingContext,
              ).add(RegisterWithEmailEmailEditRequested());
            },
            onVerify: () {
              final otp = state is OtpVerificationOtpChangeSuccess
                  ? state.otp
                  : '';
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

  void _showEmailVerificationBottomSheet(
    BuildContext callingContext,
    String email,
  ) {
    showModalBottomSheet(
      context: callingContext,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _buildOtpVerificationBottomSheet(callingContext, email);
      },
    );
  }

  @override
  void initState() {
    _emailController.addListener(() {
      BlocProvider.of<RegisterWithEmailBloc>(context).add(
        RegisterWithEmailFormFieldChanged(
          field: RegisterWithEmailFormField.email,
          value: _emailController.text,
        ),
      );
    });
    _emailController.text = widget.email;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _emailTextFieldFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<TypographyExtension>();

    return Theme(
      data: Theme.of(context).copyWith(
        dividerTheme: const DividerThemeData(color: Colors.transparent),
      ),
      child: Scaffold(
        backgroundColor: CoreBackgroundColors.pageBackground,
        body: BlocConsumer<RegisterWithEmailBloc, RegisterWithEmailState>(
          listener: (context, state) {
            if (state is RegisterWithEmailEmailCheckCompleted) {
              if (state.isEmailRegistered) {
                _emailErrorTextList = null;
                _emailErrorWidgetList = [
                  buildErrorWidgetWithLink(
                    context: context,
                    errorText: l10n?.emailAlreadyRegistered,
                    linkText: l10n?.logginLink,
                    onPressed: () {
                      // navigate to the login page with the currently entered email
                      _router.navigate(
                        fullLoginRoute,
                        arguments: _emailController.text,
                      );
                    },
                  ),
                ];
              }
              _canPressContinue = !state.isEmailRegistered;
            }
            if (state is RegisterWithEmailEmailCheckFailure) {
              _handleFailure(state.failure);
            }
            if (state is RegisterWithEmailOtpSendingSuccess) {
              _showEmailVerificationBottomSheet(context, _emailController.text);
            }
            if (state is RegisterWithEmailOtpSendingFailure) {
              _handleFailure(state.failure);
            }
            if (state is RegisterWithEmailEditUserEmail) {
              // when edit email is triggered on otp bottom sheet
              // close bottomsheet and focus on the email input
              Navigator.pop(context);
              _emailTextFieldFocusNode.requestFocus();
            }
            if (state is RegisterWithEmailFormFieldValidated) {
              _handleFieldValidation(state);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: CoreSpacing.space6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: CoreSpacing.space20),
                    AuthHeader(
                      title: '${l10n?.letsGetStarted}',
                      description:
                          '${l10n?.heyEnterYourDetailsToRegisterWithUs}',
                    ),
                    const SizedBox(height: CoreSpacing.space10),
                    CoreTextField(
                      focusNode: _emailTextFieldFocusNode,
                      controller: _emailController,
                      label: '${l10n?.emailLabel}',
                      hintText: '${l10n?.emailHint}',
                      errorTextList: _emailErrorTextList,
                      errorWidgetList: _emailErrorWidgetList,
                    ),
                    const SizedBox(height: CoreSpacing.space6),
                    CoreButton(
                      onPressed: () {
                        _emailTextFieldFocusNode.unfocus();
                        BlocProvider.of<RegisterWithEmailBloc>(context).add(
                          RegisterWithEmailContinuePressed(
                            _emailController.text,
                          ),
                        );
                      },
                      isDisabled:
                          !_canPressContinue ||
                          state is RegisterWithEmailOtpSendingLoading ||
                          state is RegisterWithEmailEmailCheckLoading,
                      label: state is RegisterWithEmailOtpSendingLoading
                          ? '${l10n?.sendingOtpButton}'
                          : state is RegisterWithEmailEmailCheckLoading
                          ? '${l10n?.checkingAvailabilityButton}'
                          : '${l10n?.continueButton}',
                      centerAlign: true,
                    ),
                    const SizedBox(height: CoreSpacing.space6),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: CoreBorderColors.lineLight,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: CoreSpacing.space2,
                          ),
                          child: Text(
                            '${l10n?.or}',
                            style: typography?.bodyMediumRegular.copyWith(
                              color: CoreTextColors.body,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: CoreBorderColors.lineLight,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CoreSpacing.space6),
                    AuthProviderButtons(onPressed: (method) {}),
                  ],
                ),
              ),
            );
          },
        ),
        persistentFooterButtons: [
          AuthFooter(
            text: '${l10n?.alreadyHaveAccount}',
            actionText: '${l10n?.logginLink}',
            onPressed: () {
              _router.navigate(fullLoginRoute);
            },
          ),
        ],
      ),
    );
  }
}
