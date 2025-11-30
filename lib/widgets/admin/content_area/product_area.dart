import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/admin/product_provider.dart';
import 'package:table_order/provider/admin/category_provider.dart';
import 'package:table_order/provider/admin/login_provider.dart';
import 'package:table_order/widgets/admin/product/add_product_modal.dart';
import 'package:table_order/widgets/admin/product/edit_product_modal.dart';
import 'package:table_order/widgets/admin/product/product_list_item.dart';
import 'package:table_order/widgets/admin/product/product_category_tab.dart';
import 'package:table_order/widgets/admin/product/delete_product_modal.dart';

class ProductArea extends StatefulWidget {
  const ProductArea({super.key});

  @override
  State<ProductArea> createState() => _ProductAreaState();
}

class _ProductAreaState extends State<ProductArea> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      final loginProvider = context.read<LoginProvider>();
      final storeId = loginProvider.storeId;

      if (storeId != null) {
        await context.read<CategoryProvider>().loadCategories(storeId);
      }

      if (!mounted) return;
      await context.read<ProductProvider>().loadProducts();
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    final selectedCategoryIndex = categoryProvider.selectedCategoryIndex;
    final selectedCategoryId = (selectedCategoryIndex == 0)
        ? null
        : categoryProvider.categories[selectedCategoryIndex - 1].id;

    final filtered = productProvider.getFilteredProducts(selectedCategoryId);

    return Container(
      color: const Color(0xffe9eef3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "상품",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => ProductAddModal(
                      onSubmit: (product) {
                        context.read<ProductProvider>().addProduct(product);
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2d7ff9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("+ 상품 추가"),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const ProductCategoryTab(),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final p = filtered[i];

                return ProductListItem(
                  product: p,
                  onEdit: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => ProductEditModal(
                        product: p,
                        onSubmit: (updated) {
                          productProvider.updateProduct(p.id, updated);
                        },
                      ),
                    );
                  },
                  onDelete: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => DeleteProductModal(
                        productName: p.name,
                        onDelete: () {
                          productProvider.deleteProduct(p.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
