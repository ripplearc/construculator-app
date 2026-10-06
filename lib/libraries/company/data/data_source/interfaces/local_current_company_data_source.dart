/// Keeps the signed-in user's company id on the device.
///
/// Holds one company id for one user at a time. A read for any other user
/// finds nothing, so a second user on the same phone never sees the first
/// user's id.
abstract class LocalCurrentCompanyDataSource {
  /// The company id kept for [userId], or `null` when none is kept for that
  /// user.
  Future<String?> loadCompanyId(String userId);

  /// Keeps [companyId] for [userId], replacing whatever was kept before.
  Future<void> saveCompanyId({
    required String userId,
    required String companyId,
  });

  /// Forgets the kept company id, whichever user it was kept for.
  Future<void> clearCompanyId();
}
