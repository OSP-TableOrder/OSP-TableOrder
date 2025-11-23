import 'package:table_order/models/admin/product.dart';
import 'package:table_order/server/admin_server/product_server.dart';

class ProductService {
  final ProductServerStub _server = ProductServerStub();

  Future<List<Product>> getProducts() => _server.fetchProducts();
  Future<void> add(Product p) => _server.addProduct(p);
  Future<void> update(String id, Product p) => _server.updateProduct(id, p);
  Future<void> delete(String id) => _server.deleteProduct(id);
}
