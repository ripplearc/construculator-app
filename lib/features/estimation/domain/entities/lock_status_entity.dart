sealed class LockStatus {
  const LockStatus();
  factory LockStatus.locked(String userId, DateTime at) = LockedStatus;
  const factory LockStatus.unlocked() = UnlockedStatus;

  bool get isLocked;
  bool isLockedBy(String userId);
}

class LockedStatus extends LockStatus {
  final String lockedByUserId;
  final DateTime lockedAt;
  const LockedStatus(this.lockedByUserId, this.lockedAt);

  @override
  bool get isLocked => true;

  @override
  bool isLockedBy(String userId) => lockedByUserId == userId;
}

class UnlockedStatus extends LockStatus {
  const UnlockedStatus();

  @override
  bool get isLocked => false;

  @override
  bool isLockedBy(String userId) => false;
}
