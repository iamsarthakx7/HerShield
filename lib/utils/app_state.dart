class AppState {
  // 🔴 EMERGENCY STATE
  static bool emergencyActive = false;
  static int emergencyStartTime = 0; // epoch seconds
  static String? activeSosId;

  // 📩 ALERT STATE
  static bool alertSent = false;

  // 🧠 CACHE / RECOVERY STATE (NEW)
  static bool restoredFromCache = false;
  static bool sosRecoveredAfterRestart = false;

  // 👥 CONTACTS
  static bool hasContacts = false;

  // 🎙️ AUDIO (FUTURE / OPTIONAL)
  static bool audioRecordingActive = false;
  static String? audioFilePath;

  // 🔄 RESET ALL (SAFE CLEANUP)
  static void resetEmergency() {
    emergencyActive = false;
    emergencyStartTime = 0;
    activeSosId = null;
    alertSent = false;
    restoredFromCache = false;
    sosRecoveredAfterRestart = false;
  }
}
