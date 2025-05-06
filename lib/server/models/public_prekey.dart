import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class PublicPreKey {
  final int id;
  final ECPublicKey publicKey;

  PublicPreKey({required this.id, required this.publicKey});

  static PublicPreKey fromPreKeyRecord(PreKeyRecord record) {
    return PublicPreKey(id: record.id, publicKey: record.getKeyPair().publicKey);
  }
}
