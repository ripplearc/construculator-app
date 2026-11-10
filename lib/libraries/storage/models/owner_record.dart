import 'package:equatable/equatable.dart';

/// Why a delete of local-only data has started.
enum PendingDeleteKind {
  /// A different user is signing in. The flag names that user.
  arrivalOfNewUser,

  /// A logout, or a sign-out of a session with no owner record. The flag names
  /// nobody.
  logoutOrNoOwnerRecord,
}

/// A delete of local-only data that has started and may not have finished.
class PendingDelete extends Equatable {
  /// Why the delete started.
  final PendingDeleteKind kind;

  /// The user whose arrival started the delete, only for
  /// [PendingDeleteKind.arrivalOfNewUser].
  final String? arrivingUserId;

  /// A delete caused by the arrival of the user [userId].
  const PendingDelete.arrivalOf(String userId)
    : kind = PendingDeleteKind.arrivalOfNewUser,
      arrivingUserId = userId;

  /// A delete caused by a logout or by a sign-out with no owner record.
  const PendingDelete.logoutOrNoOwnerRecord()
    : kind = PendingDeleteKind.logoutOrNoOwnerRecord,
      arrivingUserId = null;

  @override
  List<Object?> get props => [kind, arrivingUserId];
}

/// Says whose local-only data is on the phone.
///
/// It is not related to the project owner feature. When [userId] is null
/// nobody is known, and then [pendingDelete] is always set.
class OwnerRecord extends Equatable {
  /// The user whose data is on the phone, or null when nobody is known.
  final String? userId;

  /// The delete that has started, or null when none is in progress.
  final PendingDelete? pendingDelete;

  /// The date a sign-out left kept data on the phone, in UTC, or null when none
  /// did.
  final DateTime? signOutDate;

  /// Creates a record. Throws an [ArgumentError] when both [userId] and
  /// [pendingDelete] are missing, because that state must be unreachable, and
  /// when a user id, including the one the flag names, is an empty string:
  /// nobody known is a null [userId], never an empty one. A [signOutDate] is
  /// stored in UTC.
  OwnerRecord({this.userId, this.pendingDelete, DateTime? signOutDate})
    : signOutDate = signOutDate?.toUtc() {
    if (userId == null && pendingDelete == null) {
      throw ArgumentError('A record with no user id needs a pending delete.');
    }
    if (userId == '' || pendingDelete?.arrivingUserId == '') {
      throw ArgumentError('A user id cannot be empty.');
    }
  }

  /// Reads a record from [json]. Throws a [FormatException] when [json] is not
  /// a record written by [toJson].
  factory OwnerRecord.fromJson(Map<String, Object?> json) {
    final userId = json['userId'];
    final pending = json['pendingDelete'];
    final signOutDate = json['signOutDate'];
    if (userId != null && userId is! String) {
      throw const FormatException('userId is not a string');
    }
    if (signOutDate != null && signOutDate is! String) {
      throw const FormatException('signOutDate is not a string');
    }
    try {
      return OwnerRecord(
        userId: userId as String?,
        pendingDelete: pending == null ? null : _pendingDeleteFromJson(pending),
        signOutDate: signOutDate == null
            ? null
            : DateTime.parse(signOutDate as String),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static PendingDelete _pendingDeleteFromJson(Object pending) {
    if (pending is! Map<String, Object?>) {
      throw const FormatException('pendingDelete is not an object');
    }
    final kind = pending['kind'];
    final arrivingUserId = pending['userId'];
    switch (kind) {
      case 'arrivalOfNewUser' when arrivingUserId is String:
        return PendingDelete.arrivalOf(arrivingUserId);
      case 'logoutOrNoOwnerRecord' when arrivingUserId == null:
        return const PendingDelete.logoutOrNoOwnerRecord();
    }
    throw FormatException('pendingDelete is not valid: $pending');
  }

  /// The record as a JSON object that [OwnerRecord.fromJson] reads back.
  Map<String, Object?> toJson() {
    final pending = pendingDelete;
    return {
      'userId': userId,
      'pendingDelete': pending == null
          ? null
          : {'kind': pending.kind.name, 'userId': pending.arrivingUserId},
      'signOutDate': signOutDate?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userId, pendingDelete, signOutDate];
}
