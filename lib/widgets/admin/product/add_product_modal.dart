import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:table_order/models/admin/product.dart';
import 'package:table_order/provider/admin/category_provider.dart';
import 'package:table_order/provider/admin/login_provider.dart';
import 'package:table_order/service/admin/image_upload_service.dart';

class ProductAddModal extends StatefulWidget {
  final Function(Product) onSubmit;

  const ProductAddModal({super.key, required this.onSubmit});

  @override
  State<ProductAddModal> createState() => _ProductAddModalState();
}

class _ProductAddModalState extends State<ProductAddModal> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  int stock = 0;
  bool isSoldOut = false;
  bool isActive = true;
  String? selectedCategoryId;

  File? selectedImage;
  bool isUploading = false;

  final ImagePicker _imagePicker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();

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
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리를 선택해주세요.')),
      );
      return;
    }

    final storeId = context.read<LoginProvider>().storeId ?? '';
    String? imageUrl;

    setState(() => isUploading = true);

    try {
      // 이미지 업로드 (선택된 경우)
      if (selectedImage != null) {
        imageUrl = await _imageUploadService.uploadMenuImage(
          storeId: storeId,
          menuId: '', // 임시 ID (서버에서 생성 후 이름 변경 가능)
          imagePath: selectedImage!.path,
        );
      }

      // Product 생성
      final newProduct = Product(
        id: '', // ID는 Firestore에서 자동 생성됨
        storeId: storeId,
        categoryId: selectedCategoryId!,
        name: nameController.text.trim(),
        price: priceController.text.trim(),
        stock: stock,
        isSoldOut: isSoldOut,
        isActive: isActive,
        description: descriptionController.text.trim(),
        imageUrl: imageUrl,
      );

      widget.onSubmit(newProduct);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상품 추가 실패: $e'),
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
    final categories = context.watch<CategoryProvider>().categories;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        "상품 추가",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedCategoryId,
              items: categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedCategoryId = v),
              decoration: const InputDecoration(labelText: "카테고리"),
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
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '이미지 추가',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      )
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
              decoration: const InputDecoration(labelText: "상품명"),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "가격"),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("재고"),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          if (stock > 0) stock--;
                        });
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text("$stock"),
                    IconButton(
                      onPressed: () => setState(() => stock++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("품절 여부"),
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
                const Text("노출 여부"),
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
              decoration: const InputDecoration(labelText: "상세 설명"),
            ),
          ],
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
              : const Text("추가"),
        ),
      ],
    );
  }
}
