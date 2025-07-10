import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

part 'auth_user.freezed.dart';
part 'auth_user.g.dart';

/// Represents a user in the application
@freezed
sealed class User with _$User {

  const User._();

  /// Creates a new [User] instance
  ///
  /// - [id]: The unique identifier for the user
  /// - [credentialId]: The unique identifier for the user's credential
  /// - [email]: The email of the user
  /// - [phone]: The phone number of the user
  /// - [countryCode]: This is the country code used in combination with the phone
  /// - [firstName]: The first name of the user
  /// - [lastName]: The last name of the user
  /// - [professionalRole]: The professional role of the user
  /// - [profilePhotoUrl]: The URL of the user's profile photo
  /// - [createdAt]: The date and time the user was created
  /// - [updatedAt]: The date and time the user was last updated
  /// - [userStatus]: The status of the user
  /// - [userPreferences]: A map of user preferences
  const factory User({
    required String id,
    required String credentialId,
    required String email,
    String? phone,
    String? countryCode,
    required String firstName,
    required String lastName,
    required String professionalRole,
    String? profilePhotoUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
    required UserProfileStatus userStatus,
    required Map<String, dynamic> userPreferences,
  }) = _User;

  /// Create a `User` instance from JSON
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Full name derived from first and last names
  String get fullName => '$firstName $lastName';
  
  /// The full usable phone number
  String get phoneNumber => '$countryCode$phone';

  /// Create an empty user
  static User empty() => User(
    id: '',
    credentialId: '',
    email: '',
    phone: '',
    firstName: '',
    lastName: '',
    professionalRole: '',
    profilePhotoUrl: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    userStatus: UserProfileStatus.inactive,
    userPreferences: {},
  );
}
