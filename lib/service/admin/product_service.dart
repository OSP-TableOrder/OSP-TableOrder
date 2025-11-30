import 'package:table_order/models/admin/product.dart';
import 'package:table_order/server/admin_server/product_server.dart';

class ProductService {
  final ProductServer _server = ProductServer();

  Future<List<Product>> getProducts() => _server.fetchProducts();

  Future<List<Map<String, dynamic>>> getProductsByStore(String storeId) =>
      _server.fetchProductsByStore(storeId);

  Future<String> add(Product p) => _server.addProduct(p);
  Future<void> update(String id, Product p) => _server.updateProduct(id, p);
  Future<void> delete(String id) => _server.deleteProduct(id);
}
