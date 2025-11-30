import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:table_order/models/admin/product.dart';
import 'package:table_order/provider/admin/category_provider.dart';
import 'package:table_order/service/admin/image_upload_service.dart';

class ProductEditModal extends StatefulWidget {
  final Product product; // Product 객체 그대로 받음
  final Function(Product) onSubmit; // 수정된 Product 반환

  const ProductEditModal({
    super.key,
    required this.product,
    required this.onSubmit,
  });

  @override
  State<ProductEditModal> createState() => _ProductEditModalState();
}

class _ProductEditModalState extends State<ProductEditModal> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descriptionController;

  late int stock;
  late bool isSoldOut;
  late bool isActive;
  late String selectedCategoryId;

  File? selectedImage;
  bool isUploading = false;

  final labelStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  final ImagePicker _imagePicker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price);
    descriptionController = TextEditingController(
      text: widget.product.description,
    );

    stock = widget.product.stock;
    isSoldOut = widget.product.isSoldOut;
    isActive = widget.product.isActive;
    selectedCategoryId = widget.product.categoryId;
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() => selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
    }
  }

  Future<void> _submitProduct() async {
    final storeId = widget.product.storeId;
    String? imageUrl = widget.product.imageUrl;

    setState(() => isUploading = true);

    try {
      // 이미지 업로드 (선택된 경우)
      if (selectedImage != null) {
        imageUrl = await _imageUploadService.uploadMenuImage(
          storeId: storeId,
          menuId: widget.product.id,
          imagePath: selectedImage!.path,
        );
      }

      // Product 생성
      final updatedProduct = Product(
        id: widget.product.id,
        storeId: widget.product.storeId,
        categoryId: selectedCategoryId,
        name: nameController.text.trim(),
        price: priceController.text.trim(),
        stock: stock,
        isSoldOut: isSoldOut,
        isActive: isActive,
        description: descriptionController.text.trim(),
        imageUrl: imageUrl,
      );

      widget.onSubmit(updatedProduct);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상품 수정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = Provider.of<CategoryProvider>(context);

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "상품 수정",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            DropdownButtonFormField<String>(
              initialValue: selectedCategoryId,
              items: categoryProvider.categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedCategoryId = v!),
              decoration: InputDecoration(
                labelText: "카테고리",
                labelStyle: labelStyle,
              ),
            ),

            const SizedBox(height: 16),
            // 이미지 선택
            GestureDetector(
              onTap: isUploading ? null : _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: selectedImage == null
                    ? (widget.product.imageUrl != null
                        ? Image.network(
                            widget.product.imageUrl!,
                            fit: BoxFit.cover,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '이미지 변경',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ))
                    : Stack(
                        children: [
                          Image.file(
                            selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => selectedImage = null),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "상품명",
                  labelStyle: labelStyle,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "가격",
                  labelStyle: labelStyle,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("재고 수량", style: labelStyle),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        setState(() {
                          if (stock > 0) stock--;
                        });
                      },
                    ),
                    Text(
                      "$stock",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setState(() => stock++),
                    ),
                  ],
                ),
              ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("품절 여부", style: labelStyle),
                  Switch(
                    value: isSoldOut,
                  onChanged: (v) => setState(() => isSoldOut = v),

                  activeTrackColor: const Color(0xff2d7ff9),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.black26,
                ),
              ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("노출 여부", style: labelStyle),
                  Switch(
                    value: isActive,
                  onChanged: (v) => setState(() => isActive = v),

                  activeTrackColor: const Color(0xff2d7ff9),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.black26,
                ),
              ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "상세 설명",
                  labelStyle: labelStyle,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소", style: TextStyle(color: Colors.grey)),
        ),

        ElevatedButton(
          onPressed: isUploading ? null : _submitProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2d7ff9),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text("수정"),
        ),
      ],
    );
  }
}
