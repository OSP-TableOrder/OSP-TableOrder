import 'package:table_order/models/admin/category.dart';
import 'package:table_order/models/admin/product.dart';
import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/server/admin_server/menu_repository.dart';

/// 메뉴 도메인 Service
/// 카테고리와 상품의 비즈니스 로직 처리
///
/// 역할:
/// - Category/Product: 관리자 메뉴 관리
/// - Menu (정규화): Orders 컬렉션 조회 시 메뉴 정보 참조
class MenuService {
  final MenuRepository _repository = MenuRepository();

  // ============= Category 관련 메서드 =============

  /// 특정 가게의 모든 카테고리 조회
  Future<List<Category>> getCategories(String storeId) async {
    return await _repository.fetchCategories(storeId);
  }

  /// 카테고리 생성
  Future<void> createCategory({
    required String storeId,
    required String name,
    bool active = true,
    int order = 0,
  }) async {
    return await _repository.addCategory(
      storeId: storeId,
      name: name,
      active: active,
      order: order,
    );
  }

  /// 카테고리 수정
  Future<void> updateCategory({
    required String id,
    required String name,
    required bool active,
    required int order,
  }) async {
    return await _repository.updateCategory(
      id: id,
      name: name,
      active: active,
      order: order,
    );
  }

  /// 카테고리 삭제
  /// 참고: 카테고리 삭제 전에 해당 상품들을 처리해야 함
  Future<void> deleteCategory(String id) async {
    return await _repository.deleteCategory(id);
  }

  // ============= Product 관련 메서드 =============

  /// 모든 상품 조회
  Future<List<Product>> getProducts() async {
    return await _repository.fetchProducts();
  }

  /// 특정 가게의 활성 상품 조회
  Future<List<Product>> getProductsByStore(String storeId) async {
    return await _repository.fetchProductsByStore(storeId);
  }

  /// 상품 생성
  Future<String> createProduct(Product product) async {
    return await _repository.addProduct(product);
  }

  /// 상품 수정
  Future<void> updateProduct(String id, Product product) async {
    return await _repository.updateProduct(id, product);
  }

  /// 상품 삭제
  Future<void> deleteProduct(String id) async {
    return await _repository.deleteProduct(id);
  }

  // ============= Normalized Menu Collection 관련 메서드 =============
  // (MenuMigration을 통해 생성되는 정규화된 Menus 컬렉션)

  /// 특정 메뉴를 ID로 조회
  Future<Menu?> getMenuById(String menuId) async {
    return await _repository.getMenuById(menuId);
  }

  /// 특정 가게의 모든 활성 메뉴 조회
  Future<List<Menu>> getMenusByStore(String storeId) async {
    return await _repository.getMenusByStore(storeId);
  }

  /// 특정 가게의 특정 카테고리 메뉴 조회
  Future<List<Menu>> getMenusByCategory(String storeId, String categoryId) async {
    return await _repository.getMenusByCategory(storeId, categoryId);
  }

  /// 여러 메뉴를 ID 리스트로 조회 (Orders의 items 조회 시 효율적)
  /// Orders 문서의 items[].menuId를 통해 메뉴 정보를 병렬로 조회할 때 사용
  Future<List<Menu>> getMenusByIds(List<String> menuIds) async {
    return await _repository.getMenusByIds(menuIds);
  }

  /// 메뉴 가격 업데이트
  /// 주의: 과거 주문의 priceAtOrder는 변경되지 않음 (히스토리 보존)
  Future<bool> updateMenuPrice(String menuId, int newPrice) async {
    return await _repository.updateMenuPrice(menuId, newPrice);
  }

  /// 메뉴 품절 상태 업데이트
  Future<bool> updateMenuSoldOut(String menuId, bool isSoldOut) async {
    return await _repository.updateMenuSoldOut(menuId, isSoldOut);
  }

  /// 메뉴 활성화 상태 업데이트
  /// isActive=false인 메뉴는 조회 쿼리에서 제외됨
  Future<bool> updateMenuActive(String menuId, bool isActive) async {
    return await _repository.updateMenuActive(menuId, isActive);
  }

  /// 메뉴 추천 여부 업데이트
  Future<bool> updateMenuRecommended(String menuId, bool isRecommended) async {
    return await _repository.updateMenuRecommended(menuId, isRecommended);
  }
}
