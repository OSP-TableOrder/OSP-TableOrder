import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import 'package:table_order/models/customer/menu.dart';
import 'package:table_order/widgets/customer/header_bar.dart';
import 'package:table_order/widgets/customer/menu_item_card.dart';
import 'package:table_order/provider/customer/menu_provider.dart';
import 'package:table_order/provider/customer/cart_provider.dart';
import 'package:table_order/provider/customer/order_provider.dart';
import 'package:table_order/provider/customer/store_provider.dart';
import 'package:table_order/models/customer/store.dart';
import 'package:table_order/screens/customer/order_status_screen.dart';
import 'package:table_order/widgets/customer/call_staff_modal/call_staff_modal.dart';
import 'package:table_order/provider/admin/call_staff_provider.dart';
import 'package:table_order/routes/app_routes.dart';
import 'package:table_order/provider/app_state_provider.dart';

class MenuScreen extends StatefulWidget {
  /// storeId: 라우트 인자로 직접 전달된 경우, 또는 AppState에서 자동으로 읽음
  final String? storeId;

  const MenuScreen({super.key, this.storeId});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _noticeExpanded = false;
  late final ScrollController _scrollController;
  final Map<String, GlobalKey> _categoryKeys = {};
  String? _selectedCategory;
  static const double _categoryBarHeight = 60;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<String?> _ensureReceiptId(
    BuildContext context,
    OrderStatusViewModel orderProvider,
    String? storeId,
    String? tableId,
  ) async {
    if (storeId == null || storeId.isEmpty || tableId == null || tableId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가게 정보를 찾을 수 없습니다. 관리자에게 문의해주세요.')),
      );
      return null;
    }

    var receiptId = orderProvider.receiptId;
    if (receiptId != null && receiptId.isNotEmpty) {
      final currentOrder = orderProvider.order;
      final matchesStore =
          currentOrder.storeId.isEmpty || currentOrder.storeId == storeId;
      final matchesTable =
          currentOrder.tableId.isEmpty || currentOrder.tableId == tableId;

      if (matchesStore && matchesTable) {
        return receiptId;
      }

      orderProvider.clearReceipt();
      receiptId = null;
    }

    final hasExisting = await orderProvider.loadExistingOrderForTable(
      storeId: storeId,
      tableId: tableId,
    );
    if (!context.mounted) return null;

    if (!hasExisting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('진행 중인 주문이 없습니다.')),
      );
      return null;
    }

    return orderProvider.receiptId;
  }

  Future<void> _navigateToOrderStatus(
    BuildContext context,
    OrderStatusViewModel orderProvider,
    String? storeId,
    String? tableId,
  ) async {
    final receiptId = await _ensureReceiptId(
      context,
      orderProvider,
      storeId,
      tableId,
    );
    if (receiptId == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(receiptId: receiptId),
      ),
    );
  }

  Future<void> _showCallStaffDialog(
    BuildContext context,
    OrderStatusViewModel orderProvider,
    String? storeId,
    String? tableId,
    String? tableName,
  ) async {
    final receiptId = await _ensureReceiptId(
      context,
      orderProvider,
      storeId,
      tableId,
    );
    if (receiptId == null || !context.mounted) return;

    if (storeId == null || tableId == null) return;
    final safeTableId = tableId;

    final callStaffProvider = context.read<CallStaffProvider>();
    final tableDisplay = tableName ?? safeTableId;

    await showCallStaffDialog(
      context,
      receiptId: receiptId,
      onSubmit: (receiptId, message, items) async {
        await callStaffProvider.sendCallRequest(
          storeId: storeId,
          tableId: tableId,
          tableName: tableDisplay,
          receiptId: receiptId,
          message: message,
        );
      },
    );
  }

  void _navigateToCart(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.cart);
  }

  Future<void> _scrollToCategory(String category) async {
    final key = _categoryKeys[category];
    if (key == null) return;
    final context = key.currentContext;
    if (context == null) return;

    await Scrollable.ensureVisible(
      context,
      alignment: 0,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );

    if (!_scrollController.hasClients) return;
    final adjusted = (_scrollController.offset - _categoryBarHeight)
        .clamp(_scrollController.position.minScrollExtent, _scrollController.position.maxScrollExtent);
    await _scrollController.animateTo(
      adjusted,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
    );

    if (!mounted) return;
    setState(() {
      _selectedCategory = category;
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _categoryKeys.isEmpty) return;

    final currentOffset = _scrollController.offset + _categoryBarHeight + 8;
    String? candidate;
    double candidateOffset = double.negativeInfinity;

    for (final entry in _categoryKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;
      final viewport = RenderAbstractViewport.of(renderBox);
      final offset = viewport.getOffsetToReveal(renderBox, 0).offset - _categoryBarHeight;
      if (currentOffset >= offset && offset >= candidateOffset) {
        candidate = entry.key;
        candidateOffset = offset;
      }
    }

    candidate ??= _categoryKeys.keys.isNotEmpty ? _categoryKeys.keys.first : null;

    if (candidate != null && candidate != _selectedCategory) {
      setState(() {
        _selectedCategory = candidate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final storeProvider = context.watch<StoreProvider>();
    final appState = context.watch<AppStateProvider>();
    final orderProvider = context.watch<OrderStatusViewModel>();

    // storeId를 전달받으면 그것을 사용, 아니면 AppState에서 읽음
    final effectiveStoreId = widget.storeId ?? appState.storeId;
    final tableId = appState.tableId;
    final tableName = appState.tableName;

    final shouldLoadMenus = !menuProvider.isLoading && menuProvider.menus.isEmpty;

    if (shouldLoadMenus && effectiveStoreId != null && effectiveStoreId.isNotEmpty) {
      final provider = context.read<MenuProvider>();
      Future.microtask(() {
        if (!provider.isLoading && provider.menus.isEmpty) {
          provider.loadMenus(effectiveStoreId);
        }
      });
    }

    final currentStore = storeProvider.currentStore;
    final shouldLoadStore =
        effectiveStoreId != null && effectiveStoreId.isNotEmpty && (currentStore == null || currentStore.id != effectiveStoreId);
    if (shouldLoadStore && !storeProvider.isLoading) {
      final provider = context.read<StoreProvider>();
      Future.microtask(() {
        if (!provider.isLoading) {
          provider.loadStoreById(effectiveStoreId);
        }
      });
    }

    final shouldLoadTableName =
        (tableName == null || tableName.isEmpty) && (tableId != null && tableId.isNotEmpty);
    if (shouldLoadTableName) {
      final appStateProvider = context.read<AppStateProvider>();
      Future.microtask(() {
        if (!mounted) return;
        appStateProvider.ensureTableNameLoaded();
      });
    }

    final displayList = menuProvider.displayList;
    final categories = menuProvider.groupedMenus
        .map((group) => group['category'])
        .whereType<String>()
        .where((c) => c.trim().isNotEmpty)
        .toList(growable: false);
    final hasCategories = categories.isNotEmpty;
    _categoryKeys.removeWhere((key, _) => !categories.contains(key));
    for (final category in categories) {
      _categoryKeys.putIfAbsent(category, () => GlobalKey());
    }
    if (hasCategories &&
        (_selectedCategory == null || !categories.contains(_selectedCategory))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedCategory = categories.first;
        });
      });
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: HeaderBar(
        title: '메뉴 주문하기',
        leftItem: TextButton(
          onPressed: () => _navigateToOrderStatus(
            context,
            orderProvider,
            effectiveStoreId,
            tableId,
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(64, 40),
          ),
          child: Text(
            '주문현황',
            style: TextStyle(color: Colors.blue[700], fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        rightItem: TextButton(
          onPressed: () => _showCallStaffDialog(
            context,
            orderProvider,
            effectiveStoreId,
            tableId,
            tableName,
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(64, 40),
          ),
          child: Text(
            '직원호출',
            style: TextStyle(color: Colors.blue[700], fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: SafeArea(
        child: (menuProvider.isLoading && displayList.isEmpty)
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildStoreHeader(
                      context,
                      currentStore,
                      tableName,
                    ),
                  ),
                  if (hasCategories)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CategoryBarDelegate(
                        height: _categoryBarHeight,
                        child: _buildCategoryBar(categories),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = displayList[index];

                          if (item is String) {
                            return _buildCategoryHeader(item);
                          } else if (item is Menu) {
                            return MenuItemCard(item: item);
                          }
                          return const SizedBox.shrink();
                        },
                        childCount: displayList.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),

      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final itemCount = cartProvider.itemCount;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                onPressed: () => _navigateToCart(context),
                backgroundColor: const Color(0xFF6299FD),
                foregroundColor: Colors.white,
                child: const Icon(Icons.shopping_cart),
              ),
              if (itemCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      itemCount > 99 ? '99+' : '$itemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Container(
      key: _categoryKeys[title],
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 10.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStoreHeader(
    BuildContext context,
    Store? store,
    String? tableName,
  ) {
    final storeName = store?.name ?? '가게 정보를 불러오는 중입니다';
    final tableText = (tableName == null || tableName.isEmpty)
        ? '테이블 정보 없음'
        : tableName;
    final notice = (store?.notice ?? '').trim();
    final hasNotice = notice.isNotEmpty;
    final isExpanded = _noticeExpanded;
    final availableWidth = MediaQuery.of(context).size.width - 32; // margin
    final tableMaxWidth = availableWidth * 0.4;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '멤버도 QR 찍고 함께 주문해요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 4,
                fit: FlexFit.loose,
                child: Align(
                  alignment: Alignment.topRight,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: tableMaxWidth),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_seat_outlined,
                            size: 18,
                            color: Color(0xFF4A5161),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              tableText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (hasNotice) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  _noticeExpanded = !_noticeExpanded;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      color: Color(0xFF3B66F5),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notice,
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 28,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF3B66F5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryBar(List<String> categories) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final text = categories[index];
            final isSelected = text == _selectedCategory;
            return GestureDetector(
              onTap: () => _scrollToCategory(text),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFDCE6FF) : const Color(0xFFF5F7FB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3B66F5) : Colors.transparent,
                  ),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _CategoryBarDelegate({
    required this.child,
    this.height = 60,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryBarDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
