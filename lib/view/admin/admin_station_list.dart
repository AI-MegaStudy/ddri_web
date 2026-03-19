// DDRI 관리자 대여소 목록: DataTable, 8개 shrinkWrap / 9개+ 스크롤
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/api/models/station_models.dart';
import '../../core/design_token.dart';
import '../../vm/admin_page_controller.dart';

/// 관리자 대여소 목록 (테이블 형식). _StationHeaderRow + _StationDataRow.
class AdminStationList extends StatelessWidget {
  const AdminStationList({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminPageController>();

    return Obx(() {
      if (ctrl.isLoading.value && ctrl.items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                '재배치 목록을 불러오는 중...',
                style: Theme.of(context).textTheme.bodyMedium,
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
                '대여소가 없습니다',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      final useShrinkWrap =
          ctrl.items.length <= DesignToken.adminListShrinkWrapThreshold;

      final table = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 860),
          child: Column(
            children: [
              const _StationHeaderRow(),
              ...ctrl.items.map(_StationDataRow.new),
            ],
          ),
        ),
      );

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DesignToken.primary.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ctrl.isLoading.value)
              const LinearProgressIndicator(minHeight: 2),
            useShrinkWrap
                ? table
                : SizedBox(
                    height: DesignToken.adminListMaxHeight,
                    child: SingleChildScrollView(child: table),
                  ),
          ],
        ),
      );
    });
  }
}

class _StationHeaderRow extends StatelessWidget {
  const _StationHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(
        children: [
          _Cell(width: 300, child: _HeaderText('대여소명')),
          _Cell(width: 120, child: _HeaderText('동')),
          _Cell(
            width: 90,
            alignment: Alignment.center,
            child: _HeaderText('재고'),
          ),
          _Cell(
            width: 110,
            alignment: Alignment.center,
            child: _HeaderText('예측수요'),
          ),
          _Cell(
            width: 90,
            alignment: Alignment.center,
            child: _HeaderText('차이'),
          ),
          _Cell(width: 220, child: _HeaderText('위험도')),
          _Cell(
            width: 100,
            alignment: Alignment.center,
            child: _HeaderText('우선순위'),
          ),
        ],
      ),
    );
  }
}

class _StationDataRow extends StatelessWidget {
  const _StationDataRow(this.station);

  final StationRiskItem station;

  Color get _riskColor {
    if (station.riskScore >= 0.75) return const Color(0xFFEF4444);
    if (station.riskScore >= 0.5) return const Color(0xFFF97316);
    return DesignToken.primary;
  }

  @override
  Widget build(BuildContext context) {
    final gapColor = station.stockGap < 0
        ? const Color(0xFFEF4444)
        : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          _Cell(
            width: 300,
            child: Row(
              children: [
                if (station.serviceTag.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      station.serviceTag,
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    station.stationName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _Cell(
            width: 120,
            child: Text(
              station.districtName,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          _Cell(
            width: 90,
            alignment: Alignment.center,
            child: Text(
              '${station.currentBikeStock}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _Cell(
            width: 110,
            alignment: Alignment.center,
            child: Text(
              station.predictedDemand.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          _Cell(
            width: 90,
            alignment: Alignment.center,
            child: Text(
              station.stockGap.toStringAsFixed(1),
              style: TextStyle(fontWeight: FontWeight.w800, color: gapColor),
            ),
          ),
          _Cell(
            width: 220,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: station.riskScore.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(_riskColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 36,
                  child: Text(
                    station.riskScore.toStringAsFixed(1),
                    style: TextStyle(
                      color: _riskColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _Cell(
            width: 100,
            alignment: Alignment.center,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _riskColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${station.reallocationPriority}',
                style: TextStyle(
                  color: _riskColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF475569),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.width,
    required this.child,
    this.alignment = Alignment.centerLeft,
  });

  final double width;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(alignment: alignment, child: child),
    );
  }
}
