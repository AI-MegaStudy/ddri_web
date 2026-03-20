import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/api/models/station_models.dart';
import '../../core/design_token.dart';
import '../../vm/admin_page_controller.dart';

/// 관리자 페이지용 주간 날씨 + 기준 시각 상세 날씨.
class AdminWeatherSection extends StatelessWidget {
  const AdminWeatherSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminPageController>();

    return Obx(() {
      if (ctrl.weeklyForecast.isEmpty && ctrl.selectedForecast.value == null) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignToken.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DesignToken.primary.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: ctrl.toggleWeatherExpanded,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      size: 20,
                      color: DesignToken.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '운영 참고 날씨',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                      ),
                    ),
                    Icon(
                      ctrl.weatherExpanded.value
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
            if (ctrl.weatherExpanded.value) ...[
              const SizedBox(height: 6),
              Text(
                '기준 시각 판단과 재배치 우선순위 해석에 참고하는 날씨 정보입니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              if (ctrl.selectedForecast.value != null) ...[
                const SizedBox(height: 16),
                _SelectedAdminWeatherCard(item: ctrl.selectedForecast.value!),
              ],
              if (ctrl.weeklyForecast.isNotEmpty) ...[
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1120
                        ? 7
                        : width >= 820
                        ? 4
                        : 2;
                    final mainAxisExtent = width >= 820 ? 150.0 : 132.0;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ctrl.weeklyForecast.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        mainAxisExtent: mainAxisExtent,
                      ),
                      itemBuilder: (_, index) {
                        return _WeeklyAdminWeatherCard(
                          item: ctrl.weeklyForecast[index],
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      );
    });
  }
}

class _SelectedAdminWeatherCard extends StatelessWidget {
  const _SelectedAdminWeatherCard({required this.item});

  final WeatherDayItem item;

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.tryParse(item.weatherDatetime);
    final label = dt == null
        ? item.weatherDatetime
        : '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} 기준';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignToken.primary.withValues(alpha: 0.12),
            const Color(0xFFDBEAFE),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignToken.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              _weatherIcon(item.weatherType),
              color: _weatherColor(item.weatherType),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.weatherType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '강수 ${item.precipitationProbability.toStringAsFixed(0)}%'
                  '${item.temperature != null ? ' · 체감 참고 ${item.temperature!.toStringAsFixed(0)}°' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${item.weatherLow.toStringAsFixed(0)}° / ${item.weatherHigh.toStringAsFixed(0)}°',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyAdminWeatherCard extends StatelessWidget {
  const _WeeklyAdminWeatherCard({required this.item});

  final WeatherDayItem item;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(item.weatherDatetime);
    final label = date == null
        ? item.weatherDatetime
        : '${_weekdayLabel(date.weekday)} ${date.month}/${date.day}';
    final dateColor = date == null
        ? Colors.grey.shade700
        : _weekdayColor(date.weekday);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: dateColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 28,
            height: 28,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                _weatherIcon(item.weatherType),
                color: _weatherColor(item.weatherType),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.weatherType,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              fontSize: 12,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${item.weatherLow.toStringAsFixed(0)}°/${item.weatherHigh.toStringAsFixed(0)}°',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.05,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '강수 ${item.precipitationProbability.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blueGrey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.05,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

IconData _weatherIcon(String type) {
  if (type.contains('비')) return Icons.umbrella;
  if (type.contains('눈')) return Icons.ac_unit;
  if (type.contains('흐림') || type.contains('구름')) return Icons.cloud;
  return Icons.wb_sunny;
}

Color _weatherColor(String type) {
  if (type.contains('비')) return Colors.blue;
  if (type.contains('눈')) return Colors.lightBlue;
  if (type.contains('흐림') || type.contains('구름')) return Colors.blueGrey;
  return Colors.orange;
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return '월';
    case DateTime.tuesday:
      return '화';
    case DateTime.wednesday:
      return '수';
    case DateTime.thursday:
      return '목';
    case DateTime.friday:
      return '금';
    case DateTime.saturday:
      return '토';
    case DateTime.sunday:
      return '일';
    default:
      return '';
  }
}

Color _weekdayColor(int weekday) {
  if (weekday == DateTime.saturday) return Colors.blue.shade700;
  if (weekday == DateTime.sunday) return Colors.red.shade700;
  return Colors.grey.shade700;
}
