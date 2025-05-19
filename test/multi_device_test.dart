import 'package:flutter_signal_protocol_client_poc/client/signal_client.dart';
import 'package:flutter_signal_protocol_client_poc/server/server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Multi-device support tests', () {
    late Server server;
    late SignalClient alice;
    late SignalClient aliceLaptop;
    late SignalClient bob;

    setUp(() async {
      server = Server();

      // Create clients for Alice's phone (device 1) and laptop (device 2)
      alice = await SignalClient.build('alice', 1, 1);
      aliceLaptop = await SignalClient.build('alice', 2, 1);
      bob = await SignalClient.build('bob', 1, 1);

      // Upload keys for all devices to the server
      server.uploadInitialKeys(alice.protocolAddress, await alice.buildUserKeys());
      server.uploadInitialKeys(aliceLaptop.protocolAddress, await aliceLaptop.buildUserKeys());
      server.uploadInitialKeys(bob.protocolAddress, await bob.buildUserKeys());
    });

    test('Bob can send messages to all Alice\'s devices', () async {
      // Bob sends a message to Alice (should go to all her devices)
      await bob.deliver('alice', 'Hello to all Alice\'s devices', server);

      // Both Alice's devices should receive the message
      final alicePhoneMessages = await alice.receiveMessages(server);
      final aliceLaptopMessages = await aliceLaptop.receiveMessages(server);

      expect(alicePhoneMessages, ['Hello to all Alice\'s devices']);
      expect(aliceLaptopMessages, ['Hello to all Alice\'s devices']);

      // Alice's phone responds
      await alice.deliver('bob', 'Hello from my phone', server);

      // Alice's laptop also responds
      await aliceLaptop.deliver('bob', 'Hello from my laptop', server);

      // Bob should receive both messages
      final bobMessages = await bob.receiveMessages(server);
      expect(bobMessages.length, 2);
      expect(bobMessages, contains('Hello from my phone'));
      expect(bobMessages, contains('Hello from my laptop'));
    });

    test('Alice\'s devices maintain separate sessions with Bob', () async {
      // Bob sends a message to all Alice's devices
      await bob.deliver('alice', 'Hello Alice on all devices', server);

      // Verify both devices got the message
      final alicePhoneMessages = await alice.receiveMessages(server);
      final aliceLaptopMessages = await aliceLaptop.receiveMessages(server);

      expect(alicePhoneMessages, ['Hello Alice on all devices']);
      expect(aliceLaptopMessages, ['Hello Alice on all devices']);

      // Each device should have its own session with Bob
      await alice.deliver('bob', 'Message 1 from phone', server);
      await alice.deliver('bob', 'Message 2 from phone', server);
      await aliceLaptop.deliver('bob', 'Message 1 from laptop', server);
      await aliceLaptop.deliver('bob', 'Message 2 from laptop', server);

      // Bob receives all messages
      final bobMessages = await bob.receiveMessages(server);
      expect(bobMessages.length, 4);
      expect(
        bobMessages,
        containsAll(['Message 1 from phone', 'Message 2 from phone', 'Message 1 from laptop', 'Message 2 from laptop']),
      );
    });
  });
}
