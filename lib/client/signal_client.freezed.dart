// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'signal_client.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SignalClient {

 SignalProtocolAddress get protocolAddress; SessionStore get sessionStore; PreKeyStore get preKeyStore; SignedPreKeyStore get signedPreKeyStore; IdentityKeyStore get identityStore; SenderKeyStore get groupSenderKeyStore;
/// Create a copy of SignalClient
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignalClientCopyWith<SignalClient> get copyWith => _$SignalClientCopyWithImpl<SignalClient>(this as SignalClient, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignalClient&&(identical(other.protocolAddress, protocolAddress) || other.protocolAddress == protocolAddress)&&(identical(other.sessionStore, sessionStore) || other.sessionStore == sessionStore)&&(identical(other.preKeyStore, preKeyStore) || other.preKeyStore == preKeyStore)&&(identical(other.signedPreKeyStore, signedPreKeyStore) || other.signedPreKeyStore == signedPreKeyStore)&&(identical(other.identityStore, identityStore) || other.identityStore == identityStore)&&(identical(other.groupSenderKeyStore, groupSenderKeyStore) || other.groupSenderKeyStore == groupSenderKeyStore));
}


@override
int get hashCode => Object.hash(runtimeType,protocolAddress,sessionStore,preKeyStore,signedPreKeyStore,identityStore,groupSenderKeyStore);

@override
String toString() {
  return 'SignalClient(protocolAddress: $protocolAddress, sessionStore: $sessionStore, preKeyStore: $preKeyStore, signedPreKeyStore: $signedPreKeyStore, identityStore: $identityStore, groupSenderKeyStore: $groupSenderKeyStore)';
}


}

/// @nodoc
abstract mixin class $SignalClientCopyWith<$Res>  {
  factory $SignalClientCopyWith(SignalClient value, $Res Function(SignalClient) _then) = _$SignalClientCopyWithImpl;
@useResult
$Res call({
 SignalProtocolAddress protocolAddress, SessionStore sessionStore, PreKeyStore preKeyStore, SignedPreKeyStore signedPreKeyStore, IdentityKeyStore identityStore, SenderKeyStore groupSenderKeyStore
});




}
/// @nodoc
class _$SignalClientCopyWithImpl<$Res>
    implements $SignalClientCopyWith<$Res> {
  _$SignalClientCopyWithImpl(this._self, this._then);

  final SignalClient _self;
  final $Res Function(SignalClient) _then;

/// Create a copy of SignalClient
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? protocolAddress = null,Object? sessionStore = null,Object? preKeyStore = null,Object? signedPreKeyStore = null,Object? identityStore = null,Object? groupSenderKeyStore = null,}) {
  return _then(_self.copyWith(
protocolAddress: null == protocolAddress ? _self.protocolAddress : protocolAddress // ignore: cast_nullable_to_non_nullable
as SignalProtocolAddress,sessionStore: null == sessionStore ? _self.sessionStore : sessionStore // ignore: cast_nullable_to_non_nullable
as SessionStore,preKeyStore: null == preKeyStore ? _self.preKeyStore : preKeyStore // ignore: cast_nullable_to_non_nullable
as PreKeyStore,signedPreKeyStore: null == signedPreKeyStore ? _self.signedPreKeyStore : signedPreKeyStore // ignore: cast_nullable_to_non_nullable
as SignedPreKeyStore,identityStore: null == identityStore ? _self.identityStore : identityStore // ignore: cast_nullable_to_non_nullable
as IdentityKeyStore,groupSenderKeyStore: null == groupSenderKeyStore ? _self.groupSenderKeyStore : groupSenderKeyStore // ignore: cast_nullable_to_non_nullable
as SenderKeyStore,
  ));
}

}


/// @nodoc


class _SignalClient extends SignalClient {
  const _SignalClient({required this.protocolAddress, required this.sessionStore, required this.preKeyStore, required this.signedPreKeyStore, required this.identityStore, required this.groupSenderKeyStore}): super._();
  

@override final  SignalProtocolAddress protocolAddress;
@override final  SessionStore sessionStore;
@override final  PreKeyStore preKeyStore;
@override final  SignedPreKeyStore signedPreKeyStore;
@override final  IdentityKeyStore identityStore;
@override final  SenderKeyStore groupSenderKeyStore;

/// Create a copy of SignalClient
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignalClientCopyWith<_SignalClient> get copyWith => __$SignalClientCopyWithImpl<_SignalClient>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignalClient&&(identical(other.protocolAddress, protocolAddress) || other.protocolAddress == protocolAddress)&&(identical(other.sessionStore, sessionStore) || other.sessionStore == sessionStore)&&(identical(other.preKeyStore, preKeyStore) || other.preKeyStore == preKeyStore)&&(identical(other.signedPreKeyStore, signedPreKeyStore) || other.signedPreKeyStore == signedPreKeyStore)&&(identical(other.identityStore, identityStore) || other.identityStore == identityStore)&&(identical(other.groupSenderKeyStore, groupSenderKeyStore) || other.groupSenderKeyStore == groupSenderKeyStore));
}


@override
int get hashCode => Object.hash(runtimeType,protocolAddress,sessionStore,preKeyStore,signedPreKeyStore,identityStore,groupSenderKeyStore);

@override
String toString() {
  return 'SignalClient(protocolAddress: $protocolAddress, sessionStore: $sessionStore, preKeyStore: $preKeyStore, signedPreKeyStore: $signedPreKeyStore, identityStore: $identityStore, groupSenderKeyStore: $groupSenderKeyStore)';
}


}

/// @nodoc
abstract mixin class _$SignalClientCopyWith<$Res> implements $SignalClientCopyWith<$Res> {
  factory _$SignalClientCopyWith(_SignalClient value, $Res Function(_SignalClient) _then) = __$SignalClientCopyWithImpl;
@override @useResult
$Res call({
 SignalProtocolAddress protocolAddress, SessionStore sessionStore, PreKeyStore preKeyStore, SignedPreKeyStore signedPreKeyStore, IdentityKeyStore identityStore, SenderKeyStore groupSenderKeyStore
});




}
/// @nodoc
class __$SignalClientCopyWithImpl<$Res>
    implements _$SignalClientCopyWith<$Res> {
  __$SignalClientCopyWithImpl(this._self, this._then);

  final _SignalClient _self;
  final $Res Function(_SignalClient) _then;

/// Create a copy of SignalClient
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? protocolAddress = null,Object? sessionStore = null,Object? preKeyStore = null,Object? signedPreKeyStore = null,Object? identityStore = null,Object? groupSenderKeyStore = null,}) {
  return _then(_SignalClient(
protocolAddress: null == protocolAddress ? _self.protocolAddress : protocolAddress // ignore: cast_nullable_to_non_nullable
as SignalProtocolAddress,sessionStore: null == sessionStore ? _self.sessionStore : sessionStore // ignore: cast_nullable_to_non_nullable
as SessionStore,preKeyStore: null == preKeyStore ? _self.preKeyStore : preKeyStore // ignore: cast_nullable_to_non_nullable
as PreKeyStore,signedPreKeyStore: null == signedPreKeyStore ? _self.signedPreKeyStore : signedPreKeyStore // ignore: cast_nullable_to_non_nullable
as SignedPreKeyStore,identityStore: null == identityStore ? _self.identityStore : identityStore // ignore: cast_nullable_to_non_nullable
as IdentityKeyStore,groupSenderKeyStore: null == groupSenderKeyStore ? _self.groupSenderKeyStore : groupSenderKeyStore // ignore: cast_nullable_to_non_nullable
as SenderKeyStore,
  ));
}


}

// dart format on
