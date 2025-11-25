import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class MapsService {
  /// Mở Google Maps với chỉ đường từ điểm bắt đầu đến điểm kết thúc
  /// Sử dụng tên địa điểm để đạt độ chính xác 100%
  /// Mặc định là đi bộ (walking) - phù hợp cho app quản lý hiking
  static Future<void> openDirections({
    required BuildContext context,
    required String startPlaceName,
    required String endPlaceName,
  }) async {
    try {
      // Encode tên địa điểm để đảm bảo URL hợp lệ
      final origin = Uri.encodeComponent(startPlaceName);
      final destination = Uri.encodeComponent(endPlaceName);

      // Tạo URL cho Google Maps với directions từ start đến end
      // Mặc định dùng walking mode cho hiking
      final mapsUrl = 'https://www.google.com/maps/dir/?api=1'
          '&origin=$origin'
          '&destination=$destination'
          '&travelmode=walking';

      final Uri uri = Uri.parse(mapsUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Mở trong Google Maps app
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening Google Maps: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

