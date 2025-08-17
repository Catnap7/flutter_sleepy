// Stub implementations for platforms without dart:io (e.g., Web)
// Ensures that importing this module does not pull in dart:io APIs.

Future<void> initializeService() async {}
Future<void> startBackgroundService() async {}