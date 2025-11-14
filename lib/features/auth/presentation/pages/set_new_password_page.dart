import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/mixins/localization_mixin.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/presentation/bloc/set_new_password_bloc/set_new_password_bloc.dart';

class SetNewPasswordPage extends StatefulWidget {
  final String email;
  const SetNewPasswordPage({super.key, required this.email});

  @override
  State<SetNewPasswordPage> createState() => _SetNewPasswordPageState();
}

class _SetNewPasswordPageState extends State<SetNewPasswordPage>
    with LocalizationMixin {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<String>? _passwordErrorList;
  List<String>? _confirmPasswordErrorList;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final AppRouter _router = Modular.get<AppRouter>();

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _handlePasswordValidation(
    SetNewPasswordPasswordValidationSuccess state,
  ) {
    setState(() {
      List<String>? errorList;

      if (!state.isValid) {
        if (state.validator != null) {
          final errorMessage = state.validator?.localizedMessage(context);
          errorList = errorMessage != null ? [errorMessage] : null;
        }
      } else {
        errorList = null;
      }
      switch (state.field) {
        case SetNewPasswordFormField.password:
          _passwordErrorList = errorList;
          break;
        case SetNewPasswordFormField.passwordConfirmation:
          _confirmPasswordErrorList = errorList;
          break;
      }
    });
  }

  void _onSubmit(BuildContext context) {
    BlocProvider.of<SetNewPasswordBloc>(context).add(
      SetNewPasswordSubmitted(
        email: widget.email,
        password: _passwordController.text,
      ),
    );
  }

  @override
  void initState() {
    _passwordController.addListener(() {
      BlocProvider.of<SetNewPasswordBloc>(context).add(
        SetNewPasswordPasswordValidationRequested(
          field: SetNewPasswordFormField.password,
          value: _passwordController.text,
        ),
      );
    });

    _confirmPasswordController.addListener(() {
      BlocProvider.of<SetNewPasswordBloc>(context).add(
        SetNewPasswordPasswordValidationRequested(
          field: SetNewPasswordFormField.passwordConfirmation,
          value: _confirmPasswordController.text,
          passwordValue: _passwordController.text,
        ),
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreBackgroundColors.pageBackground,
      appBar: AppBar(
        backgroundColor: CoreBackgroundColors.pageBackground,
        elevation: 0,
      ),
      body: BlocConsumer<SetNewPasswordBloc, SetNewPasswordState>(
        listener: (context, state) {
          if (state is SetNewPasswordPasswordValidationSuccess) {
            _handlePasswordValidation(state);
          }
          if (state is SetNewPasswordFailure) {
            final failure = state.failure;
            if (failure is AuthFailure) {
              CoreToast.showError(
                context,
                failure.errorType.localizedMessage(context),
                '${l10n?.closeLabel}',
              );
            } else {
              CoreToast.showError(
                context,
                l10n?.unexpectedErrorMessage,
                '${l10n?.closeLabel}',
              );
            }
          }
          if (state is SetNewPasswordSuccess) {
            SuccessModal.show(
              context,
              message: '${l10n?.passwordResetSuccessMessage}',
              onPressed: () => _router.navigate(dashboardRoute),
              buttonLabel: '${l10n?.continueButton}',
            );
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
                  '${l10n?.setNewPasswordTitle}',
                  style: CoreTypography.headlineLargeSemiBold(),
                ),
                const SizedBox(height: CoreSpacing.space2),
                Text(
                  '${l10n?.setNewPasswordDescription}',
                  style: CoreTypography.bodyLargeRegular().copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: CoreSpacing.space4),
                CoreTextField(
                  controller: _passwordController,
                  label: '${l10n?.newPasswordLabel}',
                  hintText: '${l10n?.newPasswordHint}',
                  obscureText: !_isPasswordVisible,
                  errorTextList: _passwordErrorList,
                  suffix: IconButton(
                    icon: CoreIconWidget(
                      icon: _isPasswordVisible
                          ? CoreIcons.eye
                          : CoreIcons.eyeOff,
                    ),
                    onPressed: () {
                      _togglePasswordVisibility();
                    },
                  ),
                ),
                const SizedBox(height: CoreSpacing.space6),
                CoreTextField(
                  controller: _confirmPasswordController,
                  label: '${l10n?.confirmPasswordLabel}',
                  hintText: '${l10n?.confirmPasswordHint}',
                  obscureText: !_isConfirmPasswordVisible,
                  errorTextList: _confirmPasswordErrorList,
                  suffix: IconButton(
                    icon: CoreIconWidget(
                      icon: _isConfirmPasswordVisible
                          ? CoreIcons.eye
                          : CoreIcons.eyeOff,
                    ),
                    onPressed: () {
                      _toggleConfirmPasswordVisibility();
                    },
                  ),
                ),
                const SizedBox(height: CoreSpacing.space6),
                CoreButton(
                  onPressed: () => _onSubmit(context),
                  isDisabled:
                      _passwordController.text.isEmpty ||
                      _passwordController.text !=
                          _confirmPasswordController.text ||
                      state is SetNewPasswordLoading,
                  label: state is SetNewPasswordLoading
                      ? '${l10n?.settingPasswordButton}'
                      : '${l10n?.setPasswordButton}',
                  centerAlign: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
