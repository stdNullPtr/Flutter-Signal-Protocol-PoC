import 'package:flutter_signal_protocol_client_poc/client/signal_client.dart';
import 'package:flutter_signal_protocol_client_poc/server/server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Signal Protocol Client PoC Tests', () {
    late Server server;
    late SignalClient alice;
    late SignalClient bob;
    late SignalClient john;
    late SignalClient mike;

    setUp(() async {
      server = Server();

      alice = await SignalClient.build('alice', 1, 1);
      bob = await SignalClient.build('bob', 1, 1);
      john = await SignalClient.build('john', 1, 1);
      mike = await SignalClient.build('mike', 1, 1);

      server.uploadInitialKeys(alice.protocolAddress, await alice.buildUserKeys());
      server.uploadInitialKeys(bob.protocolAddress, await bob.buildUserKeys());
      server.uploadInitialKeys(john.protocolAddress, await john.buildUserKeys());
      server.uploadInitialKeys(mike.protocolAddress, await mike.buildUserKeys());
    });

    test('Basic message exchange between Alice and Bob', () async {
      await alice.deliver(bob.protocolAddress.getName(), 'Hello', server);
      final bobReceivedMessages = await bob.receiveMessages(server);
      expect(bobReceivedMessages, ['Hello']);

      await bob.deliver(alice.protocolAddress.getName(), 'Hey!', server);
      final aliceReceivedMessages = await alice.receiveMessages(server);
      expect(aliceReceivedMessages, ['Hey!']);
    });

    test('Multiple sequential messages from Alice to Bob', () async {
      await alice.deliver(bob.protocolAddress.getName(), 'Hello', server);
      final firstBobMessages = await bob.receiveMessages(server);
      expect(firstBobMessages, ['Hello']);

      await alice.deliver(bob.protocolAddress.getName(), 'What\'s up', server);
      await alice.deliver(bob.protocolAddress.getName(), 'How are you?', server);

      final secondBobMessages = await bob.receiveMessages(server);
      expect(secondBobMessages, ['What\'s up', 'How are you?']);
    });

    test('Message sequence ordering', () async {
      await alice.deliver(bob.protocolAddress.getName(), 'Hello', server);
      final firstBobMessages = await bob.receiveMessages(server);
      expect(firstBobMessages, ['Hello']);

      await alice.deliver(bob.protocolAddress.getName(), 'Test sequence 1', server);
      await alice.deliver(bob.protocolAddress.getName(), 'Test sequence 2', server);

      final secondBobMessages = await bob.receiveMessages(server);
      expect(secondBobMessages, [
        'Test sequence 1',
        'Test sequence 2',
      ], reason: 'Messages should be received in the order they were sent');
    });

    test('Communication with multiple users - John with Alice', () async {
      await john.deliver(alice.protocolAddress.getName(), 'Hello Alice', server);
      final aliceMessages = await alice.receiveMessages(server);
      expect(aliceMessages, ['Hello Alice']);

      await alice.deliver(john.protocolAddress.getName(), 'Hello John', server);
      final johnMessages = await john.receiveMessages(server);
      expect(johnMessages, ['Hello John']);
    });

    test('Communication with multiple users - Mike with Alice', () async {
      await mike.deliver(alice.protocolAddress.getName(), 'Hello Alice', server);
      final aliceMessages = await alice.receiveMessages(server);
      expect(aliceMessages, ['Hello Alice']);

      await alice.deliver(mike.protocolAddress.getName(), 'Hello Mike', server);
      final mikeMessages = await mike.receiveMessages(server);
      expect(mikeMessages, ['Hello Mike']);
    });

    test('Alice communicates with multiple people simultaneously', () async {
      await alice.deliver(bob.protocolAddress.getName(), 'Hello Bob', server);
      final bobMessages = await bob.receiveMessages(server);
      expect(bobMessages, ['Hello Bob']);

      await alice.deliver(john.protocolAddress.getName(), 'Hello John', server);
      final johnMessages = await john.receiveMessages(server);
      expect(johnMessages, ['Hello John']);

      await alice.deliver(mike.protocolAddress.getName(), 'Hello Mike', server);
      final mikeMessages = await mike.receiveMessages(server);
      expect(mikeMessages, ['Hello Mike']);

      await bob.deliver(alice.protocolAddress.getName(), 'Hi Alice from Bob', server);
      await john.deliver(alice.protocolAddress.getName(), 'Hi Alice from John', server);
      await mike.deliver(alice.protocolAddress.getName(), 'Hi Alice from Mike', server);

      final aliceMessages = await alice.receiveMessages(server);
      expect(aliceMessages, ['Hi Alice from Bob', 'Hi Alice from John', 'Hi Alice from Mike']);
    });

    test('Session reuse after initial setup', () async {
      await alice.deliver(bob.protocolAddress.getName(), 'Hello', server);
      final firstBobMessages = await bob.receiveMessages(server);
      expect(firstBobMessages, ['Hello']);

      await bob.deliver(alice.protocolAddress.getName(), 'Response', server);
      final aliceMessages = await alice.receiveMessages(server);
      expect(aliceMessages, ['Response']);

      await alice.deliver(bob.protocolAddress.getName(), 'Using existing session', server);
      final secondBobMessages = await bob.receiveMessages(server);
      expect(secondBobMessages, ['Using existing session']);
    });

    test('Limited PreKeys - Two clients initiating with Alice who has only one prekey', () async {
      await bob.deliver(alice.protocolAddress.getName(), 'First message to Alice', server);
      final aliceMessages = await alice.receiveMessages(server);
      expect(aliceMessages, ['First message to Alice']);

      await alice.deliver(bob.protocolAddress.getName(), 'Response to Bob', server);
      final bobMessages = await bob.receiveMessages(server);
      expect(bobMessages, ['Response to Bob']);

      expect(
        () async => await john.deliver(alice.protocolAddress.getName(), 'Hello from John', server),
        throwsA(isA<RangeError>()),
      );
    });

    group('Group messaging tests', () {
      test('Basic group message exchange', () async {
        const groupId = 'test-group';

        // Create a group with Alice, Bob, and John
        server.createGroup(groupId, [alice.protocolAddress, bob.protocolAddress, john.protocolAddress]);

        // Alice sends first message (will include distribution)
        await alice.deliverGroupMessage(groupId, 'Hello group!', server);

        // Bob and John receive the message
        final bobMessages = await bob.receiveGroupMessages(server);
        final johnMessages = await john.receiveGroupMessages(server);

        expect(bobMessages, ['Hello group!']);
        expect(johnMessages, ['Hello group!']);

        // Bob replies
        await bob.deliverGroupMessage(groupId, 'Hey everyone!', server);

        // Alice and John receive Bob's message
        final aliceMessages = await alice.receiveGroupMessages(server);
        final johnMessages2 = await john.receiveGroupMessages(server);

        expect(aliceMessages, ['Hey everyone!']);
        // John will get all messages since he last checked (our simple implementation)
        expect(johnMessages2.last, 'Hey everyone!');
        expect(johnMessages2.length, 2); // Both messages
      });

      test('Multiple group messages in sequence', () async {
        const groupId = 'chat-group';

        server.createGroup(groupId, [
          alice.protocolAddress,
          bob.protocolAddress,
          john.protocolAddress,
          mike.protocolAddress,
        ]);

        // Alice starts conversation
        await alice.deliverGroupMessage(groupId, 'Meeting at 3pm', server);

        // Everyone receives distribution message and first message
        final bobMessages1 = await bob.receiveGroupMessages(server);
        final johnMessages1 = await john.receiveGroupMessages(server);
        final mikeMessages1 = await mike.receiveGroupMessages(server);

        expect(bobMessages1, ['Meeting at 3pm']);
        expect(johnMessages1, ['Meeting at 3pm']);
        expect(mikeMessages1, ['Meeting at 3pm']);

        // Multiple replies
        await bob.deliverGroupMessage(groupId, 'Sounds good', server);
        await john.deliverGroupMessage(groupId, 'I\'ll be there', server);
        await mike.deliverGroupMessage(groupId, 'See you then', server);

        // Alice receives all replies (need to call receiveGroupMessages to get all new messages)
        final aliceMessages = await alice.receiveGroupMessages(server);
        expect(aliceMessages.length >= 3, true);
        expect(aliceMessages.any((msg) => msg.contains('Sounds good')), true);
        expect(aliceMessages.any((msg) => msg.contains('I\'ll be there')), true);
        expect(aliceMessages.any((msg) => msg.contains('See you then')), true);
      });

      test('Multiple groups with overlapping members', () async {
        const workGroup = 'work-group';
        const friendsGroup = 'friends-group';

        // Work group: Alice, Bob, John
        server.createGroup(workGroup, [alice.protocolAddress, bob.protocolAddress, john.protocolAddress]);

        // Friends group: Alice, Bob, Mike
        server.createGroup(friendsGroup, [alice.protocolAddress, bob.protocolAddress, mike.protocolAddress]);

        // Alice sends to work group
        await alice.deliverGroupMessage(workGroup, 'Work deadline tomorrow', server);

        // Alice sends to friends group
        await alice.deliverGroupMessage(friendsGroup, 'Party this weekend', server);

        // Bob receives both messages
        final bobWorkMessages = await bob.receiveGroupMessages(server);
        expect(bobWorkMessages.length, 2);
        expect(bobWorkMessages.contains('Work deadline tomorrow'), true);
        expect(bobWorkMessages.contains('Party this weekend'), true);

        // John only receives work message
        final johnMessages = await john.receiveGroupMessages(server);
        expect(johnMessages, ['Work deadline tomorrow']);

        // Mike only receives friends message
        final mikeMessages = await mike.receiveGroupMessages(server);
        expect(mikeMessages, ['Party this weekend']);
      });

      test('New member joining existing group', () async {
        const groupId = 'existing-group';

        // Initial group with Alice and Bob
        server.createGroup(groupId, [alice.protocolAddress, bob.protocolAddress]);

        // Exchange some messages
        await alice.deliverGroupMessage(groupId, 'Initial message', server);
        await bob.receiveGroupMessages(server);

        await bob.deliverGroupMessage(groupId, 'Reply to initial', server);
        await alice.receiveGroupMessages(server);

        // Add John to the group
        server.createGroup(groupId, [alice.protocolAddress, bob.protocolAddress, john.protocolAddress]);

        // Alice sends new message (John will get distribution)
        await alice.deliverGroupMessage(groupId, 'Welcome John!', server);

        // John receives all messages (including past ones in this simple implementation)
        final johnMessages = await john.receiveGroupMessages(server);
        expect(johnMessages.last, 'Welcome John!');
        expect(johnMessages.length, 3); // All messages sent to the group

        // John can now participate
        await john.deliverGroupMessage(groupId, 'Thanks for adding me!', server);

        final aliceMessages = await alice.receiveGroupMessages(server);
        final bobMessages = await bob.receiveGroupMessages(server);

        // In this simple implementation, users get all messages since they last checked
        expect(aliceMessages.last, 'Thanks for adding me!');
        expect(bobMessages.last, 'Thanks for adding me!');
      });
    });
  });
}
