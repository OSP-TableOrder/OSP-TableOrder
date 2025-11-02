import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../widgets/quantity_control.dart';

class MenuDetailScreen extends StatefulWidget {
  final MenuItem item;

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
      appBar: AppBar(
        title: Text(widget.item.name),
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // TODO: 장바구니에 아이템과 수량(_quantity)을 담는 로직
            print('${widget.item.name} $_quantity개 담기');
            Navigator.pop(context);
          },
          child: Text(
            '메뉴 담기 ($_quantity개)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6299FD),
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[100],
              child: widget.item.imageUrl != null
                  ? Image.network(widget.item.imageUrl!, fit: BoxFit.cover)
                  : Icon(Icons.restaurant, size: 100, color: Colors.grey[400]),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.item.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '${widget.item.price}원',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
