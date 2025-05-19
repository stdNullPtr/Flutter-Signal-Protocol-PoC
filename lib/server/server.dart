import 'dart:collection';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

import '../common/models/group_message.dart';
import '../common/models/message.dart';
import '../utils/logger.dart';
import 'models/user_keys.dart';

class Server {
  final HashMap<SignalProtocolAddress, UserKeys> _userData;
  final List<Message> _messageQueue;
  final List<GroupMessage> _groupMessageQueue;
  final Map<String, List<SignalProtocolAddress>> _groupMembers;

  Server() : _userData = HashMap(), _messageQueue = [], _groupMessageQueue = [], _groupMembers = {};

  void uploadInitialKeys(final SignalProtocolAddress address, final UserKeys userKeys) {
    _userData.putIfAbsent(address, () => userKeys);
    Logger.server('Stored keys for $address: ${userKeys.oneTimePreKeys.length} prekeys, identity key, signed prekey');
  }

  PreKeyBundle getBundle(final SignalProtocolAddress address) {
    Logger.server('Creating PreKey bundle for $address');
    final userData = _userData.entries.where((data) => data.key == address).first.value;

    final preKeyToUse = userData.oneTimePreKeys.removeLast();
    Logger.server('Using one-time prekey ${preKeyToUse.id} for $address (${userData.oneTimePreKeys.length} remaining)');

    return PreKeyBundle(
      userData.registrationId,
      address.getDeviceId(),
      preKeyToUse.id,
      preKeyToUse.publicKey,
      userData.signedPreKey.id,
      userData.signedPreKey.publicKey,
      userData.signedPreKey.signature,
      userData.identityKey,
    );
  }

  /// Get all device addresses for a user by name
  ///
  /// This supports multiple devices per user, as each device has a unique deviceId
  List<SignalProtocolAddress> getUserAddressesByName(final String name) {
    return _userData.entries.where((userData) => userData.key.getName() == name).map((e) => e.key).toList();
  }

  void deliver(final SignalProtocolAddress from, final SignalProtocolAddress to, final CiphertextMessage ciphertext) {
    _messageQueue.add(
      Message(
        from: from,
        to: to,
        keyType: MessageKeyType.fromValue(ciphertext.getType()),
        ciphertext: ciphertext.serialize(),
      ),
    );
  }

  List<Message> receive(final SignalProtocolAddress receiverAddress) {
    final receivedMessages = _messageQueue.where((message) => message.to == receiverAddress).toList();
    _messageQueue.removeWhere((message) => message.to == receiverAddress);
    return receivedMessages;
  }

  void createGroup(final String groupId, final List<SignalProtocolAddress> members) {
    _groupMembers[groupId] = members;
  }

  List<SignalProtocolAddress> getGroupMembers(final String groupId) {
    return _groupMembers[groupId] ?? [];
  }

  void deliverGroupMessage(final GroupMessage message) {
    _groupMessageQueue.add(message);
  }

  List<GroupMessage> receiveGroupMessages(final SignalProtocolAddress receiverAddress) {
    final groupIds =
        _groupMembers.entries
            .where((entry) => entry.value.contains(receiverAddress))
            .map((entry) => entry.key)
            .toList();

    final messages =
        _groupMessageQueue
            .where((message) => groupIds.contains(message.groupId) && message.from != receiverAddress)
            .toList();

    // Don't remove messages - others might need them
    // In real implementation, we'd track delivery status per recipient
    return messages;
  }
}
