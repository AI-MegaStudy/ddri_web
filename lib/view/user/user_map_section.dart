// DDRI 지도: flutter_map, OSM, 사용자·대여소 마커, maxZoom 16, debounce
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../common/beta/beta_mode_widgets.dart';
import '../../common/api/models/station_models.dart';
import '../../core/design_token.dart';
import '../../vm/user_page_controller.dart';

/// 주변 대여소 지도. OSM 타일, 사용자·대여소 마커, 초기화 버튼.
class UserMapSection extends StatefulWidget {
  const UserMapSection({super.key});

  @override
  State<UserMapSection> createState() => _UserMapSectionState();
}

class _UserMapSectionState extends State<UserMapSection> {
  /// 기본 뷰포트를 기존보다 약 30% 넓게 보이도록 초기 줌을 낮춘다.
  static const double _defaultZoom = 14.6;
  static const double _minZoom = 10.0;
  static const double _maxZoom = 15.75;
  static const double _zoomStep = 0.25;

  final MapController _mapController = MapController();
  late final UserPageController _ctrl;
  Worker? _focusWorker;
  Worker? _itemsWorker;
  late LatLng _currentCenter;
  double _currentZoom = _defaultZoom;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<UserPageController>();
    _currentCenter = const LatLng(37.505, 127.04);
    _focusWorker = ever<StationNearbyItem?>(_ctrl.focusedStation, (station) {
      if (station == null) return;
      unawaited(_moveToStation(station));
    });
    _itemsWorker = ever<List<StationNearbyItem>>(_ctrl.items, (items) {
      if (!_ctrl.hasLocation || items.isNotEmpty || !mounted) return;
      final userCenter = LatLng(_ctrl.lat.value!, _ctrl.lng.value!);
      _currentCenter = userCenter;
      _currentZoom = _defaultZoom;
      _mapController.move(userCenter, _defaultZoom);
    });
  }

  /// focusedStation 변경 시 해당 대여소로 지도 이동
  Future<void> _moveToStation(StationNearbyItem station) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    final center = LatLng(station.latitude, station.longitude);
    _currentCenter = center;
    _currentZoom = _maxZoom;
    _mapController.move(center, _maxZoom);
  }

  /// 지도 초기화: 사용자 위치로 이동, 포커스 해제
  void _resetMapView() {
    if (!_ctrl.hasLocation) return;
    final userCenter = LatLng(_ctrl.lat.value!, _ctrl.lng.value!);
    _ctrl.clearFocusedStation();
    _currentCenter = userCenter;
    _currentZoom = _defaultZoom;
    _mapController.move(userCenter, _defaultZoom);
  }

  void _zoomBy(double delta) {
    final nextZoom = (_currentZoom + delta).clamp(_minZoom, _maxZoom);
    _currentZoom = nextZoom;
    _mapController.move(_currentCenter, nextZoom);
  }

  bool get _canZoomIn => _currentZoom < (_maxZoom - 0.001);
  bool get _canZoomOut => _currentZoom > (_minZoom + 0.001);

  @override
  void dispose() {
    _focusWorker?.dispose();
    _itemsWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;

    return Obx(() {
      if (!ctrl.hasLocation) {
        return _MapPlaceholder(ctrl: ctrl);
      }

      final userCenter = LatLng(ctrl.lat.value!, ctrl.lng.value!);
      final stationMarkers = ctrl.items
          .map(
            (station) => Marker(
              point: LatLng(station.latitude, station.longitude),
              width: 30,
              height: 38,
              child: _StationMarker(
                level: station.availabilityLevel,
                selected:
                    ctrl.focusedStation.value?.stationId == station.stationId,
              ),
            ),
          )
          .toList();

      return LayoutBuilder(
        builder: (context, constraints) {
          final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : DesignToken.userMapMinHeight;
          return SizedBox(
            height: h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ctrl.isBetaMode)
                  const BetaModeHelperText(text: '지도에는 베타 대상 대여소만 표시됩니다.'),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: DesignToken.primary.withValues(alpha: 0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        RepaintBoundary(
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: userCenter,
                              initialZoom: _defaultZoom,
                              minZoom: _minZoom,
                              maxZoom: _maxZoom,
                              interactionOptions: const InteractionOptions(
                                // 웹에서는 지도 위 마우스 휠이 페이지 스크롤을 막기 쉬워서 비활성화한다.
                                flags:
                                    InteractiveFlag.all &
                                    ~InteractiveFlag.scrollWheelZoom,
                              ),
                              onPositionChanged: (position, _) {
                                _currentCenter = position.center;
                                _currentZoom = position.zoom;
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'ddri_web',
                                maxNativeZoom: 16,
                                keepBuffer: 1,
                                panBuffer: 0,
                                tileUpdateTransformer:
                                    TileUpdateTransformers.debounce(
                                      const Duration(milliseconds: 80),
                                    ),
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: userCenter,
                                    width: 26,
                                    height: 26,
                                    child: const _UserMarker(),
                                  ),
                                  ...stationMarkers,
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              '주변 대여소 지도',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF334155),
                                  ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Column(
                            children: [
                              _MapActionButton(
                                onPressed: _canZoomIn
                                    ? () => _zoomBy(_zoomStep)
                                    : null,
                                icon: Icons.add,
                                tooltip: '지도 확대',
                              ),
                              const SizedBox(height: 8),
                              _MapActionButton(
                                onPressed: _canZoomOut
                                    ? () => _zoomBy(-_zoomStep)
                                    : null,
                                icon: Icons.remove,
                                tooltip: '지도 축소',
                              ),
                              const SizedBox(height: 8),
                              _MapActionButton(
                                onPressed: _resetMapView,
                                icon: Icons.refresh,
                                tooltip: '지도 초기화',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(999),
      elevation: 1,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
        color: const Color(0xFF334155),
      ),
    );
  }
}

/// 지도 없을 때 플레이스홀더: 공간 유지 + 현 위치/주소 검색 유도
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.ctrl});

  final UserPageController ctrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : DesignToken.userMapMinHeight;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignToken.primary.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Obx(() {
            if (ctrl.isLoadingLocation.value) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      '위치를 불러오는 중...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '위치를 선택해 주세요',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '현 위치 또는 주소 검색으로 대여소를 조회할 수 있습니다',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => ctrl.fetchCurrentLocation(),
                      icon: const Icon(Icons.my_location, size: 20),
                      label: const Text('현 위치로 찾기'),
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignToken.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _StationMarker extends StatelessWidget {
  const _StationMarker({required this.level, required this.selected});

  final String level;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (level) {
      case 'sufficient':
        color = DesignToken.badgeSufficient;
        break;
      case 'normal':
        color = DesignToken.badgeNormal;
        break;
      default:
        color = DesignToken.badgeLow;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: selected ? 28 : 24,
          height: selected ? 28 : 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: selected ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: selected ? 8 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.pedal_bike, size: 13, color: Colors.white),
        ),
        Container(width: 2, height: 10, color: color.withValues(alpha: 0.9)),
      ],
    );
  }
}

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
