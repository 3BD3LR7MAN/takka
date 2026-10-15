import 'audio_interface.dart';
import 'audio_native.dart'
    if (dart.library.js_interop) 'audio_web.dart' as bridge;

export 'audio_interface.dart';

final AudioPlatformBridge audioBridge = bridge.getAudioBridge();
