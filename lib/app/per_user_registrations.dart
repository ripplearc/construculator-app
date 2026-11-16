// coverage:ignore-file
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/project/project_module.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/session/session_module.dart';

/// Every per-user registration of the app, in the order they are added.
///
/// It lives in the app layer because the session also holds objects that
/// belong to features, and a library may not import a feature. Only
/// `main` reads this list, and passes it to the session service.
const List<PerUserRegistration> perUserRegistrations = [
  registerProjectPerUserObjects,
  registerProjectHeaderPerUserObjects,
  registerDashboardPerUserObjects,
  registerEstimationPerUserObjects,
];
