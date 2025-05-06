import 'dart:convert';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../common/models/group_message.dart';
import '../common/models/message.dart';
import '../server/models/public_prekey.dart';
import '../server/models/public_signed_prekey.dart';
import '../server/models/user_keys.dart';
import '../server/server.dart';
import '../utils/logger.dart';

part 'signal_client.freezed.dart';

@freezed
abstract class SignalClient with _$SignalClient {
  const SignalClient._();

  const factory SignalClient({
    required SignalProtocolAddress protocolAddress,
    required SessionStore sessionStore,
    required PreKeyStore preKeyStore,
    required SignedPreKeyStore signedPreKeyStore,
    required IdentityKeyStore identityStore,
    required SenderKeyStore groupSenderKeyStore,
  }) = _SignalClient;

  // Track which groups we've sent distribution messages to (simple PoC approach)
  static final Map<String, Map<String, bool>> _distributedKeys = {};

  static Future<SignalClient> build(final String name, final int deviceId, final int preKeysToCreate) async {
    final identityKeyPair = generateIdentityKeyPair();
    final registrationId = generateRegistrationId(false);

    final List<PreKeyRecord> preKeys = generatePreKeys(0, preKeysToCreate);

    final signedPreKey = generateSignedPreKey(identityKeyPair, 0);

    final sessionStore = InMemorySessionStore();
    final preKeyStore = InMemoryPreKeyStore();
    final signedPreKeyStore = InMemorySignedPreKeyStore();
    final identityStore = InMemoryIdentityKeyStore(identityKeyPair, registrationId);

    for (var p in preKeys) {
      await preKeyStore.storePreKey(p.id, p);
    }

    await signedPreKeyStore.storeSignedPreKey(signedPreKey.id, signedPreKey);

    final protocolAddress = SignalProtocolAddress(name, deviceId);

    final senderKeyStore = InMemorySenderKeyStore();

    return SignalClient(
      protocolAddress: protocolAddress,
      sessionStore: sessionStore,
      preKeyStore: preKeyStore,
      signedPreKeyStore: signedPreKeyStore,
      identityStore: identityStore,
      groupSenderKeyStore: senderKeyStore,
    );
  }

  Future<void> deliver(final String userName, final String message, final Server server) async {
    final recipientAddresses = server.getUserAddressesByName(userName);
    if (recipientAddresses.isEmpty) {
      Logger.client(protocolAddress.getName(), 'No addresses for user $userName !!!', type: LogType.error);
      return;
    }

    for (var remoteAddress in recipientAddresses) {
      final sessionExists = await sessionStore.containsSession(remoteAddress);

      if (!sessionExists) {
        Logger.client(protocolAddress.getName(), 'No session with $remoteAddress, establishing new session');
        final deviceBundle = server.getBundle(remoteAddress);
        final sessionBuilder = SessionBuilder(
          sessionStore,
          preKeyStore,
          signedPreKeyStore,
          identityStore,
          remoteAddress,
        );
        await sessionBuilder.processPreKeyBundle(deviceBundle);
        Logger.client(
          protocolAddress.getName(),
          'X3DH key agreement completed with $remoteAddress',
          type: LogType.keyExchange,
        );
      }

      final sessionCipher = SessionCipher(sessionStore, preKeyStore, signedPreKeyStore, identityStore, remoteAddress);
      Logger.client(protocolAddress.getName(), 'Encrypting "$message" for $remoteAddress', type: LogType.encryption);
      final ciphertext = await sessionCipher.encrypt(utf8.encode(message));
      server.deliver(protocolAddress, remoteAddress, ciphertext);
      final messageType = MessageKeyType.fromValue(ciphertext.getType());
      Logger.client(protocolAddress.getName(), 'Sent encrypted message to $remoteAddress (type: ${messageType.name})');
    }
  }

  Future<List<String>> receiveMessages(final Server server) async {
    final messages = server.receive(protocolAddress);
    final List<String> decryptedMessages = [];
    Logger.client(protocolAddress.getName(), 'Checking for messages: ${messages.length} found');

    for (var message in messages) {
      Logger.client(protocolAddress.getName(), 'Processing message from ${message.from}');
      final sessionCipher = SessionCipher(sessionStore, preKeyStore, signedPreKeyStore, identityStore, message.from);

      Uint8List plainText;
      if (message.keyType == MessageKeyType.prekey) {
        Logger.client(protocolAddress.getName(), 'Message is PreKeyMessage (initial message)');
        plainText = await sessionCipher.decrypt(PreKeySignalMessage(message.ciphertext));
        final decryptedMessage = utf8.decode(plainText);
        decryptedMessages.add(decryptedMessage);
        Logger.client(
          protocolAddress.getName(),
          'Decrypted initial message: "$decryptedMessage"',
          type: LogType.decryption,
        );
        Logger.client(protocolAddress.getName(), 'Session established with ${message.from}', type: LogType.success);
      } else if (message.keyType == MessageKeyType.whisper) {
        Logger.client(protocolAddress.getName(), 'Message is regular Signal message');
        plainText = await sessionCipher.decryptFromSignal(SignalMessage.fromSerialized(message.ciphertext));
        final decryptedMessage = utf8.decode(plainText);
        decryptedMessages.add(decryptedMessage);
        Logger.client(protocolAddress.getName(), 'Decrypted: "$decryptedMessage"', type: LogType.decryption);
      }
    }
    return decryptedMessages;
  }

  Future<UserKeys> buildUserKeys() async {
    final signedPreKeyRecord = await signedPreKeyStore.loadSignedPreKey(0);
    final preKeyRecords = await Future.wait(
      (preKeyStore as InMemoryPreKeyStore).store.keys.map((id) => preKeyStore.loadPreKey(id)),
    );

    return UserKeys(
      registrationId: await identityStore.getLocalRegistrationId(),
      identityKey: (await identityStore.getIdentityKeyPair()).getPublicKey(),
      signedPreKey: PublicSignedPreKey.fromSignedPreKeyRecord(signedPreKeyRecord),
      oneTimePreKeys: preKeyRecords.map((record) => PublicPreKey.fromPreKeyRecord(record)).toList(),
    );
  }

  Future<void> deliverGroupMessage(final String groupId, final String message, final Server server) async {
    final groupSender = SenderKeyName(groupId, protocolAddress);
    final sessionBuilder = GroupSessionBuilder(groupSenderKeyStore);
    final groupCipher = GroupCipher(groupSenderKeyStore, groupSender);

    final userKey = protocolAddress.toString();
    _distributedKeys[userKey] ??= {};

    if (_distributedKeys[userKey]![groupId] != true) {
      _distributedKeys[userKey]![groupId] = true;
      Logger.client(protocolAddress.getName(), 'Creating new sender key for group $groupId', type: LogType.keyExchange);
      final distributionMessage = await sessionBuilder.create(groupSender);

      final distributionGroupMessage = GroupMessage(
        groupId: groupId,
        from: protocolAddress,
        messageType: GroupMessageType.distribution,
        ciphertext: distributionMessage.serialize(),
      );
      server.deliverGroupMessage(distributionGroupMessage);
      Logger.client(protocolAddress.getName(), 'Sent distribution message to group $groupId');
    } else {
      Logger.client(protocolAddress.getName(), 'Using existing sender key for group $groupId');
    }

    final encryptedMessage = await groupCipher.encrypt(Uint8List.fromList(utf8.encode(message)));
    Logger.client(
      protocolAddress.getName(),
      'Encrypted message "$message" for group $groupId',
      type: LogType.encryption,
    );

    final groupMessage = GroupMessage(
      groupId: groupId,
      from: protocolAddress,
      messageType: GroupMessageType.regular,
      ciphertext: encryptedMessage,
    );

    server.deliverGroupMessage(groupMessage);
    Logger.client(protocolAddress.getName(), 'Message sent to server');
  }

  Future<List<String>> receiveGroupMessages(final Server server) async {
    final groupMessages = server.receiveGroupMessages(protocolAddress);
    final List<String> decryptedMessages = [];

    for (var message in groupMessages) {
      final groupSender = SenderKeyName(message.groupId, message.from);

      if (message.messageType == GroupMessageType.distribution) {
        Logger.client(
          protocolAddress.getName(),
          'Processing distribution message from ${message.from.getName()} for group ${message.groupId}',
        );
        final sessionBuilder = GroupSessionBuilder(groupSenderKeyStore);
        final distributionMessage = SenderKeyDistributionMessageWrapper.fromSerialized(message.ciphertext);
        await sessionBuilder.process(groupSender, distributionMessage);
        Logger.client(
          protocolAddress.getName(),
          'Stored sender key from ${message.from.getName()} for group ${message.groupId}',
          type: LogType.keyExchange,
        );
      } else {
        Logger.client(
          protocolAddress.getName(),
          'Decrypting message from ${message.from.getName()} in group ${message.groupId}',
        );
        final groupCipher = GroupCipher(groupSenderKeyStore, groupSender);
        final plaintext = await groupCipher.decrypt(message.ciphertext);
        final decryptedMessage = utf8.decode(plaintext);
        decryptedMessages.add(decryptedMessage);
        Logger.client(protocolAddress.getName(), 'Decrypted: "$decryptedMessage"', type: LogType.decryption);
      }
    }

    return decryptedMessages;
  }
}
