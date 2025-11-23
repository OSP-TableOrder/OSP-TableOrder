import 'package:flutter/material.dart';
import 'package:table_order/models/admin/table_info.dart';

class ReceiptModal extends StatelessWidget {
  final TableInfo table;

  const ReceiptModal({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "주문서",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Text(
              "테이블명 : ${table.tableName}",
              style: const TextStyle(fontSize: 15),
            ),
            Text(
              "총 주문수 : ${table.items.length}",
              style: const TextStyle(fontSize: 15),
            ),
            Text(
              "주문 시각 : ${table.orderTime}",
              style: const TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 14),
            const Divider(thickness: 1),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: const [
                  Expanded(
                    flex: 6,
                    child: Text("메뉴명", style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "수량",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "가격",
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),
            const SizedBox(height: 4),

            Expanded(
              child: ListView.builder(
                itemCount: table.items.length,
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        // 메뉴명
                        Expanded(
                          flex: 6,
                          child: Text(
                            table.items[i],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // 수량
                        const Expanded(
                          flex: 2,
                          child: Text("1", textAlign: TextAlign.center),
                        ),

                        // 가격
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${table.totalPrice ~/ table.items.length}원",
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(thickness: 1),

            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "총 결제 금액",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${table.totalPrice}원",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
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
