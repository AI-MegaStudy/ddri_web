// DDRI 날씨: 주간 예보, 선택 시각 상세, /v1/weather 연동
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/api/models/station_models.dart';
import '../../core/design_token.dart';
import '../../vm/user_page_controller.dart';

/// 주간 날씨 + 선택 시각 날씨. 재시도 버튼 포함.
class UserWeatherSection extends StatelessWidget {
  const UserWeatherSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UserPageController>();

    return Obx(() {
      if (!ctrl.hasLocation) return const SizedBox.shrink();
      final hasError =
          ctrl.weatherErrorMessage.value.isNotEmpty &&
          ctrl.weeklyForecast.isEmpty &&
          ctrl.selectedForecast.value == null;
      final hasContent =
          ctrl.weeklyForecast.isNotEmpty || ctrl.selectedForecast.value != null;
      final isInitialLoading =
          ctrl.isLoadingWeather.value && !hasError && !hasContent;

      if (!hasError && !hasContent && !isInitialLoading) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignToken.cardBackground,
          borderRadius: BorderRadius.circular(DesignToken.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                    Expanded(
                      child: Text(
                        '이번 주 날씨',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
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
              const SizedBox(height: 16),
              if (isInitialLoading)
                const Center(child: CircularProgressIndicator())
              else if (hasError)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ctrl.weatherErrorMessage.value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: ctrl.isLoadingWeather.value
                          ? null
                          : ctrl.retryWeather,
                      icon: const Icon(Icons.refresh),
                      tooltip: '날씨 재시도',
                    ),
                  ],
                )
              else ...[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 1100
                        ? 7
                        : width >= 700
                        ? 4
                        : 4;
                    final mainAxisExtent = width >= 1100
                        ? 176.0
                        : width >= 700
                        ? 182.0
                        : width >= DesignToken.breakpointTablet
                        ? 150.0
                        : 146.0;

                    final compact = width < DesignToken.breakpointTablet;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ctrl.weeklyForecast.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: compact ? 6 : 10,
                        mainAxisSpacing: compact ? 6 : 10,
                        mainAxisExtent: mainAxisExtent,
                      ),
                      itemBuilder: (_, index) {
                        final item = ctrl.weeklyForecast[index];
                        return _WeeklyWeatherCard(item: item, compact: compact);
                      },
                    );
                  },
                ),
                if (ctrl.selectedForecast.value != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    '선택 시간 예상 날씨',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SelectedWeatherCard(item: ctrl.selectedForecast.value!),
                ],
              ],
            ],
          ],
        ),
      );
    });
  }
}

class _WeeklyWeatherCard extends StatelessWidget {
  const _WeeklyWeatherCard({required this.item, this.compact = false});

  final WeatherDayItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(item.weatherDatetime);
    final weekday = date == null ? '' : _weekdayLabel(date.weekday);
    final label = date == null
        ? item.weatherDatetime
        : '$weekday ${date.month}/${date.day}';
    final dateColor = date == null
        ? Colors.grey.shade700
        : _weekdayColor(date.weekday);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tight =
            compact ||
            constraints.maxHeight <= 126 ||
            constraints.maxWidth <= 132;
        final horizontalPadding = tight ? 6.0 : 10.0;
        final verticalPadding = tight ? 6.0 : 10.0;
        final iconSize = tight ? 28.0 : 34.0;
        final gap1 = tight ? 4.0 : 6.0;
        final gap2 = tight ? 2.0 : 4.0;
        final titleFont = tight ? 11.0 : 12.0;
        final metaFont = tight ? 10.0 : 11.0;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(tight ? 8 : 12),
            border: Border.all(color: Colors.grey.shade200),
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
                  fontSize: titleFont,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: gap1),
              SizedBox(
                width: iconSize,
                height: iconSize,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Icon(
                    _weatherIcon(item.weatherType),
                    color: _weatherColor(item.weatherType),
                  ),
                ),
              ),
              SizedBox(height: gap2),
              Text(
                item.weatherType,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: titleFont,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: gap2),
              Text(
                '${item.weatherLow.toStringAsFixed(0)}°/${item.weatherHigh.toStringAsFixed(0)}°',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: titleFont,
                  height: 1.05,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: gap2),
              Text(
                '강수 ${item.precipitationProbability.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blueGrey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: metaFont,
                  height: 1.05,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectedWeatherCard extends StatelessWidget {
  const _SelectedWeatherCard({required this.item});

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
