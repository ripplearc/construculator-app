import 'package:construculator/features/auth/presentation/widgets/error_widget_builder.dart';
import 'package:construculator/features/auth/presentation/bloc/otp_verification_bloc/otp_verification_bloc.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_footer.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_methods.dart';
import 'package:construculator/features/auth/presentation/widgets/otp_verification_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:core_ui/core_ui.dart';
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

class _RegisterWithEmailPageState extends State<RegisterWithEmailPage> {
  final _emailController = TextEditingController();
  final _emailTextFieldFocusNode = FocusNode();

  List<Widget>? _emailErrorWidgetList;
  List<String>? _emailErrorTextList;

  bool _canPressContinue = false;
  AppLocalizations? l10n;
  final AppRouter _router = Modular.get<AppRouter>();

  void _handleFailure(Failure failure) {
    if (failure is AuthFailure) {
      if (failure.errorType == AuthErrorType.rateLimited) {
        CoreToast.showError(context, l10n?.tooManyAttempts);
      } else {
        CoreToast.showError(context, failure.errorType.localizedMessage(context));
      }
    } else {
      CoreToast.showError(context, l10n?.unexpectedErrorMessage);
    }
  }

  void _showEmailVerificationBottomSheet(
    BuildContext callingContext,
    String email,
  ) {
    String otp = '';
    bool otpInvalid = true;
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
                final otpValidator = AuthValidation.validateOtp(otp);
                otpInvalid = otpValidator != null;
              }
              if (state is OtpVerificationSuccess) {
                _router.navigate(fullCreateAccountRoute, arguments: email);
              }
              if (state is OtpVerificationFailure) {
                _handleFailure(state.failure);
              }
              if (state is OtpVerificationOtpResent) {
                CoreToast.showSuccess(context, l10n?.otpResendSuccess);
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
                    otpInvalid ||
                    state is OtpVerificationLoading ||
                    state is OtpVerificationResendLoading,
                onResend: () {
                  BlocProvider.of<OtpVerificationBloc>(
                    context,
                  ).add(OtpVerificationResendRequested(contact: email));
                },
                onEdit: () {
                  BlocProvider.of<RegisterWithEmailBloc>(
                    callingContext,
                  ).add(RegisterWithEmailEditEmail());
                },
                onVerify: () {
                  BlocProvider.of<OtpVerificationBloc>(
                    context,
                  ).add(OtpVerificationSubmitted(contact: email, otp: otp));
                },
                onChanged: (otp) {
                    BlocProvider.of<OtpVerificationBloc>(
                      context,
                    ).add(OtpVerificationOtpChanged(otp: otp));
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    _emailController.addListener(() {
      final email = _emailController.text;
      final emailValidator = AuthValidation.validateEmail(email);
      if (emailValidator != null) {
        final error = emailValidator.localizedMessage(context);
        setState(() {
          _emailErrorWidgetList = null;
          if (error != null) {
            _emailErrorTextList = [error];
          }
        });
      } else {
        setState(() {
          _emailErrorWidgetList = null;
          _emailErrorTextList = null;
        });
        BlocProvider.of<RegisterWithEmailBloc>(
          context,
        ).add(RegisterWithEmailEmailChanged(email));
      }
    });
    _emailController.text = widget.email;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    l10n = AppLocalizations.of(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _emailTextFieldFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerTheme: const DividerThemeData(color: Colors.transparent),
      ),
      child: Scaffold(
        backgroundColor: CoreBackgroundColors.pageBackground,
        body: BlocConsumer<RegisterWithEmailBloc, RegisterWithEmailState>(
          listener: (context, state) {
            if (state is RegisterWithEmailEmailCheckSuccess) {
              if (state.isEmailRegistered) {
                _emailErrorTextList = null;
                _emailErrorWidgetList = [
                  buildErrorWidget(
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
          },
          builder: (context, state) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: CoreSpacing.space6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: CoreSpacing.space20),
                    Text(
                      '${l10n?.letsGetStarted}',
                      style: CoreTypography.headlineLargeSemiBold(),
                    ),
                    const SizedBox(height: CoreSpacing.space4),
                    Text(
                      '${l10n?.heyEnterYourDetailsToRegisterWithUs}',
                      style: CoreTypography.bodyLargeRegular(),
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
                      label:
                          state is RegisterWithEmailOtpSendingLoading
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
                          child: Divider(color: CoreBorderColors.lineLight, thickness: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: CoreSpacing.space2,
                          ),
                          child: Text(
                            '${l10n?.or}',
                            style: TextStyle(color: CoreTextColors.body),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: CoreBorderColors.lineLight, thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: CoreSpacing.space6),
                    AuthMethods(onPressed: (method) {}),
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
