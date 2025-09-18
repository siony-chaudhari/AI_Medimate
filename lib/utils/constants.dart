import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF1976D2);
  static const Color accent = Color(0xFF64B5F6);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}

class AppSizes {
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
}

class AppStrings {
  static const String appName = 'MediMate AI';
  static const String appTagline = 'AI-powered Medication Management';
  
  // Auth
  static const String signUp = 'Sign up';
  static const String signIn = 'Sign in';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String name = 'Name';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = 'Don\'t have an account?';
  
  // Home
  static const String welcome = 'Welcome';
  static const String stayHealthy = 'Stay healthy, stay on track';
  static const String uploadPrescription = 'Upload Prescription';
  static const String todayReminders = 'Today\'s Reminders';
  static const String expiryAlerts = 'Expiry Alerts';
  static const String askAI = 'Ask AI Assistant';
  static const String nextMedicine = 'Next Medicine';
  
  // Navigation
  static const String home = 'Home';
  static const String reminders = 'Reminders';
  static const String history = 'History';
  static const String profile = 'Profile';
  
  // Reminders
  static const String today = 'Today';
  static const String todayProgress = 'Today\'s Progress';
  static const String keepUpGreatWork = 'Keep up the great work!';
  static const String taken = 'Taken';
  static const String missed = 'Missed';
  
  // Expiry Tracker
  static const String expiryTracker = 'Expiry Tracker';
  static const String trackingOverview = 'Tracking Overview';
  static const String medicinesMonitored = 'medicines being monitored';
  static const String needAttention = 'Need attention';
  static const String yourMedicines = 'Your Medicines';
  static const String expired = 'Expired';
  static const String expiringSoon = 'Expiring Soon';
  static const String safe = 'Safe';
  
  // AI Chat
  static const String aiAssistant = 'AI Assistant';
  static const String typeQuestion = 'Type your health question...';
  static const String helloMessage = 'Hello! How can I help with your health questions today?';
  
  // Profile
  static const String personalInfo = 'Personal Information';
  static const String manageProfile = 'Manage your profile details';
  static const String myPrescriptions = 'My Prescriptions';
  static const String viewPrescriptions = 'View and manage prescriptions';
  static const String settings = 'Settings & Preferences';
  static const String customizeExperience = 'Customize your experience';
  static const String helpSupport = 'Help & Support';
  static const String getAssistance = 'Get assistance and FAQs';
  static const String logOut = 'Log Out';
}
