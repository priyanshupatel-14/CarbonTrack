class CarbonSummary {
  final double totalCo2e;
  final double transportationCo2e;
  final double electricityCo2e;
  final double foodCo2e;
  final double wasteCo2e;
  final String reportingPeriod;

  CarbonSummary({
    required this.totalCo2e,
    required this.transportationCo2e,
    required this.electricityCo2e,
    required this.foodCo2e,
    required this.wasteCo2e,
    required this.reportingPeriod,
  });

  factory CarbonSummary.fromJson(Map<String, dynamic> json) {
    return CarbonSummary(
      totalCo2e: (json['totalCo2e'] as num?)?.toDouble() ?? 0.0,
      transportationCo2e: (json['transportationCo2e'] as num?)?.toDouble() ?? 0.0,
      electricityCo2e: (json['electricityCo2e'] as num?)?.toDouble() ?? 0.0,
      foodCo2e: (json['foodCo2e'] as num?)?.toDouble() ?? 0.0,
      wasteCo2e: (json['wasteCo2e'] as num?)?.toDouble() ?? 0.0,
      reportingPeriod: json['reportingPeriod']?.toString() ?? 'Current Period',
    );
  }
}
