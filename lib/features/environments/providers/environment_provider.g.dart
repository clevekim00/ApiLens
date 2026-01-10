// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$environmentRepositoryHash() =>
    r'1da1659f3e553539f57c08e3765bc9b8e4ce5e79';

/// See also [environmentRepository].
@ProviderFor(environmentRepository)
final environmentRepositoryProvider =
    AutoDisposeProvider<EnvironmentRepository>.internal(
  environmentRepository,
  name: r'environmentRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$environmentRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EnvironmentRepositoryRef
    = AutoDisposeProviderRef<EnvironmentRepository>;
String _$activeEnvironmentIdHash() =>
    r'3f3e6ec9435f3297052e8ebc1f20f9e2a5e3382c';

/// See also [ActiveEnvironmentId].
@ProviderFor(ActiveEnvironmentId)
final activeEnvironmentIdProvider =
    AutoDisposeNotifierProvider<ActiveEnvironmentId, Id?>.internal(
  ActiveEnvironmentId.new,
  name: r'activeEnvironmentIdProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeEnvironmentIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ActiveEnvironmentId = AutoDisposeNotifier<Id?>;
String _$environmentListHash() => r'b5c467ae3fdf58f6a2382f214a59593e24e01188';

/// See also [EnvironmentList].
@ProviderFor(EnvironmentList)
final environmentListProvider = AutoDisposeAsyncNotifierProvider<
    EnvironmentList, List<EnvironmentItem>>.internal(
  EnvironmentList.new,
  name: r'environmentListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$environmentListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EnvironmentList = AutoDisposeAsyncNotifier<List<EnvironmentItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
