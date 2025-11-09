import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;

  /// Initialize TTS with settings
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      debugPrint("🔊 Initializing TTS Service...");

      // Set language to English (India)
      await _flutterTts.setLanguage("en-IN");

      // Set speech rate (0.0 to 1.0, default 0.5)
      await _flutterTts.setSpeechRate(0.5);

      // Set volume (0.0 to 1.0, default 1.0)
      await _flutterTts.setVolume(1.0);

      // Set pitch (0.5 to 2.0, default 1.0)
      await _flutterTts.setPitch(1.0);

      // iOS specific settings
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );

      _isInitialized = true;
      debugPrint("✅ TTS Service initialized successfully");
    } catch (e) {
      debugPrint("❌ Error initializing TTS: $e");
    }
  }

  /// Speak the medicine reminder
  static Future<void> speakMedicineReminder(String medicineName) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      // Create a natural reminder message
      final message = "It's time to take your $medicineName";
      
      debugPrint("🔊 Speaking: $message");
      
      await _flutterTts.speak(message);
    } catch (e) {
      debugPrint("❌ Error speaking: $e");
    }
  }

  /// Speak custom text
  static Future<void> speak(String text) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      debugPrint("🔊 Speaking: $text");
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("❌ Error speaking: $e");
    }
  }

  /// Stop speaking
  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
      debugPrint("🔇 TTS stopped");
    } catch (e) {
      debugPrint("❌ Error stopping TTS: $e");
    }
  }

  /// Check if TTS is speaking
  static Future<bool> isSpeaking() async {
    try {
      final speaking = await _flutterTts.awaitSpeakCompletion(true);
      return speaking;
    } catch (e) {
      debugPrint("❌ Error checking TTS status: $e");
      return false;
    }
  }

  /// Get available languages
  static Future<List<dynamic>> getLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      debugPrint("📋 Available languages: $languages");
      return languages;
    } catch (e) {
      debugPrint("❌ Error getting languages: $e");
      return [];
    }
  }

  /// Set language
  static Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
      debugPrint("🌐 Language set to: $language");
    } catch (e) {
      debugPrint("❌ Error setting language: $e");
    }
  }

  /// Set speech rate (0.0 to 1.0)
  static Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
      debugPrint("⚡ Speech rate set to: $rate");
    } catch (e) {
      debugPrint("❌ Error setting speech rate: $e");
    }
  }

  /// Set volume (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
      debugPrint("🔊 Volume set to: $volume");
    } catch (e) {
      debugPrint("❌ Error setting volume: $e");
    }
  }

  /// Set pitch (0.5 to 2.0)
  static Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
      debugPrint("🎵 Pitch set to: $pitch");
    } catch (e) {
      debugPrint("❌ Error setting pitch: $e");
    }
  }
}
