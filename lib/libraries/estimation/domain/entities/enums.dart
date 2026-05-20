/// Defines the strategy for applying markups to cost estimates.
/// 
/// This enum determines whether markups are applied uniformly across
/// all cost components or separately to different categories.
/// 
/// Details can be found in the detailed design document: 
/// https://docs.google.com/document/d/1MHn-LanxVJ96-HSe47C9Km0evtkPcyQDw9eDzFD60AA/edit?tab=t.m4ek8adycklb#heading=h.pailgmv07rcv
enum MarkupType { 
  /// Apply a single markup to the entire project cost.
  /// All cost components (materials, labor, equipment) use the same markup value.
  overall, 
  
  /// Apply separate markups to different cost categories.
  /// Allows different markup values for materials, labor, and equipment.
  granular 
}

/// Defines how markup values are calculated and applied.
/// 
/// This enum determines whether markups are calculated as a percentage
/// of the base cost or as a fixed dollar amount.
/// 
/// Details can be found in the detailed design document: 
/// https://docs.google.com/document/d/1MHn-LanxVJ96-HSe47C9Km0evtkPcyQDw9eDzFD60AA/edit?tab=t.m4ek8adycklb#heading=h.pailgmv07rcv
enum MarkupValueType { 
  /// Markup is calculated as a percentage of the base cost.
  percentage, 
  
  /// Markup is a fixed amount added to the base cost.
  amount 
}
