import 'dart:io';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _bucketPath = 'menu_images';

  /// 메뉴 이미지 업로드
  /// [storeId]: 가게 ID
  /// [menuId]: 메뉴 ID (선택사항, 빈 문자열이면 임시 ID 생성)
  /// [imagePath]: 이미지 파일 경로
  /// 반환값: 업로드된 이미지의 다운로드 URL
  Future<String> uploadMenuImage({
    required String storeId,
    required String menuId,
    required String imagePath,
  }) async {
    try {
      // 파일이 존재하는지 확인
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw Exception('이미지 파일을 찾을 수 없습니다.');
      }

      // Firebase Storage 경로 생성
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = menuId.isEmpty ? 'temp_$timestamp' : menuId;
      final storagePath = '$_bucketPath/$storeId/$fileName';

      // 파일 업로드
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(file);

      // 업로드 완료 대기
      await uploadTask.whenComplete(() {});

      // 다운로드 URL 획득
      final downloadUrl = await ref.getDownloadURL();

      developer.log(
        'Image uploaded successfully: $downloadUrl',
        name: 'ImageUploadService',
      );

      return downloadUrl;
    } catch (e) {
      developer.log(
        'Error uploading image: $e',
        name: 'ImageUploadService',
      );
      rethrow;
    }
  }

  /// 메뉴 이미지 삭제
  /// [storeId]: 가게 ID
  /// [menuId]: 메뉴 ID
  Future<void> deleteMenuImage({
    required String storeId,
    required String menuId,
  }) async {
    try {
      final storagePath = '$_bucketPath/$storeId/$menuId';
      final ref = _storage.ref().child(storagePath);

      await ref.delete();

      developer.log(
        'Image deleted successfully: $storagePath',
        name: 'ImageUploadService',
      );
    } catch (e) {
      developer.log(
        'Error deleting image: $e',
        name: 'ImageUploadService',
      );
      // 삭제 실패는 무시 (이미지가 없을 수 있음)
    }
  }
}
