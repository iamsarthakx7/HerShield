// import 'dart:io';
// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';
//
// class AudioService {
//   final AudioRecorder _recorder = AudioRecorder();
//
//   /// 🎙️ Start recording
//   Future<String?> startRecording(String sosId) async {
//     if (!Platform.isAndroid) {
//       // Skip audio on non-Android platforms
//       return null;
//     }
//
//     if (!await _recorder.hasPermission()) {
//       return null;
//     }
//
//     final dir = await getApplicationDocumentsDirectory();
//     final path = '${dir.path}/sos_audio_$sosId.m4a';
//
//     await _recorder.start(
//       const RecordConfig(
//         encoder: AudioEncoder.aacLc,
//         bitRate: 128000,
//         sampleRate: 44100,
//       ),
//       path: path,
//     );
//
//     return path;
//   }
//
//   /// 🛑 Stop recording (upload later)
//   Future<void> stopAndUpload({
//     required String filePath,
//     required String sosId,
//   }) async {
//     if (!Platform.isAndroid) return;
//
//     await _recorder.stop();
//
//     // 🔥 Firebase upload will be added later
//     print('🎙️ Audio saved at: $filePath');
//   }
// }
