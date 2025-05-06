import 'package:flutter_signal_protocol_client_poc/client/signal_client.dart';
import 'package:flutter_signal_protocol_client_poc/server/server.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Group sender key reuse test', () async {
    final server = Server();

    final alice = await SignalClient.build('alice', 1, 1);
    final bob = await SignalClient.build('bob', 1, 1);

    server.uploadInitialKeys(alice.protocolAddress, await alice.buildUserKeys());
    server.uploadInitialKeys(bob.protocolAddress, await bob.buildUserKeys());

    const groupId = 'test-group';
    server.createGroup(groupId, [alice.protocolAddress, bob.protocolAddress]);

    // Alice sends first message (should create and distribute key)
    await alice.deliverGroupMessage(groupId, 'First message', server);

    // Alice sends second message (should reuse key)
    await alice.deliverGroupMessage(groupId, 'Second message', server);

    // Alice sends third message (should reuse key)
    await alice.deliverGroupMessage(groupId, 'Third message', server);

    // Bob receives all messages
    final bobMessages = await bob.receiveGroupMessages(server);

    // Bob should have received 3 messages but only 1 distribution message
    expect(bobMessages, ['First message', 'Second message', 'Third message']);
  });
}
