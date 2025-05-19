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

  /// Create a new Signal client with given name, device ID, and number of prekeys
  ///
  /// For multi-device support, create multiple clients with the same name but different deviceIds
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

    for (final remoteAddress in recipientAddresses) {
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
      } else {
        Logger.client(protocolAddress.getName(), 'Using existing session with $remoteAddress');
        await _ensureSessionIsAcknowledged(remoteAddress);
      }

      final sessionCipher = SessionCipher(sessionStore, preKeyStore, signedPreKeyStore, identityStore, remoteAddress);

      Logger.client(protocolAddress.getName(), 'Encrypting "$message" for $remoteAddress', type: LogType.encryption);
      final ciphertext = await sessionCipher.encrypt(utf8.encode(message));

      server.deliver(protocolAddress, remoteAddress, ciphertext);

      final messageType = MessageKeyType.fromValue(ciphertext.getType());
      Logger.client(protocolAddress.getName(), 'Sent encrypted message to $remoteAddress (type: ${messageType.name})');
    }
  }

  Future<void> _ensureSessionIsAcknowledged(final SignalProtocolAddress remoteAddress) async {
    final sessionRecord = await sessionStore.loadSession(remoteAddress);

    if (sessionRecord.sessionState.hasUnacknowledgedPreKeyMessage()) {
      Logger.client(
        protocolAddress.getName(),
        'Session with $remoteAddress has unacknowledged prekey message, clearing flag',
        type: LogType.keyExchange,
      );

      sessionRecord.sessionState.clearUnacknowledgedPreKeyMessage();

      await sessionStore.storeSession(remoteAddress, sessionRecord);

      Logger.client(
        protocolAddress.getName(),
        'Session with $remoteAddress is now fully acknowledged',
        type: LogType.success,
      );
    }
  }

  Future<List<String>> receiveMessages(final Server server) async {
    final messages = server.receive(protocolAddress);
    final List<String> decryptedMessages = [];
    Logger.client(protocolAddress.getName(), 'Checking for messages: ${messages.length} found');

    for (final message in messages) {
      Logger.client(protocolAddress.getName(), 'Processing message from ${message.from}');
      final sessionCipher = SessionCipher(sessionStore, preKeyStore, signedPreKeyStore, identityStore, message.from);

      late final Uint8List plainText;
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

        // Acknowledge the session to enable proper ratcheting in subsequent messages
        await _acknowledgeSession(message.from, server);
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

  // Creates a dummy message to acknowledge the session and establish ratchet keys
  Future<void> _acknowledgeSession(final SignalProtocolAddress remoteAddress, final Server server) async {
    if (await sessionStore.containsSession(remoteAddress)) {
      Logger.client(
        protocolAddress.getName(),
        'Sending silent acknowledgment to complete session with $remoteAddress',
        type: LogType.keyExchange,
      );

      final sessionCipher = SessionCipher(sessionStore, preKeyStore, signedPreKeyStore, identityStore, remoteAddress);
      final ackMessage = Uint8List.fromList(utf8.encode("ACK"));
      final ciphertext = await sessionCipher.encrypt(ackMessage);

      // We don't actually send this message - it's just to update our local session state
      // In a real implementation, this would be a special message type or an actual message

      final messageType = MessageKeyType.fromValue(ciphertext.getType());
      Logger.client(
        protocolAddress.getName(),
        'Session with $remoteAddress acknowledged (next message type: ${messageType.name})',
        type: LogType.success,
      );
    }
  }

  /// Creates bundle of keys for initial session establishment
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

  /// Encrypts and sends a message to a group
  Future<void> deliverGroupMessage(final String groupId, final String message, final Server server) async {
    final groupSender = SenderKeyName(groupId, protocolAddress);
    final sessionBuilder = GroupSessionBuilder(groupSenderKeyStore);
    final groupCipher = GroupCipher(groupSenderKeyStore, groupSender);

    // Track which groups we've distributed keys to for this user
    final userKey = protocolAddress.toString();
    _distributedKeys[userKey] ??= {};

    // If we haven't distributed our key to this group yet, do it before sending messages
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

    final messageBytes = Uint8List.fromList(utf8.encode(message));
    final encryptedMessage = await groupCipher.encrypt(messageBytes);

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

  /// Receives and decrypts messages from a group
  Future<List<String>> receiveGroupMessages(final Server server) async {
    final groupMessages = server.receiveGroupMessages(protocolAddress);
    final List<String> decryptedMessages = [];

    for (final message in groupMessages) {
      final groupSender = SenderKeyName(message.groupId, message.from);

      if (message.messageType == GroupMessageType.distribution) {
        // Handle distribution message (key exchange for group messaging)
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
        // Handle regular message
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
