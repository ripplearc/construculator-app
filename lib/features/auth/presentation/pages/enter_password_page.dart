import 'package:construculator/features/auth/presentation/widgets/auth_header.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/mixins/localization_mixin.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/presentation/bloc/enter_password_bloc/enter_password_bloc.dart';

class EnterPasswordPage extends StatefulWidget {
  final String email;

  const EnterPasswordPage({super.key, required this.email});

  @override
  State<EnterPasswordPage> createState() => _EnterPasswordPageState();
}

class _EnterPasswordPageState extends State<EnterPasswordPage>
    with LocalizationMixin {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _canPressContinue = false;
  List<String>? _passwordErrorList;
  final AppRouter _router = Modular.get<AppRouter>();

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  void initState() {
    _passwordController.addListener(() {
      setState(() {
        _canPressContinue = _passwordController.text.isNotEmpty;
        _passwordErrorList = _passwordController.text.isEmpty
            ? [l10n?.passwordRequiredError ?? '']
            : null;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginButtonPressed(BuildContext context) {
    BlocProvider.of<EnterPasswordBloc>(context).add(
      EnterPasswordSubmitted(
        email: widget.email,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreBackgroundColors.pageBackground,
      appBar: AppBar(
        backgroundColor: CoreBackgroundColors.pageBackground,
        elevation: 0,
      ),
      body: BlocConsumer<EnterPasswordBloc, EnterPasswordState>(
        listener: (context, state) {
          if (state is EnterPasswordSubmitFailure) {
            final failure = state.failure;
            if (failure is AuthFailure) {
              CoreToast.showError(
                context,
                failure.errorType.localizedMessage(context),
                '${l10n?.continueButton}',
              );
            } else {
              CoreToast.showError(
                context,
                l10n?.unexpectedErrorMessage,
                '${l10n?.continueButton}',
              );
            }
          }
          if (state is EnterPasswordSubmitSuccess) {
            _passwordController.clear();
            _passwordErrorList = null;
            SuccessModal.show(
              context,
              message: '${l10n?.loginSuccessMessage}',
              onPressed: () {
                _router.navigate(dashboardRoute);
              },
              buttonLabel: '${l10n?.continueButton}',
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ListView(
              children: [
                const SizedBox(height: 16),
                AuthHeader(
                  title: '${l10n?.enterPasswordTitle}',
                  description: '${l10n?.enterPasswordDescription}',
                  contact: widget.email,
                  onContactPressed: () => _router.pop(),
                ),
                const SizedBox(height: 24),
                CoreTextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  label: '${l10n?.passwordLabel}',
                  hintText: '${l10n?.passwordHint}',
                  suffix: IconButton(
                    icon: CoreIconWidget(
                      icon: _isPasswordVisible
                          ? CoreIcons.eye
                          : CoreIcons.eyeOff,
                      size: CoreSpacing.space6,
                      color: CoreTextColors.dark,
                    ),
                    onPressed: () => _togglePasswordVisibility(),
                  ),
                  errorTextList: _passwordErrorList,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _router.pushNamed(fullForgotPasswordRoute);
                    },
                    child: Text(
                      '${l10n?.forgotPasswordTitle}',
                      style: CoreTypography.bodyLargeSemiBold(
                        color: CoreTextColors.link,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CoreButton(
                  onPressed: () => _onLoginButtonPressed(context),
                  isDisabled:
                      !_canPressContinue || state is EnterPasswordSubmitLoading,
                  centerAlign: true,
                  label: state is EnterPasswordSubmitLoading
                      ? '${l10n?.loggingInButton}'
                      : '${l10n?.continueButton}',
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
