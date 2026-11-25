import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// What a read of the saved Supabase session found.
sealed class SavedSessionRead {
  const SavedSessionRead();
}

/// A value is saved.
final class SavedSessionFound extends SavedSessionRead with Equatable {
  /// The saved text, as Supabase wrote it.
  final String value;

  /// A read that found [value].
  const SavedSessionFound(this.value);

  @override
  List<Object?> get props => [value];

  /// Whether Supabase can load [value] as a session.
  ///
  /// This is Supabase's own test: the text is JSON and holds an access token.
  /// A value that fails it gives a first auth event with no session, and
  /// Supabase leaves the value saved.
  bool get isReadableSession {
    try {
      final decoded = json.decode(value);
      if (decoded is! Map<String, dynamic>) return false;
      return supabase.Session.fromJson(decoded) != null;
    } on FormatException {
      return false;
    } on TypeError {
      return false;
    }
  }
}

/// Nothing is saved.
final class SavedSessionAbsent extends SavedSessionRead {
  /// A read that found no value.
  const SavedSessionAbsent();
}

/// The read failed, for example because the iPhone keychain is locked.
///
/// This is not the same as [SavedSessionAbsent]: nothing may be deleted and no
/// sign-out date may be saved on an unknown read.
final class SavedSessionUnknown extends SavedSessionRead {
  /// A read that could not tell.
  const SavedSessionUnknown();
}
