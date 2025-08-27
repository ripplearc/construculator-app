import 'package:construculator/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_footer.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_header.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_provider_buttons.dart';
import 'package:construculator/features/auth/presentation/widgets/error_widget_builder.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class LoginWithEmailPage extends StatefulWidget {
  final String email;
  const LoginWithEmailPage({super.key, required this.email});

  @override
  State<LoginWithEmailPage> createState() => _LoginWithEmailPageState();
}

class _LoginWithEmailPageState extends State<LoginWithEmailPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _canPressContinue = false;
  List<String>? _emailErrorList;
  List<Widget>? _emailErrorWidgetList;
  AppLocalizations? l10n;
  final AppRouter _router = Modular.get<AppRouter>();

  _getContinueButtonText(LoginWithEmailState state) {
    if (state is LoginWithEmailLoading) {
      return '${l10n?.loggingInButton}';
    }
    if (state is LoginWithEmailAvailabilityLoading) {
      return '${l10n?.checkingAvailabilityButton}';
    }
    return '${l10n?.continueButton}';
  }

  _handleFailure(Failure failure) {
    if (failure is AuthFailure) {
      CoreToast.showError(
        context,
        failure.errorType.localizedMessage(context),
        l10n?.closeLabel ?? '',
      );
    } else {
      CoreToast.showError(
        context,
        l10n?.unexpectedErrorMessage ?? '',
        l10n?.closeLabel ?? '',
      );
    }
  }

  void _handleFieldValidation(LoginWithEmailFormFieldValidated state) {
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
        case LoginWithEmailFormField.email:
          _emailErrorList = errorList;
          break;
      }

      // Validate form after updating errors
      _validateForm();
    });
  }

  void _validateForm() {
    final valid = _emailErrorList == null && _emailController.text.isNotEmpty;
    setState(() {
      _canPressContinue = valid;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _emailController.text = widget.email;

    _emailController.addListener(() {
      BlocProvider.of<LoginWithEmailBloc>(context).add(
        LoginWithEmailFormFieldChanged(
          field: LoginWithEmailFormField.email,
          value: _emailController.text,
        ),
      );
    });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    l10n = AppLocalizations.of(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerTheme: const DividerThemeData(color: Colors.transparent),
      ),
      child: Scaffold(
        backgroundColor: CoreBackgroundColors.pageBackground,
        body: BlocConsumer<LoginWithEmailBloc, LoginWithEmailState>(
          listener: (context, state) {
            if (state is LoginWithEmailFailure) {
              _handleFailure(state.failure);
            }
            if (state is LoginWithEmailAvailabilityCheckFailure) {
              _handleFailure(state.failure);
            }
            if (state is LoginWithEmailAvailabilityCheckSuccess) {
              if (!state.isEmailRegistered) {
                _emailErrorList = null;
                _emailErrorWidgetList = [
                  buildErrorWidgetWithLink(
                    errorText: l10n?.emailNotRegistered,
                    linkText: l10n?.register,
                    onPressed: () {
                      // navitage to the register page with the entered email
                      _router.navigate(
                        fullRegisterRoute,
                        arguments: _emailController.text,
                      );
                    },
                  ),
                ];
              } else {
                _emailErrorList = null;
                _emailErrorWidgetList = null;
              }
              _canPressContinue = state.isEmailRegistered;
            }
            if (state is LoginWithEmailFormFieldValidated) {
              _handleFieldValidation(state);
            }
          },
          builder: (context, state) {
            return _buildLoginWithEmailForm(state);
          },
        ),
        persistentFooterButtons: [
          AuthFooter(
            text: '${l10n?.dontHaveAndAccountText}',
            actionText: '${l10n?.register}',
            onPressed: () {
              _router.navigate(fullRegisterRoute);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginWithEmailForm(LoginWithEmailState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: CoreSpacing.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: CoreSpacing.space20),
            AuthHeader(
              title: '${l10n?.welcomeBack}',
              description: '${l10n?.enterYourEmailIdToLoginToYourAccount}',
            ),
            const SizedBox(height: CoreSpacing.space10),
            CoreTextField(
              controller: _emailController,
              label: '${l10n?.emailLabel}',
              hintText: '${l10n?.emailHint}',
              errorWidgetList: _emailErrorWidgetList,
              errorTextList: _emailErrorList,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: CoreSpacing.space6),
            CoreButton(
              isDisabled:
                  !_canPressContinue ||
                  state is LoginWithEmailAvailabilityLoading,
              onPressed: () {
                _router.pushNamed(
                  fullEnterPasswordRoute,
                  arguments: _emailController.text,
                );
              },
              label: _getContinueButtonText(state),
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
                  padding: EdgeInsets.symmetric(horizontal: CoreSpacing.space2),
                  child: Text(
                    '${l10n?.or}',
                    style: TextStyle(color: CoreTextColors.body),
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
  }
}
