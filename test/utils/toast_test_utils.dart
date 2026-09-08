/// CoreToast displays for 3 seconds by default (the package does not export
/// the duration as a constant); pump just past it to flush the auto-dismiss
/// timer before the test ends.
const Duration kToastDismissDuration = Duration(seconds: 4);
