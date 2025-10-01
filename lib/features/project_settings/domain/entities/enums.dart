/// Storage providers supported for project export functionality.
///
/// These enums represent the different cloud storage services that users
/// can choose from when exporting their construction project data.
/// 
/// Details can be found in the detailed design document: https://docs.google.com/document/d/1iXnDtNoersQdjHARELluAMqb8sB96rhRmjMKCWUA3QY/edit?tab=t.9phj9ydk8mav#heading=h.7xf5e9ii5k79
enum StorageProvider {
  /// Google Drive cloud storage service.
  googleDrive,
  
  /// Microsoft OneDrive cloud storage service.
  oneDrive,
  
  /// Dropbox cloud storage service.
  dropbox,
}

/// Represents the current status of a construction project.
///
/// Projects can be in different states throughout their lifecycle,
/// affecting their visibility and accessibility within the application.
/// 
/// Details can be found in the detailed design document: https://docs.google.com/document/d/1iXnDtNoersQdjHARELluAMqb8sB96rhRmjMKCWUA3QY/edit?tab=t.9phj9ydk8mav#heading=h.7xf5e9ii5k79
enum ProjectStatus {
  /// The project is currently active and being worked on.
  active,
  
  /// The project has been archived and is no longer actively used.
  archived,
}