import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/admin/table_order_provider.dart';
import 'package:table_order/widgets/admin/order/receipt_modal.dart';
import 'package:table_order/widgets/admin/table/table_card_item.dart';

class TableManagementArea extends StatefulWidget {
  const TableManagementArea({super.key});

  @override
  State<TableManagementArea> createState() => _TableManagementAreaState();
}

class _TableManagementAreaState extends State<TableManagementArea> {
  @override
  void initState() {
    super.initState();
    context.read<TableOrderProvider>().loadTables();
  }

  @override
  Widget build(BuildContext context) {
    final tables = context.watch<TableOrderProvider>().tables;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (int i = 0; i < tables.length; i++)
            TableCardItem(
              key: ValueKey("table_index_$i"),
              table: tables[i],
              onTap: () {
                final provider = context.read<TableOrderProvider>();

                if (tables[i].hasNewOrder) {
                  provider.checkNewOrder(i);
                }
                if (tables[i].hasCallRequest) {
                  provider.checkCallRequest(i);
                }

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ReceiptModal(table: tables[i], tableIndex: i),
                );
              },
            ),
        ],
      ),
    );
  }
}
