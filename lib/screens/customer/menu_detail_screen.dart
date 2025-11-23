import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/widgets/quantity_control.dart';
import 'package:table_order/widgets/header_bar.dart';
import 'package:table_order/provider/customer/cart_provider.dart';

class MenuDetailScreen extends StatefulWidget {
  final Menu item;

  const MenuDetailScreen({Key? key, required this.item}) : super(key: key);

  @override
  _MenuDetailScreenState createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  int _quantity = 1;

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            final cartProvider = context.read<CartProvider>();
            cartProvider.addItem(widget.item, _quantity);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.item.name} $_quantity개가 장바구니에 추가되었습니다.'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6299FD),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '메뉴 담기 ($_quantity개)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeaderBar(
              title: widget.item.name,
              leftItem: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios),
              ),
            ),

            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[100],
              child: widget.item.imageUrl != null
                  ? Image.network(
                      widget.item.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.restaurant, size: 100, color: Colors.grey[400]);
                      },
                    )
                  : Icon(Icons.restaurant, size: 100, color: Colors.grey[400]),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.item.price}원',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: Colors.grey[200]),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '주문 수량 $_quantity개',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  QuantityControl(
                    onDecrement: _decrementQuantity,
                    onIncrement: _incrementQuantity,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
