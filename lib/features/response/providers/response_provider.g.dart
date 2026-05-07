// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$apiServiceHash() => r'aae96465e0d57e457b058c0384031cdb0968086d';

/// See also [apiService].
@ProviderFor(apiService)
final apiServiceProvider = AutoDisposeProvider<ApiService>.internal(
  apiService,
  name: r'apiServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ApiServiceRef = AutoDisposeProviderRef<ApiService>;
String _$responseNotifierHash() => r'7f04dab6af22d0d32a72b2f3c393442a79d8cc0f';

/// See also [ResponseNotifier].
@ProviderFor(ResponseNotifier)
final responseNotifierProvider = AutoDisposeNotifierProvider<ResponseNotifier,
    AsyncValue<ResponseModel?>>.internal(
  ResponseNotifier.new,
  name: r'responseNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$responseNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ResponseNotifier = AutoDisposeNotifier<AsyncValue<ResponseModel?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
