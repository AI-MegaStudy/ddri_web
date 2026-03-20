// DDRI 검색 영역: 현 위치, 주소 찾기, 날짜/시간, 반경, 에러 메시지
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kpostal_plus/kpostal_plus.dart';

import '../../app_config.dart';
import '../../common/geocoding/address_geocoder.dart' show geocodeKpostal;
import '../../core/design_token.dart';
import '../../utils/ddri_debug.dart';
import '../../vm/user_page_controller.dart';

/// 검색/입력 영역: 내 위치 찾기, 주소 찾기, 시간대 선택, 반경 선택.
class UserSearchArea extends StatelessWidget {
  const UserSearchArea({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<UserPageController>();

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 버튼 행
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _LocationButton(
                    icon: Icons.my_location,
                    label: '현 위치',
                    onPressed: ctrl.isLoadingLocation.value
                        ? null
                        : () => ctrl.fetchCurrentLocation(),
                    loading: ctrl.isLoadingLocation.value,
                  ),
                  _LocationButton(
                    icon: Icons.search,
                    label: '주소 찾기',
                    onPressed: () => _openAddressSearch(context, ctrl),
                  ),
                  _DateTimeButton(controller: ctrl),
                ],
              )),
          const SizedBox(height: 12),
          // 선택된 위치 표시
          Obx(() {
            if (ctrl.address.value.isEmpty) {
              return Text(
                '위치를 선택해 주세요',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              );
            }
            return Text(
              ctrl.address.value,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            );
          }),
          const SizedBox(height: 12),
          // 조회 방식 / 반경 필터
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('전체보기'),
                  selected: ctrl.selectedRadiusM.value == null,
                  onSelected: (_) => ctrl.onRadiusFilterChanged(null),
                  selectedColor: DesignToken.primary.withValues(alpha: 0.3),
                ),
                ...DesignToken.radiusOptions.map((m) {
                  final isSelected = ctrl.selectedRadiusM.value == m;
                  return ChoiceChip(
                    label: Text(m >= 1000 ? '${m ~/ 1000}km' : '${m}m'),
                    selected: isSelected,
                    onSelected: (_) => ctrl.onRadiusFilterChanged(m),
                    selectedColor: DesignToken.primary.withValues(alpha: 0.3),
                  );
                }),
              ],
            ),
          ),
          // 에러 메시지
          Obx(() {
            if (ctrl.errorMessage.value.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                ctrl.errorMessage.value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openAddressSearch(BuildContext context, UserPageController ctrl) async {
    // KpostalPlusView가 내부에서 navigator.pop(result) 호출함 → callback에서 pop 하면 안 됨 (이중 pop → 흰화면)
    final result = await Get.to<Kpostal>(
      () => KpostalPlusView(
        title: '주소 검색',
        kakaoKey: AppConfig.kakaoJsKey ?? '',
        callback: (_) {}, // 패키지가 pop 처리, 여기서는 아무것도 하지 않음
      ),
    );

    if (result == null) return;

    // 웹: kakaoLatitude/kakaoLongitude 우선, 없으면 latitude/longitude
    var la = result.kakaoLatitude ?? result.latitude;
    var ln = result.kakaoLongitude ?? result.longitude;

    // 카카오·플랫폼 지오코딩 실패 시 OpenStreetMap Nominatim 폴백
    if (la == null || ln == null) {
      final fallback = await geocodeKpostal(result);
      if (fallback != null) {
        la = fallback.lat;
        ln = fallback.lng;
      }
    }

    if (la != null && ln != null) {
      ddriDebugPrint('[DDRI] 주소 검색 결과 좌표: lat=$la, lng=$ln');
      ctrl.applyAddressAndFetch(la, ln, result.address);
    } else {
      ctrl.errorMessage.value = '선택한 주소의 좌표를 가져올 수 없습니다. 카카오 API 키(JavaScript 키)를 설정해 보세요.';
    }
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: DesignToken.primary,
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({required this.controller});

  final UserPageController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dt = controller.targetDatetime.value;
      return OutlinedButton.icon(
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: dt,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 6)),
          );
          if (picked == null || !context.mounted) return;
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(dt),
          );
          if (time == null || !context.mounted) return;
          final combined = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          if (combined.isBefore(DateTime.now())) {
            Get.snackbar(
              '선택 불가',
              '과거 시각은 선택할 수 없습니다.',
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }
          controller.onDatetimeChanged(combined);
        },
        icon: const Icon(Icons.schedule, size: 18),
        label: Text(
          '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
        ),
      );
    });
  }
}
