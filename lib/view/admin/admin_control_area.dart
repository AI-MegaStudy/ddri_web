// DDRI 관리자 제어: 날짜/시간, 긴급만, 행정동, 정렬, 순서, 반응형
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/design_token.dart';
import '../../vm/admin_page_controller.dart';

/// 관리자 제어 영역: 기준 날짜/시간, 필터, 정렬.
class AdminControlArea extends StatelessWidget {
  const AdminControlArea({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AdminPageController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignToken.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignToken.primary.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(
                  children: [
                    _DateButton(controller: ctrl),
                    const SizedBox(width: 12),
                    _TimeButton(controller: ctrl),
                    Container(
                      width: 1,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: const Color(0xFFE2E8F0),
                    ),
                    Obx(
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: ctrl.urgentOnly.value == true,
                            onChanged: (v) =>
                                ctrl.setUrgentOnly(v ? true : null),
                            activeThumbColor: Colors.white,
                            activeTrackColor: DesignToken.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '긴급만(예상 잔여 5대 이하)',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    _SimpleDropdown(
                      label: '정렬',
                      value: ctrl.sortBy.value,
                      items: AdminPageController.sortByOptions
                          .map((k) => (k, '정렬: ${_sortByLabel(k)}'))
                          .toList(),
                      onChanged: (v) => ctrl.setSortBy(v ?? 'risk_score'),
                    ),
                    const SizedBox(width: 12),
                    _SimpleDropdown(
                      label: '행정동',
                      value: ctrl.districtName.value ?? '전체',
                      items: AdminPageController.districtOptions
                          .map((s) => (s, s == '전체' ? '행정동 전체' : s))
                          .toList(),
                      onChanged: (v) => ctrl.setDistrictName(v),
                    ),
                    const SizedBox(width: 12),
                    _SimpleDropdown(
                      label: '순서',
                      value: ctrl.sortOrder.value,
                      items: const [('desc', '내림차순'), ('asc', '오름차순')],
                      onChanged: (v) => ctrl.setSortOrder(v ?? 'desc'),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _DateButton(controller: ctrl),
                        _TimeButton(controller: ctrl),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: ctrl.urgentOnly.value == true,
                            onChanged: (v) =>
                                ctrl.setUrgentOnly(v ? true : null),
                            activeThumbColor: Colors.white,
                            activeTrackColor: DesignToken.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '긴급만(예상 잔여 5대 이하)',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _SimpleDropdown(
                          label: '정렬',
                          value: ctrl.sortBy.value,
                          items: AdminPageController.sortByOptions
                              .map((k) => (k, '정렬: ${_sortByLabel(k)}'))
                              .toList(),
                          onChanged: (v) => ctrl.setSortBy(v ?? 'risk_score'),
                        ),
                        _SimpleDropdown(
                          label: '행정동',
                          value: ctrl.districtName.value ?? '전체',
                          items: AdminPageController.districtOptions
                              .map((s) => (s, s == '전체' ? '행정동 전체' : s))
                              .toList(),
                          onChanged: (v) => ctrl.setDistrictName(v),
                        ),
                        _SimpleDropdown(
                          label: '순서',
                          value: ctrl.sortOrder.value,
                          items: const [('desc', '내림차순'), ('asc', '오름차순')],
                          onChanged: (v) => ctrl.setSortOrder(v ?? 'desc'),
                        ),
                      ],
                    ),
                  ],
                ),
              Obx(() {
                if (ctrl.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    ctrl.errorMessage.value,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  static String _sortByLabel(String k) {
    switch (k) {
      case 'risk_score':
        return '위험점수';
      case 'reallocation_priority':
        return '우선순위';
      case 'stock_gap':
        return '재고차이';
      default:
        return k;
    }
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.controller});

  final AdminPageController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DesignToken.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _pickDate(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 18,
                color: DesignToken.primary,
              ),
              const SizedBox(width: 8),
              Obx(() {
                final dt = controller.baseDatetime.value;
                return Text(
                  '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final dt = controller.baseDatetime.value;
    final date = await showDatePicker(
      context: context,
      initialDate: dt,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date != null && context.mounted) {
      controller.setBaseDatetime(
        DateTime(date.year, date.month, date.day, dt.hour, dt.minute),
      );
    }
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.controller});

  final AdminPageController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DesignToken.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _pickTime(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, size: 18, color: DesignToken.primary),
              const SizedBox(width: 8),
              Obx(() {
                final dt = controller.baseDatetime.value;
                return Text(
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final dt = controller.baseDatetime.value;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: dt.hour, minute: dt.minute),
    );
    if (time != null && context.mounted) {
      controller.setBaseDatetime(
        DateTime(dt.year, dt.month, dt.day, time.hour, time.minute),
      );
    }
  }
}

class _SimpleDropdown extends StatelessWidget {
  const _SimpleDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<(String value, String label)> items;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = items.any((e) => e.$1 == value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DesignToken.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: hasValue ? value : items.first.$1,
          isExpanded: false,
          borderRadius: BorderRadius.circular(12),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
          hint: Text(label),
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.$1,
                  child: Text(e.$2, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
