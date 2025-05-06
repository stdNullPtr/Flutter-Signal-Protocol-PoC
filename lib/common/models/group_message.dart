import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

enum GroupMessageType { distribution, regular }

class GroupMessage {
  final String groupId;
  final SignalProtocolAddress from;
  final GroupMessageType messageType;
  final Uint8List ciphertext;

  GroupMessage({required this.groupId, required this.from, required this.messageType, required this.ciphertext});
}
