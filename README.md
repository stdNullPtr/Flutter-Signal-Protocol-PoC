# Flutter Signal Protocol Client - Proof of Concept

A proof-of-concept implementation of the Signal Protocol in Flutter/Dart, demonstrating end-to-end encrypted messaging through executable test scenarios.

## 🎯 Purpose

This repository serves as a technical demonstration of Signal Protocol implementation in Dart. Rather than being a runnable application, it provides a comprehensive test suite that showcases:

- Complete Signal Protocol implementation
- Key exchange mechanisms
- Session establishment
- Message encryption/decryption
- Multi-user communication scenarios

**Important**: This codebase is designed to be explored through its test suite. The tests serve as living documentation and executable examples of the Signal Protocol implementation.

## 📋 Requirements

- Flutter `>=3.7.2`
- Dart `>=3.7.2`
- A running instance of the Signal Protocol server (for integration tests)

## 🛠️ Installation

```bash
# Clone the repository
git clone https://github.com/stdNullPtr/flutter_signal_protocol_client_poc
cd flutter_signal_protocol_client_poc

# Install dependencies
flutter pub get

# Generate Freezed code
dart run build_runner build
```

## 🏗️ Architecture

### Core Implementation

#### `SignalClient` (`lib/client/signal_client.dart`)
The main Signal Protocol implementation featuring:
- Identity key pair generation and management
- PreKey bundle creation and distribution
- Session establishment with other users
- Message encryption using the Double Ratchet algorithm
- Message decryption and session management

#### `SignalClientState` (`lib/client/signal_client.freezed.dart`)
Immutable state management using Freezed, containing:
- User identity keys
- PreKey and signed PreKey stores
- Active sessions cache
- Pending messages queue
- One-time PreKey management

### Supporting Infrastructure

#### Data Models
- `UserKeys` (`lib/server/models/user_keys.dart`): Represents a user's PreKey bundle for key exchange
- `Message` (`lib/common/models/message.dart`): Encapsulates encrypted message data
- `PublicPreKey` & `PublicSignedPreKey` (`lib/server/models/`): Key structures for exchange

#### (Mock) Server Communication (`lib/server/server.dart`)
- PreKey bundle upload and retrieval
- Encrypted message routing
- Message acknowledgment handling

#### Utilities
- `Logger` (`lib/utils/logger.dart`): Logging utility for debugging

### Project Structure

```
lib/
├── client/
│   ├── signal_client.dart         # Signal Protocol implementation
│   └── signal_client.freezed.dart # Generated immutable state
├── common/
│   └── models/
│       ├── message.dart           # Message structure
│       └── group_message.dart     # Group message support
├── server/
│   ├── models/
│   │   ├── user_keys.dart         # PreKey bundle model
│   │   ├── public_prekey.dart     # Public PreKey structure
│   │   └── public_signed_prekey.dart # Signed PreKey structure
│   └── server.dart                # Server API client
└── utils/
    └── logger.dart                # Logging utility

test/
├── signal_protocol_test.dart      # Comprehensive test scenarios
└── key_reuse_test.dart            # Tests for key reuse prevention
```

## 🧪 Understanding the Implementation Through Tests

The test suites serve as the primary documentation for this PoC. Each test file demonstrates specific aspects of the Signal Protocol:
- `test/signal_protocol_test.dart`: Core protocol implementation scenarios
- `test/key_reuse_test.dart`: Security tests for preventing key reuse attacks

### Running the Test Suite

```bash
# Run all test scenarios
flutter test

# Run with verbose output to see the implementation in action
flutter test --reporter expanded

# Run a specific test scenario
flutter test --name "should establish session and exchange messages"
```

### Test Scenarios

1. **Basic Key Generation**
   - Demonstrates identity key creation
   - Shows PreKey bundle generation
   - Validates cryptographic material

2. **PreKey Bundle Exchange**
   - Shows how users publish their PreKey bundles
   - Demonstrates bundle retrieval from server
   - Validates bundle integrity

3. **Session Establishment**
   - Illustrates initial session creation
   - Shows the X3DH key agreement protocol
   - Demonstrates session caching

4. **Message Exchange**
   - Shows complete message encryption flow
   - Demonstrates the Double Ratchet algorithm
   - Illustrates message decryption

5. **Multi-User Scenarios**
   - Complex interactions between multiple users
   - Concurrent session management
   - Message ordering and delivery

6. **Key Reuse Prevention** (in `key_reuse_test.dart`)
   - Ensures one-time PreKeys are not reused
   - Validates security against key reuse attacks
   - Tests proper key rotation mechanisms

Each test includes comprehensive logging that explains what's happening at each step of the protocol.

## 🔍 Key Components Explained

### Signal Protocol Implementation

The implementation follows the Signal Protocol specification:

1. **Identity Keys**: Long-term Curve25519 key pairs
2. **Signed PreKey**: Medium-term keys with signatures
3. **One-Time PreKeys**: Ephemeral keys for perfect forward secrecy
4. **Sessions**: Established using X3DH (Extended Triple Diffie-Hellman)
5. **Double Ratchet**: Provides forward secrecy and break-in recovery

### State Management

Uses Freezed for immutable state management:
- Ensures thread safety
- Prevents accidental state mutations
- Provides efficient state updates through copying

### Server Integration

The implementation requires a compatible server that:
- Stores and serves PreKey bundles
- Routes encrypted messages between users
- Never has access to plaintext content

## 🔒 Security Considerations

This PoC demonstrates the following security properties:

- **End-to-End Encryption**: Messages are encrypted on the sender's device and decrypted on the recipient's device
- **Perfect Forward Secrecy**: Compromised keys don't affect past communications
- **Break-in Recovery**: Compromised keys don't affect future communications
- **Deniable Authentication**: Messages can be authenticated by the recipient but anyone could have forged messages after the conversation - protecting users from being cryptographically proven to have sent a message

## 🚦 What This PoC Demonstrates

✅ Complete Signal Protocol implementation in Dart  
✅ Proper key management and rotation  
✅ Session establishment between users  
✅ Message encryption and decryption  
✅ Multi-user communication patterns  
✅ Server integration for key exchange  

## 🚫 What This PoC Doesn't Include

❌ User interface implementation  
❌ Persistent storage of keys and sessions  
❌ Production-ready error handling  
❌ Message delivery guarantees  
❌ Group messaging  
❌ Media/file encryption  

## 📚 Learning from the Code

To understand the Signal Protocol implementation:

1. Start with the main test file: `test/signal_protocol_test.dart`
2. Follow the test scenarios in order
3. Review security tests in `test/key_reuse_test.dart`
4. Examine the `SignalClient` implementation in `lib/client/signal_client.dart`
5. Review the state management in `SignalClientState`
6. Understand the server interactions in `lib/server/server.dart`
7. Explore the data models in `lib/common/models/` and `lib/server/models/`

## 🔗 References

- [Signal Protocol Documentation](https://signal.org/docs/)
- [libsignal_protocol_dart](https://pub.dev/packages/libsignal_protocol_dart)
- [The X3DH Key Agreement Protocol](https://signal.org/docs/specifications/x3dh/)
- [The Double Ratchet Algorithm](https://signal.org/docs/specifications/doubleratchet/)

## 🤝 Contributing

This is a proof-of-concept implementation. Contributions should focus on:

- Improving test coverage and scenarios
- Adding clarifying documentation
- Fixing implementation issues
- Demonstrating additional protocol features

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

The GPL-3.0 license ensures that:
- Source code must be made available when distributed
- Modifications must be released under the same license
- Commercial use is allowed only if the source code is provided
- Patent rights are granted to users

---

This proof-of-concept demonstrates how the Signal Protocol can be implemented in Flutter/Dart. Explore the test suite to understand the implementation details.
