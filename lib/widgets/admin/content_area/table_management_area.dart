import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_order/provider/admin/login_provider.dart';
import 'package:table_order/provider/admin/order_provider.dart';
import 'package:table_order/widgets/admin/order/receipt_modal.dart';
import 'package:table_order/widgets/admin/table/table_card_item.dart';

class TableManagementArea extends StatefulWidget {
  const TableManagementArea({super.key});

  @override
  State<TableManagementArea> createState() => _TableManagementAreaState();
}

class _TableManagementAreaState extends State<TableManagementArea> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    try {
      final storeId = context.read<LoginProvider>().storeId;
      if (storeId != null) {
        await context
            .read<OrderProvider>()
            .loadTables(storeId.toString());
      }
    } catch (e) {
      debugPrint('Error loading tables: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tables = context.watch<OrderProvider>().tables;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
              onTap: () async {
                final provider = context.read<OrderProvider>();
                final storeId =
                    context.read<LoginProvider>().storeId?.toString();

                if (tables[i].hasCallRequest && storeId != null) {
                  await provider.checkCallRequest(i, storeId);
                  if (!context.mounted) {
                    return;
                  }
                }

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => ReceiptModal(
                    table: tables[i],
                    tableIndex: i,
                    storeId: storeId,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
