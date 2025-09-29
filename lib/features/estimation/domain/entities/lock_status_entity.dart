/// Represents the locking status of an entity to prevent concurrent editing.
/// 
/// This sealed class provides a type-safe way to represent whether an entity
/// (such as a cost estimate) is currently locked for editing. It supports
/// two states: locked and unlocked.
/// 
/// When locked, the status includes information about who locked the entity
/// and when it was locked, enabling proper access control and conflict resolution.
/// 
/// Details can be found in the detailed design document: https://docs.google.com/document/d/1MHn-LanxVJ96-HSe47C9Km0evtkPcyQDw9eDzFD60AA/edit?tab=t.m4ek8adycklb#bookmark=id.d9j7twe7aurf
sealed class LockStatus {
  const LockStatus();
  
  /// Creates a locked status with the specified user and timestamp.
  factory LockStatus.locked(String userId, DateTime at) = LockedStatus;
  
  /// Creates an unlocked status.
  const factory LockStatus.unlocked() = UnlockedStatus;

  /// Returns true if the entity is currently locked.
  bool get isLocked;
  
  /// Returns true if the entity is locked by the specified user.
  /// 
  /// This method is useful for determining if the current user can edit
  /// the entity (they can if they are the one who locked it).
  bool isLockedBy(String userId);
}

/// Represents a locked state of an entity.
/// 
/// Contains information about who locked the entity and when the lock was applied.
/// This information is essential for access control and audit trails.
class LockedStatus extends LockStatus {
  /// The ID of the user who locked the entity.
  final String lockedByUserId;
  
  /// The timestamp when the entity was locked.
  final DateTime lockedAt;
  
  /// Creates a locked status with the specified user and timestamp.
  const LockedStatus(this.lockedByUserId, this.lockedAt);

  @override
  bool get isLocked => true;

  @override
  bool isLockedBy(String userId) => lockedByUserId == userId;
}

/// Represents an unlocked state of an entity.
/// 
/// Indicates that the entity is available for editing by any authorized user.
/// This is the default state for entities that are not currently being modified.
class UnlockedStatus extends LockStatus {
  /// Creates an unlocked status.
  const UnlockedStatus();

  @override
  bool get isLocked => false;

  @override
  bool isLockedBy(String userId) => false;
}
