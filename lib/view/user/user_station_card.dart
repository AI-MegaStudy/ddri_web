// DDRI 대여소 카드: 배지, 거리, 자전거 수, 길찾기, 지도 포커스 연동
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/api/models/station_models.dart';
import '../../common/map/map_directions_launcher.dart';
import '../../core/design_token.dart';
import '../../vm/user_page_controller.dart';

/// 대여소 카드: 배지, 거리, 자전거 수, 길찾기.
/// 포커스 시 테두리 하이라이트.
class UserStationCard extends StatelessWidget {
  const UserStationCard({super.key, required this.station});

  final StationNearbyItem station;

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor(station.availabilityLevel);
    final badgeLabel = _badgeLabel(station.availabilityLevel);
    final ctrl = Get.find<UserPageController>();

    return Obx(() {
      final isFocused =
          ctrl.focusedStation.value?.stationId == station.stationId;

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignToken.cardRadius),
          side: BorderSide(
            color: isFocused
                ? DesignToken.primary.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        elevation: DesignToken.cardElevation,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignToken.cardRadius),
          onTap: () => ctrl.focusStation(station),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (station.serviceTag.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1D4ED8,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          station.serviceTag,
                          style: const TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDistance(station.distanceM),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => launchMapDirections(
                        lat: station.latitude,
                        lng: station.longitude,
                        destinationTitle: station.stationName,
                      ),
                      icon: const Icon(Icons.directions, color: Colors.blue),
                      tooltip: '길찾기',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  station.stationName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (station.address.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    station.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _InfoChip(label: '현재 ${station.currentBikeStock}대'),
                    _InfoChip(
                      label:
                          '예상 잔여 ${station.predictedRemainingBikes.toStringAsFixed(1)}대',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// 가용성 수준별 배지 색상 (sufficient/normal/low)
  Color _badgeColor(String level) {
    switch (level) {
      case 'sufficient':
        return DesignToken.badgeSufficient;
      case 'normal':
        return DesignToken.badgeNormal;
      default:
        return DesignToken.badgeLow;
    }
  }

  /// 가용성 수준별 배지 라벨
  String _badgeLabel(String level) {
    switch (level) {
      case 'sufficient':
        return '대여가능';
      case 'normal':
        return '보통';
      default:
        return '부족';
    }
  }

  /// 거리 포맷 (m → km)
  String _formatDistance(double m) {
    if (m >= 1000) {
      return '${(m / 1000).toStringAsFixed(1)}km';
    }
    return '${m.round()}m';
  }
}

/// 정보 칩 (현재 N대, 예상 잔여 N대 등)
class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
