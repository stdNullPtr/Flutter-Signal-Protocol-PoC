import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import 'public_prekey.dart';
import 'public_signed_prekey.dart';

class UserKeys {
  final int registrationId;
  final IdentityKey identityKey;
  final PublicSignedPreKey signedPreKey;
  final List<PublicPreKey> oneTimePreKeys;

  UserKeys({
    required this.registrationId,
    required this.identityKey,
    required this.signedPreKey,
    required this.oneTimePreKeys,
  });
}
