import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/toast/toast.dart';
import 'package:construculator/libraries/widgets/success_modal.dart';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';
import 'package:construculator/features/auth/domain/entities/professional_role.dart';

class CreateAccountPage extends StatefulWidget {
  final String? email;
  final String? phone;

  const CreateAccountPage({super.key, this.email, this.phone});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _phoneFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();

  List<ProfessionalRole> _professionalRolesList = <ProfessionalRole>[];
  ProfessionalRole? _selectedRole;
  String _selectedPhonePrefix = '+1';
  final List<String> _phonePrefixes = ['+1'];

  List<String>? _firstNameErrorList;
  List<String>? _lastNameErrorList;
  String? _roleError;
  List<String>? _mobileNumberErrorList;
  List<String>? _emailErrorList;
  List<String>? _passwordErrorList;
  List<String>? _confirmPasswordErrorList;

  bool _canPressContinue = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  AppLocalizations? l10n;
  final CToast _toast = Modular.get<CToast>();
  final AppRouter _router = Modular.get<AppRouter>();

  bool get isEmailRegistration {
    final email = widget.email;
    if (email != null && email.isNotEmpty) {
      return true;
    }
    return false;
  }

  void _onItemSelectorOpened() {
    // remove focus from any textfield
    FocusManager.instance.primaryFocus?.unfocus();
    _validateRole();
    _validateForm();
  }

  void _validateRole() {
    if (_selectedRole != null) {
      _roleError = null;
    } else {
      _roleError = l10n?.roleRequiredError;
    }
  }

  void _handleFailure(Failure failure) {
    if (failure is AuthFailure) {
      _toast.showError(context, failure.errorType.localizedMessage(context));
    } else {
      _toast.showError(context, l10n?.unexpectedErrorMessage);
    }
  }

  void _openLink(String url) {}

  void _onRoleSelected(String? selectedName) {
    if (selectedName != null) {
      final selectedRole = _professionalRolesList.firstWhere(
        (role) => role.name == selectedName,
      );
      setState(() {
        _selectedRole = selectedRole;
      });
    } else {
      setState(() {
        _selectedRole = null;
      });
    }
    _validateRole();
  }

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

  void _clearForm() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _mobileNumberController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _selectedRole = null;
      _selectedPhonePrefix = '+1';
      _firstNameErrorList = null;
      _lastNameErrorList = null;
      _roleError = null;
      _mobileNumberErrorList = null;
      _emailErrorList = null;
      _passwordErrorList = null;
      _confirmPasswordErrorList = null;
      _canPressContinue = false;
    });
  }

  void _validateForm() {
    final valid =
        _firstNameErrorList == null &&
        _lastNameErrorList == null &&
        _roleError == null &&
        _mobileNumberErrorList == null &&
        _emailErrorList == null &&
        _passwordErrorList == null &&
        _confirmPasswordErrorList == null &&
        _selectedRole != null &&
        _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        (isEmailRegistration
            ? _emailController.text.isNotEmpty
            : _mobileNumberController.text.isNotEmpty);
    setState(() {
      _canPressContinue = valid;
    });
  }

  void _showSuccessModal(BuildContext context) {
    SuccessModal.show(
      context,
      message: l10n?.createAccountSuccessMessage,
      onPressed: () => _router.navigate(dashboardRoute),
    );
  }

  void _onSubmit(BuildContext context) {
    final phone = widget.phone ?? _mobileNumberController.text;
    BlocProvider.of<CreateAccountBloc>(context).add(
      CreateAccountSubmitted(
        email: widget.email ?? _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        role: _selectedRole?.id ?? '',
        phonePrefix: phone.isNotEmpty ? _selectedPhonePrefix : '',
        mobileNumber: phone,
      ),
    );
  }

  @override
  void initState() {
    _emailController.text = widget.email ?? '';
    _mobileNumberController.text = widget.phone ?? '';
    BlocProvider.of<CreateAccountBloc>(
      context,
    ).add(const LoadProfessionalRoles());
    _firstNameController.addListener(() {
      if (_firstNameController.text.isEmpty) {
        setState(() {
          final error = l10n?.firstNameRequired;
          if (error != null) {
            _firstNameErrorList = [error];
          }
        });
      } else {
        setState(() {
          _firstNameErrorList = null;
        });
      }
      _validateForm();
    });
    _lastNameController.addListener(() {
      if (_lastNameController.text.isEmpty) {
        setState(() {
          final error = l10n?.lastNameRequired;
          if (error != null) {
            _lastNameErrorList = [error];
          }
        });
      } else {
        setState(() {
          _lastNameErrorList = null;
        });
      }
      _validateForm();
    });
    _emailController.addListener(() {
      final emailValidator = AuthValidation.validateEmail(
        _emailController.text,
      );
      if (emailValidator != null) {
        setState(() {
          final error = emailValidator.localizedMessage(context);
          if (error != null) {
            _emailErrorList = [error];
          }
        });
      } else {
        setState(() {
          _emailErrorList = null;
        });
      }
      _validateForm();
    });
    _mobileNumberController.addListener(() {
      // phone is optional for email registration
      // do not validate when phone is empty
      if (isEmailRegistration && _mobileNumberController.text.isEmpty) {
        setState(() {
          _mobileNumberErrorList = null;
        });
        return;
      }
      final phoneValidator = AuthValidation.validatePhoneNumber(
        '$_selectedPhonePrefix${_mobileNumberController.text}',
      );
      if (phoneValidator != null) {
        setState(() {
          final error = phoneValidator.localizedMessage(context);
          if (error != null) {
            _mobileNumberErrorList = [error];
          }
        });
      } else {
        setState(() {
          _mobileNumberErrorList = null;
        });
      }
      _validateForm();
    });
    _passwordController.addListener(() {
      final passwordValidator = AuthValidation.validatePassword(
        _passwordController.text,
      );
      if (passwordValidator != null) {
        setState(() {
          final error = passwordValidator.localizedMessage(context);
          if (error != null) {
            _passwordErrorList = [error];
          }
        });
      } else {
        setState(() {
          _passwordErrorList = null;
        });
      }
      _validateForm();
    });
    _confirmPasswordController.addListener(() {
      if (_confirmPasswordController.text.isEmpty) {
        setState(() {
          final error = l10n?.confirmPasswordRequired;
          if (error != null) {
            _confirmPasswordErrorList = [error];
          }
        });
      } else {
        if (_confirmPasswordController.text != _passwordController.text) {
          setState(() {
            final error =
                AppLocalizations.of(context)?.passwordsDoNotMatchError;
            if (error != null) {
              _confirmPasswordErrorList = [error];
            }
          });
        } else {
          setState(() {
            _confirmPasswordErrorList = null;
          });
        }
      }
      _validateForm();
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _toast.dispose();
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
      body: BlocConsumer<CreateAccountBloc, CreateAccountState>(
        listener: (context, state) {
          if (state is CreateAccountSuccess) {
            _clearForm();
            _showSuccessModal(context);
          }
          if (state is CreateAccountFailure) {
            _handleFailure(state.failure);
          }
          if (state is CreateAccountGetProfessionalRolesSuccess) {
            setState(() {
              _professionalRolesList = state.professionalRolesList;
            });
          }
          if (state is CreateAccountGetProfessionalRolesFailure) {
            _handleFailure(state.failure);
          }
          if (state is CreateAccountOtpSendingFailure) {
            _handleFailure(state.failure);
          }
          if (state is CreateAccountOtpVerified) {
            // hide bottomsheet otp from contact verification is verified
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: CoreSpacing.space6),
                  Text(
                    '${l10n?.createAccountTitle}',
                    style: CoreTypography.headlineLargeSemiBold(),
                  ),
                  const SizedBox(height: CoreSpacing.space3),
                  Text(
                    '${l10n?.createAccountSubtitle}',
                    style: CoreTypography.bodyLargeRegular(),
                  ),
                  const SizedBox(height: CoreSpacing.space8),
                  CoreTextField(
                    label: '${l10n?.firstNameLabel}',
                    hintText: '${l10n?.firstNameHint}',
                    controller: _firstNameController,
                    errorTextList: _firstNameErrorList,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  CoreTextField(
                    label: '${l10n?.lastNameLabel}',
                    hintText: '${l10n?.lastNameHint}',
                    controller: _lastNameController,
                    errorTextList: _lastNameErrorList,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  if (state is CreateAccountGetProfessionalRolesLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: CoreIconColors.dark,
                      ),
                    )
                  else if (state is CreateAccountGetProfessionalRolesFailure)
                    Text(
                      '${l10n?.rolesLoadingError}',
                      style: CoreTypography.bodySmallRegular(
                        color: CoreTextColors.error,
                      ),
                    )
                  else
                    SingleItemSelector<String>(
                      labelText: '${l10n?.roleLabel}',
                      hintText: '${l10n?.roleHint}',
                      onOpen: _onItemSelectorOpened,
                      selectedItem: _selectedRole?.name,
                      items:
                          _professionalRolesList
                              .map((role) => role.name)
                              .toList(),
                      onItemSelected: _onRoleSelected,
                      modalTitle: '${l10n?.selectRoleTitle}',
                    ),
                  if (_roleError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: CoreSpacing.space1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: CoreSpacing.space3),
                          const CoreIconWidget(
                            icon: CoreIcons.error,
                            size: 16,
                            color: CoreIconColors.red,
                          ),
                          const SizedBox(width: CoreSpacing.space1),
                          Text(
                            '$_roleError',
                            style: CoreTypography.bodySmallRegular(
                              color: CoreTextColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: CoreSpacing.space6),
                  CoreTextField(
                    label: '${l10n?.emailLabel}',
                    hintText: '${l10n?.emailHint}',
                    enabled: false,
                    readOnly: true,
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    errorTextList: _emailErrorList,
                    suffix: const CoreIconWidget(
                      icon: CoreIcons.checkCircle,
                      color: CoreIconColors.green,
                    ),
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  CoreTextField(
                    label: '${l10n?.mobileNumberLabel}',
                    hintText: '${l10n?.mobileNumberHint}',
                    controller: _mobileNumberController,
                    focusNode: _phoneFocusNode,
                    isPhoneNumber: true,
                    phonePrefixes: _phonePrefixes,
                    countryCodePickerTitle:
                        AppLocalizations.of(context)?.selectCountryCode,
                    phonePrefix: _selectedPhonePrefix,
                    onPhonePrefixChanged: (prefix) {
                      if (prefix != null) {
                        setState(() {
                          _selectedPhonePrefix = prefix;
                        });
                      }
                    },
                    errorTextList: _mobileNumberErrorList,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  CoreTextField(
                    label: '${l10n?.passwordLabel}',
                    hintText: '${l10n?.passwordHint}',
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    suffix: IconButton(
                      icon: CoreIconWidget(
                        icon:
                            _isPasswordVisible
                                ? CoreIcons.eye
                                : CoreIcons.eyeOff,
                        size: CoreSpacing.space6,
                        color: CoreTextColors.dark,
                      ),
                      onPressed: () => _togglePasswordVisibility(),
                    ),
                    errorTextList: _passwordErrorList,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  CoreTextField(
                    label: '${l10n?.confirmPasswordLabel}',
                    hintText: '${l10n?.confirmPasswordHint}',
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    suffix: IconButton(
                      icon: CoreIconWidget(
                        icon:
                            _isConfirmPasswordVisible
                                ? CoreIcons.eye
                                : CoreIcons.eyeOff,
                        size: CoreSpacing.space6,
                        color: CoreTextColors.dark,
                      ),
                      onPressed: () => _toggleConfirmPasswordVisibility(),
                    ),
                    errorTextList: _confirmPasswordErrorList,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  Text.rich(
                    TextSpan(
                      text: '${l10n?.termsAndConditionsText}',
                      style: CoreTypography.bodyMediumRegular(
                        color: CoreTextColors.headline,
                      ),
                      children: [
                        WidgetSpan(
                          child: InkWell(
                            onTap: () => _openLink(''),
                            child: Text(
                              '${l10n?.termsAndServicesLink}',
                              style: CoreTypography.bodyMediumMedium(
                                color: CoreTextColors.link,
                              ).copyWith(decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                        TextSpan(text: ' ${l10n?.andAcknowledge} '),
                        WidgetSpan(
                          child: InkWell(
                            onTap: () => _openLink(''),
                            child: Text(
                              '${l10n?.privacyPolicyLink}',
                              style: CoreTypography.bodyMediumMedium(
                                color: CoreTextColors.link,
                              ).copyWith(decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CoreButton(
                    centerAlign: true,
                    isDisabled:
                        !_canPressContinue || state is CreateAccountLoading,
                    onPressed: () {
                      _onSubmit(context);
                    },
                    label:
                        state is CreateAccountLoading
                            ? '${l10n?.creatingAccountButton}'
                            : '${l10n?.agreeAndContinueButton}',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
