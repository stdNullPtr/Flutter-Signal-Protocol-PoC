import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class PublicSignedPreKey {
  final int id;
  final ECPublicKey publicKey;
  final Uint8List signature;

  PublicSignedPreKey({required this.id, required this.publicKey, required this.signature});

  static PublicSignedPreKey fromSignedPreKeyRecord(SignedPreKeyRecord record) {
    return PublicSignedPreKey(id: record.id, publicKey: record.getKeyPair().publicKey, signature: record.signature);
  }
}
