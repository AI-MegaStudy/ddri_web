import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../common/api/models/station_models.dart';
import '../../core/design_token.dart';
import '../../utils/ddri_debug.dart';
import '../../vm/admin_page_controller.dart';

/// 관리자 지도: 현재 필터 결과를 마커로 표시하고 선택 행과 연동한다.
class AdminMapPlaceholder extends StatefulWidget {
  const AdminMapPlaceholder({super.key});

  @override
  State<AdminMapPlaceholder> createState() => _AdminMapPlaceholderState();
}

class _AdminMapPlaceholderState extends State<AdminMapPlaceholder> {
  static const double _defaultZoom = 12.8;
  static const double _minZoom = 10.0;
  static const double _maxZoom = 15.75;
  static const double _zoomStep = 0.25;

  final MapController _mapController = MapController();
  late final AdminPageController _ctrl;
  Worker? _focusWorker;
  Worker? _itemsWorker;
  late LatLng _currentCenter;
  double _currentZoom = _defaultZoom;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AdminPageController>();
    _currentCenter = const LatLng(37.505, 127.04);
    _focusWorker = ever<StationRiskItem?>(_ctrl.focusedStation, (station) {
      if (station == null) return;
      unawaited(
        _moveMap(
          center: LatLng(station.latitude, station.longitude),
          zoom: 14.8,
        ),
      );
    });
    _itemsWorker = ever<List<StationRiskItem>>(_ctrl.items, (items) {
      if (items.isEmpty || _ctrl.focusedStation.value != null) return;
      unawaited(_moveMap(center: _averageCenter(items), zoom: _defaultZoom));
    });
  }

  Future<void> _moveMap({required LatLng center, required double zoom}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    _currentCenter = center;
    _currentZoom = zoom;
    _mapController.move(center, zoom);
  }

  void _resetMapView() {
    if (_ctrl.items.isEmpty) return;
    _ctrl.focusedStation.value = null;
    final center = _averageCenter(_ctrl.items);
    _currentCenter = center;
    _currentZoom = _defaultZoom;
    _mapController.move(center, _defaultZoom);
  }

  void _zoomBy(double delta) {
    final nextZoom = (_currentZoom + delta).clamp(_minZoom, _maxZoom);
    _currentZoom = nextZoom;
    _mapController.move(_currentCenter, nextZoom);
  }

  bool get _canZoomIn => _currentZoom < (_maxZoom - 0.001);
  bool get _canZoomOut => _currentZoom > (_minZoom + 0.001);

  LatLng _averageCenter(List<StationRiskItem> items) {
    if (items.isEmpty) {
      return const LatLng(37.505, 127.04);
    }
    final avgLat =
        items.map((item) => item.latitude).reduce((a, b) => a + b) /
        items.length;
    final avgLon =
        items.map((item) => item.longitude).reduce((a, b) => a + b) /
        items.length;
    return LatLng(avgLat, avgLon);
  }

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
      ddriDebugPrint(
        '[DDRI] AdminMap build: ctrl=${ctrl.hashCode}, items=${ctrl.items.length}, focused=${ctrl.focusedStation.value?.stationId}',
      );
      if (ctrl.items.isEmpty) {
        return _EmptyAdminMap(onReset: null);
      }

      final focused = ctrl.focusedStation.value;
      final center = focused != null
          ? LatLng(focused.latitude, focused.longitude)
          : _averageCenter(ctrl.items);
      final zoom = focused != null ? 14.8 : _defaultZoom;
      _currentCenter = center;
      final markers = ctrl.items.map((station) {
        final selected = focused?.stationId == station.stationId;
        return Marker(
          point: LatLng(station.latitude, station.longitude),
          width: 34,
          height: 42,
          child: GestureDetector(
            onTap: () => ctrl.focusStation(station),
            child: _AdminStationMarker(
              selected: selected,
              riskScore: station.riskScore,
              priority: station.reallocationPriority,
            ),
          ),
        );
      }).toList();

      return Container(
        height: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignToken.primary.withValues(alpha: 0.2)),
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
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: zoom,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.scrollWheelZoom,
                ),
                onPositionChanged: (position, _) {
                  _currentCenter = position.center;
                  _currentZoom = position.zoom;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ddri_web',
                  maxNativeZoom: 16,
                  keepBuffer: 1,
                  panBuffer: 0,
                  tileUpdateTransformer: TileUpdateTransformers.debounce(
                    const Duration(milliseconds: 80),
                  ),
                ),
                MarkerLayer(markers: markers),
              ],
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
                  color: Colors.white.withValues(alpha: 0.92),
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
                  '필터 결과 지도',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    onPressed: _canZoomIn ? () => _zoomBy(_zoomStep) : null,
                    icon: Icons.add,
                    tooltip: '지도 확대',
                  ),
                  const SizedBox(height: 8),
                  _MapActionButton(
                    onPressed: _canZoomOut ? () => _zoomBy(-_zoomStep) : null,
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

class _AdminStationMarker extends StatelessWidget {
  const _AdminStationMarker({
    required this.selected,
    required this.riskScore,
    required this.priority,
  });

  final bool selected;
  final double riskScore;
  final int priority;

  Color get _color {
    if (riskScore >= 0.75) return const Color(0xFFEF4444);
    if (riskScore >= 0.5) return const Color(0xFFF97316);
    return DesignToken.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: selected ? 28 : 24,
          height: selected ? 28 : 24,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: selected ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.28),
                blurRadius: selected ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$priority',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
        Container(width: 2, height: 10, color: _color),
      ],
    );
  }
}

class _EmptyAdminMap extends StatelessWidget {
  const _EmptyAdminMap({this.onReset});

  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignToken.primary.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 42, color: Colors.blueGrey.shade300),
            const SizedBox(height: 8),
            Text(
              '표시할 대여소가 없습니다',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
