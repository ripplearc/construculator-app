import 'package:construculator/libraries/session/session_module.dart';

/// Every library's per-user registration, in the order they are added.
///
/// Only `SessionLibraryModule` reads this list, and passes it to the session
/// service.
const List<PerUserRegistration> perUserRegistrations = [];
