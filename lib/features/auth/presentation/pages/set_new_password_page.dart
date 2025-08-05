import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';  
import 'package:core_ui/core_ui.dart';
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

class _SetNewPasswordPageState extends State<SetNewPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<String>? _passwordErrorList;
  List<String>? _confirmPasswordErrorList;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  AppLocalizations? l10n;
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

  @override
  void initState() {
    _passwordController.addListener(() {
      final passwordValidationResult = AuthValidation.validatePassword(
        _passwordController.text,
      );
      if (passwordValidationResult != null) {
        setState(() {
          final error = passwordValidationResult.localizedMessage(context);
          if (error != null) {
            setState(() {
              _passwordErrorList = [error];
            });
          }
        });
      } else {
        setState(() {
          _passwordErrorList = null;
        });
      }
    });
    _confirmPasswordController.addListener(() {
      final confirmPasswordValidationResult = AuthValidation.validatePassword(
        _confirmPasswordController.text,
      );
      if (confirmPasswordValidationResult != null) {
        setState(() {
          final error = confirmPasswordValidationResult.localizedMessage(
            context,
          );
          if (error != null) {
            setState(() {
              _confirmPasswordErrorList = [error];
            });
          }
        });
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            final error =
                AppLocalizations.of(context)?.passwordsDoNotMatchError;
            if (error != null) {
              setState(() {
                _confirmPasswordErrorList = [error];
              });
            }
          });
        } else {
          setState(() {
            _confirmPasswordErrorList = null;
          });
        }
      }
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    l10n = AppLocalizations.of(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoreBackgroundColors.pageBackground,
      appBar: AppBar(
        backgroundColor: CoreBackgroundColors.pageBackground,
        elevation: 0,
      ),
      body: BlocConsumer<SetNewPasswordBloc, SetNewPasswordState>(
        listener: (context, state) {
          if (state is SetNewPasswordFailure) {
            final failure = state.failure;
            if (failure is AuthFailure) {
              CoreToast.showError(
                context,
                failure.errorType.localizedMessage(context),
              );
            } else {
              CoreToast.showError(context, l10n?.unexpectedErrorMessage);
            }
          }
          if (state is SetNewPasswordSuccess) {
            _confirmPasswordController.clear();
            _passwordController.clear();
            _confirmPasswordErrorList = null;
            _passwordErrorList = null;
            SuccessModal.show(
              context,
              message: '${l10n?.passwordResetSuccessMessage}',
              onPressed: () => _router.navigate(dashboardRoute),
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
                      icon:
                          _isPasswordVisible ? CoreIcons.eye : CoreIcons.eyeOff,
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
                      icon:
                          _isConfirmPasswordVisible
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
                      _confirmPasswordController.text.isEmpty ||
                      _passwordController.text !=
                          _confirmPasswordController.text ||
                      state is SetNewPasswordLoading,
                  label:
                      state is SetNewPasswordLoading
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
