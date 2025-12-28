class AppState {
  static bool emergencyActive = false;
  static bool hasContacts = false;

  static String? activeSosId;
  static bool alertSent = false;
  static int emergencyStartTime = 0; // epoch seconds
  static bool audioRecordingActive = false;
  static String? audioFilePath;

}