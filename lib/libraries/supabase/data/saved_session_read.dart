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

  @override
  bool? get stringify => false;

  /// Whether Supabase can load [value] as a session. Any error while parsing
  /// counts as "not a session", because Supabase keeps a value that throws
  /// anything while loading.
  ///
  /// This is Supabase's own test: the text is JSON and holds an access token
  /// and a user. A value that is not JSON, or has a bad user, gives a first
  /// auth event with no session, and Supabase leaves the value saved. A JSON
  /// value with no access token makes Supabase end the session itself and
  /// remove the value.
  bool get isReadableSession => _session != null;

  /// The user the saved session belongs to, or null when [isReadableSession]
  /// is false.
  String? get userId => _session?.user.id;

  /// The access token of the saved session, or null when [isReadableSession]
  /// is false.
  String? get accessToken => _session?.accessToken;

  supabase.Session? get _session {
    try {
      return supabase.Session.fromJson(json.decode(value));
    } on Object {
      return null;
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
