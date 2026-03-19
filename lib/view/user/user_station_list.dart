// DDRI 대여소 목록: 거리순, 로딩/빈 상태, 지도 포커스 연동
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../vm/user_page_controller.dart';
import 'user_station_card.dart';

/// 대여소 목록 (거리순). ListView + UserStationCard.
/// [sideLayout] true: 독립 스크롤 (좌우분할 시 우측 패널용)
class UserStationList extends StatelessWidget {
  const UserStationList({super.key, this.sideLayout = false});

  final bool sideLayout;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UserPageController>();

    return Obx(() {
      if (ctrl.isLoading.value && ctrl.items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('대여소 목록을 불러오는 중...'),
            ],
          ),
        );
      }

      if (!ctrl.hasLocation) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                '위치를 선택해 주세요',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                '현 위치 또는 주소 찾기로 검색하세요',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }

      if (ctrl.items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_bike,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '주변에 대여소가 없습니다',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                '반경을 넓히거나 다른 위치를 선택해 보세요',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
              ),
            ],
          ),
        );
      }

      if (sideLayout) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                ctrl.stationListTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (ctrl.isLoading.value)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: LinearProgressIndicator()),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: ctrl.items.length,
                itemBuilder: (_, i) => UserStationCard(station: ctrl.items[i]),
              ),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              ctrl.stationListTitle,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (ctrl.isLoading.value)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: LinearProgressIndicator()),
            ),
          ListView.builder(
            itemCount: ctrl.items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (_, i) => UserStationCard(station: ctrl.items[i]),
          ),
        ],
      );
    });
  }
}
