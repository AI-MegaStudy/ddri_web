// DDRI API 응답 모델: StationNearbyItem, StationRiskItem, StationMasterItem, WeatherDayItem
/// 근처 대여소 1건 (사용자 페이지)
class StationNearbyItem {
  const StationNearbyItem({
    required this.stationId,
    required this.stationName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceM,
    required this.currentBikeStock,
    required this.predictedRentalCount,
    required this.predictedRemainingBikes,
    required this.bikeAvailabilityFlag,
    required this.availabilityLevel,
    required this.operationalStatus,
    required this.serviceTag,
  });

  final int stationId;
  final String stationName;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceM;
  final int currentBikeStock;
  final double predictedRentalCount;
  final double predictedRemainingBikes;
  final bool bikeAvailabilityFlag;

  /// sufficient | normal | low
  final String availabilityLevel;
  final String operationalStatus;
  final String serviceTag;

  factory StationNearbyItem.fromJson(Map<String, dynamic> json) {
    return StationNearbyItem(
      stationId: json['station_id'] as int,
      stationName: json['station_name'] as String,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      distanceM: (json['distance_m'] as num).toDouble(),
      currentBikeStock: json['current_bike_stock'] as int? ?? 0,
      predictedRentalCount:
          (json['predicted_rental_count'] as num?)?.toDouble() ?? 0,
      predictedRemainingBikes:
          (json['predicted_remaining_bikes'] as num?)?.toDouble() ?? 0,
      bikeAvailabilityFlag: json['bike_availability_flag'] as bool? ?? false,
      availabilityLevel: json['availability_level'] as String? ?? 'low',
      operationalStatus: json['operational_status'] as String? ?? '',
      serviceTag: json['service_tag'] as String? ?? '',
    );
  }
}

/// 위험 대여소 1건 (관리자 페이지)
class StationRiskItem {
  const StationRiskItem({
    required this.stationId,
    required this.stationName,
    required this.districtName,
    required this.clusterCode,
    required this.latitude,
    required this.longitude,
    required this.currentBikeStock,
    required this.predictedDemand,
    required this.stockGap,
    required this.riskScore,
    required this.reallocationPriority,
    required this.operationalStatus,
    required this.serviceTag,
  });

  final int stationId;
  final String stationName;
  final String districtName;
  final String clusterCode;
  final double latitude;
  final double longitude;
  final int currentBikeStock;
  final double predictedDemand;
  final double stockGap;
  final double riskScore;
  final int reallocationPriority;
  final String operationalStatus;
  final String serviceTag;

  factory StationRiskItem.fromJson(Map<String, dynamic> json) {
    return StationRiskItem(
      stationId: json['station_id'] as int,
      stationName: json['station_name'] as String,
      districtName: json['district_name'] as String? ?? '',
      clusterCode: json['cluster_code'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      currentBikeStock: json['current_bike_stock'] as int? ?? 0,
      predictedDemand: (json['predicted_demand'] as num?)?.toDouble() ?? 0,
      stockGap: (json['stock_gap'] as num?)?.toDouble() ?? 0,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0,
      reallocationPriority: json['reallocation_priority'] as int? ?? 0,
      operationalStatus: json['operational_status'] as String? ?? '',
      serviceTag: json['service_tag'] as String? ?? '',
    );
  }
}

/// 스테이션 마스터 1건
class StationMasterItem {
  const StationMasterItem({
    required this.stationId,
    required this.apiStationId,
    required this.stationName,
    required this.districtName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.clusterCode,
    required this.operationalStatus,
    required this.serviceTag,
  });

  final int stationId;
  final String apiStationId;
  final String stationName;
  final String districtName;
  final String address;
  final double latitude;
  final double longitude;
  final String clusterCode;
  final String operationalStatus;
  final String serviceTag;

  factory StationMasterItem.fromJson(Map<String, dynamic> json) {
    return StationMasterItem(
      stationId: json['station_id'] as int,
      apiStationId: json['api_station_id'] as String? ?? '',
      stationName: json['station_name'] as String,
      districtName: json['district_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      clusterCode: json['cluster_code'] as String? ?? '',
      operationalStatus: json['operational_status'] as String? ?? '',
      serviceTag: json['service_tag'] as String? ?? '',
    );
  }
}

/// 날씨 1건 (일별 또는 시각별)
class WeatherDayItem {
  const WeatherDayItem({
    required this.weatherDatetime,
    required this.weatherType,
    required this.weatherLow,
    required this.weatherHigh,
    required this.precipitationProbability,
    required this.iconUrl,
    this.temperature,
  });

  final String weatherDatetime;
  final String weatherType;
  final double weatherLow;
  final double weatherHigh;
  final double precipitationProbability;
  final String iconUrl;
  final double? temperature;

  factory WeatherDayItem.fromJson(Map<String, dynamic> json) {
    return WeatherDayItem(
      weatherDatetime: json['weather_datetime'] as String? ?? '',
      weatherType: json['weather_type'] as String? ?? '',
      weatherLow: (json['weather_low'] as num?)?.toDouble() ?? 0,
      weatherHigh: (json['weather_high'] as num?)?.toDouble() ?? 0,
      precipitationProbability:
          ((json['precipitation_probability'] ??
                      json['precipitation_probability_max'])
                  as num?)
              ?.toDouble() ??
          0,
      iconUrl: json['icon_url'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble(),
    );
  }
}
