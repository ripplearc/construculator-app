import 'package:construculator/features/auth/presentation/bloc/login_with_email_bloc/login_with_email_bloc.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_footer.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_methods.dart';
import 'package:construculator/features/auth/presentation/widgets/error_widget_builder.dart';
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
  final CToast _toast = Modular.get<CToast>();
  final AppRouter _router = Modular.get<AppRouter>();

  _handleFailure(Failure failure) {
    if (failure is AuthFailure) {
      _toast.showError(context, failure.errorType.localizedMessage(context));
    } else {
      _toast.showError(context, l10n?.unexpectedErrorMessage);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
    _toast.dispose();
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
            _emailErrorList = [error];
          }
        });
      } else {
        setState(() {
          _emailErrorWidgetList = null;
          _emailErrorList = null;
        });
        BlocProvider.of<LoginWithEmailBloc>(
          context,
        ).add(LoginEmailChanged(email));
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
            if (state is LoginWithEmailAvailabilityFailure) {
              _handleFailure(state.failure);
            }
            if (state is LoginWithEmailAvailabilitySuccess) {
              if (!state.isEmailRegistered) {
                _emailErrorList = null;
                _emailErrorWidgetList = [
                  buildErrorWidget(
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
                      '${l10n?.welcomeBack}',
                      style: CoreTypography.headlineLargeSemiBold(),
                    ),
                    const SizedBox(height: CoreSpacing.space4),
                    Text(
                      '${l10n?.enterYourEmailIdToLoginToYourAccount}',
                      style: CoreTypography.bodyLargeRegular(),
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
                      isDisabled: !_canPressContinue || state is LoginWithEmailAvailabilityLoading,
                      onPressed: () {
                        _router.pushNamed(
                          fullEnterPasswordRoute,
                          arguments: _emailController.text,
                        );
                      },
                      label:
                          state is LoginWithEmailLoading
                              ? '${l10n?.loggingInButton}'
                              : state is LoginWithEmailAvailabilityLoading
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
}
