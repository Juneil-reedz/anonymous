import 'package:flutter/services.dart';

class NativeShare {
  static const _channel = MethodChannel('com.anonymous.app/share');

  /// Fires the Facebook Stories intent on Android.
  /// Returns true if launched, false if Facebook is not installed.
  /// Throws on non-Android — caller should guard with Platform.isAndroid.
  static Future<bool> toFacebookStory(Uint8List imageBytes) async {
    final result = await _channel.invokeMethod<bool>(
      'shareToFacebookStory',
      {'imageBytes': imageBytes},
    );
    return result ?? false;
  }

  /// Fires the Instagram Stories intent on Android.
  static Future<bool> toInstagramStory(Uint8List imageBytes) async {
    final result = await _channel.invokeMethod<bool>(
      'shareToInstagramStory',
      {'imageBytes': imageBytes},
    );
    return result ?? false;
  }
}
