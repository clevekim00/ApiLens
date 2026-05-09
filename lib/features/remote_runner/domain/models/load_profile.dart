enum LoadDistributionPolicy {
  equalSplit,
  capacityWeighted,
}

class LoadProfile {
  final int virtualUsers;
  final int durationSeconds;
  final int rampUpSeconds;
  final int iterations;
  final int thinkTimeMs;
  final int? concurrencyCap;
  final LoadDistributionPolicy distributionPolicy;

  const LoadProfile({
    required this.virtualUsers,
    required this.durationSeconds,
    this.rampUpSeconds = 0,
    this.iterations = 1,
    this.thinkTimeMs = 0,
    this.concurrencyCap,
    this.distributionPolicy = LoadDistributionPolicy.capacityWeighted,
  });

  Map<String, dynamic> toJson() => {
        'virtualUsers': virtualUsers,
        'durationSeconds': durationSeconds,
        'rampUpSeconds': rampUpSeconds,
        'iterations': iterations,
        'thinkTimeMs': thinkTimeMs,
        'concurrencyCap': concurrencyCap,
        'distributionPolicy': distributionPolicy.name,
      };

  factory LoadProfile.fromJson(Map<String, dynamic> json) {
    return LoadProfile(
      virtualUsers: (json['virtualUsers'] as num?)?.toInt() ?? 0,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      rampUpSeconds: (json['rampUpSeconds'] as num?)?.toInt() ?? 0,
      iterations: (json['iterations'] as num?)?.toInt() ?? 1,
      thinkTimeMs: (json['thinkTimeMs'] as num?)?.toInt() ?? 0,
      concurrencyCap: (json['concurrencyCap'] as num?)?.toInt(),
      distributionPolicy: LoadDistributionPolicy.values.firstWhere(
        (policy) => policy.name == json['distributionPolicy'],
        orElse: () => LoadDistributionPolicy.capacityWeighted,
      ),
    );
  }
}
