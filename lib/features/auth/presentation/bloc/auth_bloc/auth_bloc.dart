import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/auth_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthManager _authManager;
  final AuthNotifier _authNotifier;
  final AppRouter _router;
  
  AuthBloc({
    required AuthManager authManager,
    required AuthNotifier authNotifier,
    required AppRouter router,
  }) : _authManager = authManager,
       _authNotifier = authNotifier,
       _router = router,
       super(const AuthInitial()) {
    
    on<AuthStarted>(_onAuthStarted);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthUserProfileChanged>(_onUserProfileChanged);
  }

  void _onAuthStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoadInProgress());
    
    try {
      final cred = _authManager.getCurrentCredentials();
      
      if (cred.data?.id == null) {
        emit(const AuthLoadUnauthenticated());
        _router.navigate(fullLoginRoute);
        return;
      }
      
      final result = await _authManager.getUserProfile(cred.data?.id ?? '');
      
      if (result.isSuccess && result.data != null) {
        emit(AuthLoadSuccess(
          user: result.data,
          avatarUrl: result.data?.profilePhotoUrl,
        ));
      } else {
        emit(const AuthLoadUnauthenticated());
        _router.navigate(fullCreateAccountRoute, arguments: cred.data?.email);
      }
    } catch (error) {
      emit(AuthLoadFailure('Failed to load authentication state: $error'));
    }
  }

  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    // Handle auth state changes from the notifier
    // This can be used to react to external auth state changes
  }

  void _onUserProfileChanged(AuthUserProfileChanged event, Emitter<AuthState> emit) {
    if (event.user == null) {
      emit(const AuthLoadUnauthenticated());
      final cred = _authManager.getCurrentCredentials();
      _router.navigate(fullCreateAccountRoute, arguments: cred.data?.email);
    } else {
      emit(AuthLoadSuccess(
        user: event.user,
        avatarUrl: event.user?.profilePhotoUrl,
      ));
    }
  }

  /// Initialize the auth bloc and start listening to auth changes
  void initialize() {
    // Listen to auth state changes
    _authNotifier.onAuthStateChanged.listen((authState) {
      add(const AuthStateChanged());
    });
    
    // Listen to user profile changes
    _authNotifier.onUserProfileChanged.listen((user) {
      add(AuthUserProfileChanged(user));
    });
    
    // Start the auth process
    add(const AuthStarted());
  }
}
