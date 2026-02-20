import 'package:construculator/features/auth/presentation/extensions/auth_error_type_extension.dart';
import 'package:construculator/features/auth/presentation/widgets/auth_header.dart';
import 'package:construculator/features/auth/presentation/widgets/terms_and_conditions_section.dart';
import 'package:construculator/libraries/auth/data/models/professional_role.dart';

import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/dashboard_routes.dart';
import 'package:construculator/libraries/ui/core_icon_sizes.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:construculator/features/auth/presentation/bloc/create_account_bloc/create_account_bloc.dart';

const usCountryCode = '+1';

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
  String _selectedPhonePrefix = usCountryCode;
  final List<String> _phonePrefixes = [usCountryCode];

  List<String>? _firstNameErrorList;
  List<String>? _lastNameErrorList;
  List<String>? _roleErrorList;
  List<String>? _mobileNumberErrorList;
  List<String>? _emailErrorList;
  List<String>? _passwordErrorList;
  List<String>? _confirmPasswordErrorList;

  bool _canPressContinue = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final AppRouter _router = Modular.get<AppRouter>();

  bool get isEmailRegistration {
    final email = widget.email;
    if (email != null && email.isNotEmpty) {
      return true;
    }
    return false;
  }

  void _onItemSelectorOpened() {
    FocusManager.instance.primaryFocus?.unfocus();
    BlocProvider.of<CreateAccountBloc>(context).add(
      CreateAccountFormFieldChanged(
        field: CreateAccountFormField.role,
        value: _selectedRole?.name ?? '',
        isEmailRegistration: isEmailRegistration,
      ),
    );
  }

  void _handleFailure(Failure failure) {
    final l10n = context.l10n;
    if (failure is AuthFailure) {
      CoreToast.showError(
        context,
        failure.errorType.localizedMessage(context),
        l10n.closeLabel,
      );
    } else {
      CoreToast.showError(
        context,
        l10n.unexpectedErrorMessage,
        l10n.closeLabel,
      );
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

    // Validate role using bloc
    BlocProvider.of<CreateAccountBloc>(context).add(
      CreateAccountFormFieldChanged(
        field: CreateAccountFormField.role,
        value: selectedName ?? '',
        isEmailRegistration: isEmailRegistration,
      ),
    );
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
      _selectedPhonePrefix = usCountryCode;
      _firstNameErrorList = null;
      _lastNameErrorList = null;
      _roleErrorList = null;
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
        _roleErrorList == null &&
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
    final l10n = context.l10n;
    SuccessModal.show(
      context,
      message: l10n.createAccountSuccessMessage,
      buttonLabel: l10n.continueButton,
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

  void _handleFieldValidation(CreateAccountFormFieldValidated state) {
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

      // Update the appropriate error list
      switch (state.field) {
        case CreateAccountFormField.firstName:
          _firstNameErrorList = errorList;
          break;
        case CreateAccountFormField.lastName:
          _lastNameErrorList = errorList;
          break;
        case CreateAccountFormField.role:
          _roleErrorList = errorList;
          break;
        case CreateAccountFormField.mobileNumber:
          _mobileNumberErrorList = errorList;
          break;
        case CreateAccountFormField.email:
          _emailErrorList = errorList;
          break;
        case CreateAccountFormField.password:
          _passwordErrorList = errorList;
          break;
        case CreateAccountFormField.confirmPassword:
          _confirmPasswordErrorList = errorList;
          break;
      }

      // Validate form after updating errors
      _validateForm();
    });
  }

  @override
  void initState() {
    _emailController.text = widget.email ?? '';
    _mobileNumberController.text = widget.phone ?? '';
    BlocProvider.of<CreateAccountBloc>(
      context,
    ).add(const CreateAccountGetProfessionalRolesRequested());

    _firstNameController.addListener(() {
      BlocProvider.of<CreateAccountBloc>(context).add(
        CreateAccountFormFieldChanged(
          field: CreateAccountFormField.firstName,
          value: _firstNameController.text,
          isEmailRegistration: isEmailRegistration,
        ),
      );
    });

    _lastNameController.addListener(() {
      BlocProvider.of<CreateAccountBloc>(context).add(
        CreateAccountFormFieldChanged(
          field: CreateAccountFormField.lastName,
          value: _lastNameController.text,
          isEmailRegistration: isEmailRegistration,
        ),
      );
    });

    _emailController.addListener(() {
      BlocProvider.of<CreateAccountBloc>(context).add(
        CreateAccountFormFieldChanged(
          field: CreateAccountFormField.email,
          value: _emailController.text,
          isEmailRegistration: isEmailRegistration,
        ),
      );
    });

    _mobileNumberController.addListener(() {
      BlocProvider.of<CreateAccountBloc>(context).add(
        CreateAccountFormFieldChanged(
          field: CreateAccountFormField.mobileNumber,
          value: _mobileNumberController.text,
          isEmailRegistration: isEmailRegistration,
          phonePrefix: _selectedPhonePrefix,
        ),
      );
    });

    _passwordController.addListener(() {
      BlocProvider.of<CreateAccountBloc>(context).add(
        CreateAccountFormFieldChanged(
          field: CreateAccountFormField.password,
          value: _passwordController.text,
          isEmailRegistration: isEmailRegistration,
        ),
      );
    });

    _confirmPasswordController.addListener(() {
      BlocProvider.of<CreateAccountBloc>(context).add(
        CreateAccountFormFieldChanged(
          field: CreateAccountFormField.confirmPassword,
          value: _confirmPasswordController.text,
          isEmailRegistration: isEmailRegistration,
          passwordValue: _passwordController.text,
        ),
      );
    });

    super.initState();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      appBar: AppBar(backgroundColor: colors.pageBackground, elevation: 0),
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
          if (state is CreateAccountFormFieldValidated) {
            _handleFieldValidation(state);
          }
        },
        builder: (context, state) {
          final typography = context.textTheme;
          final l10n = context.l10n;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: CoreSpacing.space6),
                  AuthHeader(
                    title: l10n.createAccountTitle,
                    description: l10n.createAccountSubtitle,
                  ),
                  const SizedBox(height: CoreSpacing.space8),
                  CoreTextField(
                    label: l10n.firstNameLabel,
                    hintText: l10n.firstNameHint,
                    controller: _firstNameController,
                    errorTextList: _firstNameErrorList,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  CoreTextField(
                    label: l10n.lastNameLabel,
                    hintText: l10n.lastNameHint,
                    controller: _lastNameController,
                    errorTextList: _lastNameErrorList,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  if (state is CreateAccountGetProfessionalRolesLoading)
                    Center(child: CoreLoadingIndicator())
                  else if (state is CreateAccountGetProfessionalRolesFailure)
                    Text(
                      l10n.rolesLoadingError,
                      style: typography.bodySmallRegular.copyWith(
                        color: colors.textError,
                      ),
                    )
                  else
                    SingleItemSelector<String>(
                      labelText: l10n.roleLabel,
                      hintText: l10n.roleHint,
                      onOpen: _onItemSelectorOpened,
                      selectedItem: _selectedRole?.name,
                      items: _professionalRolesList
                          .map((role) => role.name)
                          .toList(),
                      onItemSelected: _onRoleSelected,
                      modalTitle: l10n.selectRoleTitle,
                    ),
                  if (_roleErrorList?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: CoreSpacing.space1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: CoreSpacing.space3),
                          CoreIconWidget(
                            icon: CoreIcons.error,
                            size: CoreIconSizes.xSmall,
                            color: colors.iconRed,
                          ),
                          const SizedBox(width: CoreSpacing.space1),
                          Expanded(
                            child: Text(
                              '${_roleErrorList?.first}',
                              style: typography.bodySmallRegular.copyWith(
                                color: colors.textError,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: CoreSpacing.space6),
                  CoreTextField(
                    label: l10n.emailLabel,
                    hintText: l10n.emailHint,
                    enabled: false,
                    readOnly: true,
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    errorTextList: _emailErrorList,
                    suffix: CoreIconWidget(
                      icon: CoreIcons.checkCircle,
                      color: colors.iconGreen,
                    ),
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  CoreTextField(
                    label: l10n.mobileNumberLabel,
                    hintText: l10n.mobileNumberHint,
                    controller: _mobileNumberController,
                    focusNode: _phoneFocusNode,
                    isPhoneNumber: true,
                    phonePrefixes: _phonePrefixes,
                    countryCodePickerTitle: context.l10n.selectCountryCode,
                    phonePrefix: _selectedPhonePrefix,
                    onPhonePrefixChanged: (prefix) {
                      if (prefix != null) {
                        setState(() {
                          _selectedPhonePrefix = prefix;
                        });
                        // Re-validate mobile number when prefix changes
                        BlocProvider.of<CreateAccountBloc>(context).add(
                          CreateAccountFormFieldChanged(
                            field: CreateAccountFormField.mobileNumber,
                            value: _mobileNumberController.text,
                            isEmailRegistration: isEmailRegistration,
                            phonePrefix: prefix,
                          ),
                        );
                      }
                    },
                    errorTextList: _mobileNumberErrorList,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  CoreTextField(
                    label: l10n.passwordLabel,
                    hintText: l10n.passwordHint,
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    suffix: IconButton(
                      icon: CoreIconWidget(
                        icon: _isPasswordVisible
                            ? CoreIcons.eye
                            : CoreIcons.eyeOff,
                        size: CoreIconSizes.medium,
                        color: colors.iconDark,
                      ),
                      onPressed: () => _togglePasswordVisibility(),
                      tooltip: _isPasswordVisible
                          ? l10n.hidePasswordLabel
                          : l10n.showPasswordLabel,
                    ),
                    errorTextList: _passwordErrorList,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  CoreTextField(
                    label: l10n.confirmPasswordLabel,
                    hintText: l10n.confirmPasswordHint,
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    suffix: IconButton(
                      icon: CoreIconWidget(
                        icon: _isConfirmPasswordVisible
                            ? CoreIcons.eye
                            : CoreIcons.eyeOff,
                        size: CoreIconSizes.medium,
                        color: colors.iconDark,
                      ),
                      onPressed: () => _toggleConfirmPasswordVisibility(),
                      tooltip: _isConfirmPasswordVisible
                          ? l10n.hidePasswordLabel
                          : l10n.showPasswordLabel,
                    ),
                    errorTextList: _confirmPasswordErrorList,
                  ),
                  const SizedBox(height: CoreSpacing.space6),
                  TermsAndConditionsSection(
                    termsAndConditionsText: l10n.termsAndConditionsText,
                    termsAndServicesLink: l10n.termsAndServicesLink,
                    privacyPolicyLink: l10n.privacyPolicyLink,
                    andAcknowledge: l10n.andAcknowledge,
                    onTermsAndConditionsLinkPressed: () => _openLink(''),
                    onPrivacyPolicyLinkPressed: () => _openLink(''),
                  ),
                  const SizedBox(height: 24),
                  CoreButton(
                    centerAlign: true,
                    isDisabled:
                        !_canPressContinue || state is CreateAccountLoading,
                    onPressed: () {
                      _onSubmit(context);
                    },
                    label: state is CreateAccountLoading
                        ? l10n.creatingAccountButton
                        : l10n.agreeAndContinueButton,
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
