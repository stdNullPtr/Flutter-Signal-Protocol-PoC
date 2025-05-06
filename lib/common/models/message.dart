import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

enum MessageKeyType {
  prekey(CiphertextMessage.prekeyType),
  whisper(CiphertextMessage.whisperType);

  final int value;

  const MessageKeyType(this.value);

  static MessageKeyType fromValue(int value) {
    return MessageKeyType.values.firstWhere((type) => type.value == value);
  }
}

class Message {
  final SignalProtocolAddress from;
  final SignalProtocolAddress to;
  final MessageKeyType keyType;
  final Uint8List ciphertext;

  Message({required this.from, required this.keyType, required this.to, required this.ciphertext});
}
