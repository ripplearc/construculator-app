import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/toast/toast.dart';
import 'package:construculator/libraries/widgets/success_modal.dart';
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

class _EnterPasswordPageState extends State<EnterPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _canPressContinue = false;
  List<String>? _passwordErrorList;
  AppLocalizations? l10n;
  final CToast _toast = Modular.get<CToast>();
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
        _passwordErrorList =
            _passwordController.text.isEmpty
                ? [l10n?.passwordRequiredError ?? '']
                : null;
      });
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
    _toast.dispose();
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
              _toast.showError(
                context,
                failure.errorType.localizedMessage(context),
              );
            } else {
              _toast.showError(context, l10n?.unexpectedErrorMessage);
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
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ListView(
              children: [
                const SizedBox(height: 16),
                Text(
                  '${l10n?.enterPasswordTitle}',
                  style: CoreTypography.headlineLargeSemiBold(),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily:
                          Theme.of(context).textTheme.bodyLarge?.fontFamily,
                    ),
                    children: [
                      TextSpan(
                        text: '${l10n?.enterPasswordDescription} ',
                        style: CoreTypography.bodyLargeRegular(),
                      ),
                      WidgetSpan(
                        child: InkWell(
                          key: Key('edit_link'),
                          onTap: () {
                            _router.pop();
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.email,
                                style: CoreTypography.bodyLargeSemiBold(
                                  color: CoreTextColors.link,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(left: 4.0),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: CoreTextColors.link,
                                ),
                              ),
                            ],
                          ),
                        ),
                        alignment: PlaceholderAlignment.middle
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CoreTextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  label: '${l10n?.passwordLabel}',
                  hintText: '${l10n?.passwordHint}',
                  suffix: IconButton(
                    icon: CoreIconWidget(
                      icon:
                          _isPasswordVisible ? CoreIcons.eye : CoreIcons.eyeOff,
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
                  label:
                      state is EnterPasswordSubmitLoading
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
