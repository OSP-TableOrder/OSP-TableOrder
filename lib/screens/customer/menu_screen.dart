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
import 'package:table_order/provider/admin/staff_request_provider.dart';
import 'package:table_order/routes/app_routes.dart';
import 'package:table_order/provider/app_state_provider.dart';
import 'package:table_order/widgets/customer/menu_category_bar.dart';
import 'package:table_order/widgets/customer/menu_category_header.dart';
import 'package:table_order/widgets/customer/measured_size.dart';
import 'package:table_order/widgets/customer/store_info_header.dart';

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
  final Map<String?, GlobalKey> _categoryKeys = {}; // categoryId를 key로 사용
  final Map<String?, double> _categoryHeights = {}; // 카테고리 헤더 실제 높이
  final Map<String, double> _menuItemHeights = {}; // 메뉴 카드 실제 높이
  double? _storeHeaderHeight; // 스토어 헤더 실제 높이
  String? _selectedCategoryId; // categoryId 기반 선택 상태
  String? _manuallySelectedCategoryId; // 사용자가 수동으로 선택한 카테고리
  bool _isScrolling = false; // 스크롤 애니메이션 진행 중 플래그
  bool _isNavigating = false; // 네비게이션 중복 방지 플래그
  static const double _categoryBarHeight = 60;
  static const double _defaultStoreHeaderHeight = 220;
  static const double _defaultCategoryHeaderHeight = 50;
  static const double _defaultMenuItemHeight = 215;

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
    if (storeId == null ||
        storeId.isEmpty ||
        tableId == null ||
        tableId.isEmpty) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('진행 중인 주문이 없습니다.')));
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
    // 중복 네비게이션 방지
    if (_isNavigating) return;
    _isNavigating = true;

    try {
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
    } finally {
      _isNavigating = false;
    }
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

    final staffRequestProvider = context.read<StaffRequestProvider>();
    final tableDisplay = tableName ?? safeTableId;

    await showCallStaffDialog(
      context,
      receiptId: receiptId,
      onSubmit: (receiptId, message, items) async {
        await staffRequestProvider.addCallRequest(
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
    // 중복 네비게이션 방지
    if (_isNavigating) return;
    _isNavigating = true;

    Navigator.pushNamed(context, AppRoutes.cart).then((_) {
      _isNavigating = false;
    });
  }

  Future<void> _scrollToCategoryId(String? categoryId) async {
    if (!_scrollController.hasClients) return;

    // Prevent duplicate scrolling while animation is in progress
    if (_isScrolling) {
      return;
    }

    // Mark that user manually selected this category
    _manuallySelectedCategoryId = categoryId;
    _isScrolling = true;

    final menuProvider = context.read<MenuProvider>();
    final displayList = menuProvider.displayList;

    // displayList에서 해당 categoryId의 카테고리 헤더 위치 찾기
    int targetIndex = -1;
    for (int i = 0; i < displayList.length; i++) {
      final item = displayList[i];
      if (item is Map<String, dynamic>) {
        final itemCategoryId = item['categoryId'] as String?;
        final isHeader = item.containsKey('name');
        if (isHeader && itemCategoryId == categoryId) {
          targetIndex = i;
          break;
        }
      }
    }

    if (targetIndex == -1) {
      _isScrolling = false;
      return;
    }

    final hasPinnedHeader = menuProvider.categoryIds.isNotEmpty;
    final pinnedAdjustment = hasPinnedHeader ? _categoryBarHeight : 0;

    // 한 번만 시도: GlobalKey가 현재 렌더링되어 있으면 사용
    try {
      final key = _categoryKeys[categoryId];
      if (key != null && key.currentContext != null) {
        final renderBox = key.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final viewport = RenderAbstractViewport.of(renderBox);
          final offsetToReveal = viewport.getOffsetToReveal(renderBox, 0);
          final targetRenderOffset = offsetToReveal.offset;

          final correctedTargetOffset = (targetRenderOffset - pinnedAdjustment)
              .clamp(
                _scrollController.position.minScrollExtent,
                _scrollController.position.maxScrollExtent,
              );

          if (!mounted || !_scrollController.hasClients) return;

          await _scrollController.animateTo(
            correctedTargetOffset,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );

          // Set the selected category immediately after animation completes
          setState(() {
            _selectedCategoryId = categoryId;
          });

          // Clear manual selection flag after animation completes
          _manuallySelectedCategoryId = null;
          _isScrolling = false;
          return;
        }
      }
    } catch (e) {
      // Silently continue to estimated offset if GlobalKey lookup fails
    }

    // 즉시 estimated offset 사용 (재시도 안 함)
    // 모든 이전 아이템의 높이를 합산
    double estimatedOffset =
        (_storeHeaderHeight ?? _defaultStoreHeaderHeight) + pinnedAdjustment;

    for (int i = 0; i < targetIndex; i++) {
      final item = displayList[i];
      if (item is Map<String, dynamic>) {
        // 카테고리 헤더: 렌더링되었으면 실제 높이, 아니면 추정값
        final itemCategoryId = item['categoryId'] as String?;
        final cachedHeight = _categoryHeights[itemCategoryId];
        if (cachedHeight != null) {
          estimatedOffset += cachedHeight;
          continue;
        }

        final key = _categoryKeys[itemCategoryId];
        if (key != null && key.currentContext != null) {
          try {
            final renderBox =
                key.currentContext!.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              estimatedOffset += renderBox.size.height;
              continue;
            }
          } catch (_) {}
        }
        estimatedOffset += _defaultCategoryHeaderHeight;
      } else if (item is Menu) {
        final cachedHeight = _menuItemHeights[item.id];
        if (cachedHeight != null) {
          estimatedOffset += cachedHeight;
        } else {
          estimatedOffset += _defaultMenuItemHeight;
        }
      }
    }

    final correctedEstimatedOffset = (estimatedOffset - pinnedAdjustment).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    if (!mounted || !_scrollController.hasClients) return;

    await _scrollController.animateTo(
      correctedEstimatedOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );

    // Set the selected category immediately after animation completes
    setState(() {
      _selectedCategoryId = categoryId;
    });

    // Clear manual selection flag after animation completes
    _manuallySelectedCategoryId = null;
    _isScrolling = false;
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _categoryKeys.isEmpty) return;

    // Skip auto-selection if user manually selected a category recently
    // The flag will be cleared after the scroll animation completes
    if (_manuallySelectedCategoryId != null) {
      return;
    }

    final currentOffset = _scrollController.offset;
    String? candidate;
    double closestDistance = double.infinity;

    // _categoryKeys는 순서를 보장하지 않으므로, categoryIds 순서로 검사
    final menuProvider = context.read<MenuProvider>();
    for (final categoryId in menuProvider.categoryIds) {
      final ctx = _categoryKeys[categoryId]?.currentContext;
      if (ctx == null) continue;

      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      final viewport = RenderAbstractViewport.of(renderBox);
      final offset = viewport.getOffsetToReveal(renderBox, 0).offset;

      // 현재 스크롤 위치에 가장 가까운 카테고리 선택 (위 또는 아래)
      final distance = (offset - currentOffset).abs();
      if (distance < closestDistance) {
        candidate = categoryId;
        closestDistance = distance;
      }
    }

    // 위에 있는 카테고리가 없으면 (처음 스크롤하기 전) 첫 번째 카테고리 선택
    // 단, 이미 다른 카테고리가 선택된 경우는 변경하지 않음
    if (candidate == null && _selectedCategoryId == null) {
      candidate = menuProvider.categoryIds.isNotEmpty
          ? menuProvider.categoryIds.first
          : null;
    }

    if (candidate != null && candidate != _selectedCategoryId) {
      setState(() {
        _selectedCategoryId = candidate;
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

    // 한 번도 로드하지 않았으면 로드 시도
    final shouldLoadMenus =
        !menuProvider.hasAttemptedLoad && !menuProvider.isLoading;

    if (shouldLoadMenus &&
        effectiveStoreId != null &&
        effectiveStoreId.isNotEmpty) {
      final provider = context.read<MenuProvider>();
      Future.microtask(() {
        if (!provider.hasAttemptedLoad && !provider.isLoading) {
          provider.loadMenus(effectiveStoreId);
        }
      });
    }

    final currentStore = storeProvider.currentStore;
    final shouldLoadStore =
        effectiveStoreId != null &&
        effectiveStoreId.isNotEmpty &&
        (currentStore == null || currentStore.id != effectiveStoreId);
    if (shouldLoadStore && !storeProvider.isLoading) {
      final provider = context.read<StoreProvider>();
      Future.microtask(() {
        if (!provider.isLoading) {
          provider.loadStoreById(effectiveStoreId);
        }
      });
    }

    final shouldLoadTableName =
        (tableName == null || tableName.isEmpty) &&
        (tableId != null && tableId.isNotEmpty);
    if (shouldLoadTableName) {
      final appStateProvider = context.read<AppStateProvider>();
      Future.microtask(() {
        if (!mounted) return;
        appStateProvider.ensureTableNameLoaded();
      });
    }

    final displayList = menuProvider.displayList;
    final categoryIds = menuProvider.categoryIds;
    final Map<String?, String> categoryLabels = {};
    for (final group in menuProvider.groupedMenus) {
      final id = group['categoryId'] as String?;
      final label = (group['category'] as String?)?.trim();
      if (label != null && label.isNotEmpty) {
        categoryLabels[id] = label;
      }
    }
    if (menuProvider.hasUncategorizedMenus) {
      categoryLabels[kUncategorizedCategoryId] = '기타';
    }

    final hasCategories = categoryIds.isNotEmpty;
    _categoryKeys.removeWhere((key, _) => !categoryIds.contains(key));
    _categoryHeights.removeWhere((key, _) => !categoryIds.contains(key));
    final activeMenuIds = menuProvider.menus.map((menu) => menu.id).toSet();
    _menuItemHeights.removeWhere((key, _) => !activeMenuIds.contains(key));
    for (final categoryId in categoryIds) {
      _categoryKeys.putIfAbsent(categoryId, () => GlobalKey());
    }
    if (hasCategories &&
        (_selectedCategoryId == null ||
            !categoryIds.contains(_selectedCategoryId))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedCategoryId = categoryIds.first;
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
        child: _buildBody(
          context,
          menuProvider,
          storeProvider,
          displayList,
          hasCategories,
          categoryIds,
          currentStore,
          tableName,
          categoryLabels,
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

  /// 페이지 본문 빌더 - 에러 상태와 정상 상태를 분기하여 표시
  Widget _buildBody(
    BuildContext context,
    MenuProvider menuProvider,
    StoreProvider storeProvider,
    List<dynamic> displayList,
    bool hasCategories,
    List<String?> categoryIds,
    Store? currentStore,
    String? tableName,
    Map<String?, String> categoryLabels,
  ) {
    // 로딩 중이고 데이터가 없으면 로딩 표시
    if (menuProvider.isLoading && displayList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // storeId가 없으면 오류 표시
    if (menuProvider.error != null || storeProvider.error != null) {
      final errorMessage =
          menuProvider.error ?? storeProvider.error ?? '알 수 없는 오류가 발생했습니다.';
      return _buildErrorPage(errorMessage);
    }

    // 가게 정보가 로드되지 않았으면 오류 표시
    if (currentStore == null && !storeProvider.isLoading) {
      return _buildErrorPage('가게 정보를 찾을 수 없습니다. 관리자에게 문의해주세요.');
    }

    // 메뉴가 없으면 안내 메시지와 함께 가게 정보만 표시
    if (displayList.isEmpty && !menuProvider.isLoading) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: StoreInfoHeader(
              store: currentStore,
              tableName: tableName,
              isNoticeExpanded: _noticeExpanded,
              onToggleNotice: () {
                setState(() {
                  _noticeExpanded = !_noticeExpanded;
                });
              },
              onHeight: (height) {
                _storeHeaderHeight = height;
              },
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '현재 준비 중인 메뉴가 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '잠시 후 다시 확인해주세요',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 정상 상태: 메뉴와 함께 표시
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: StoreInfoHeader(
            store: currentStore,
            tableName: tableName,
            isNoticeExpanded: _noticeExpanded,
            onToggleNotice: () {
              setState(() {
                _noticeExpanded = !_noticeExpanded;
              });
            },
            onHeight: (height) {
              _storeHeaderHeight = height;
            },
          ),
        ),
        if (hasCategories)
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryBarDelegate(
              height: _categoryBarHeight,
              child: MenuCategoryBar(
                categoryIds: categoryIds,
                selectedCategoryId: _selectedCategoryId,
                categoryLabels: categoryLabels,
                onCategoryTap: _scrollToCategoryId,
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = displayList[index];

              if (item is Map<String, dynamic>) {
                final categoryId = item['categoryId'] as String?;
                final categoryName = item['name'] as String? ?? '기타';
                final headerKey = _categoryKeys.putIfAbsent(
                  categoryId,
                  () => GlobalKey(),
                );

                return MenuCategoryHeader(
                  headerKey: headerKey,
                  title: categoryName,
                  onHeight: (height) {
                    _categoryHeights[categoryId] = height;
                  },
                );
              }

              if (item is Menu) {
                return MeasuredSize(
                  key: ValueKey('menu-${item.id}'),
                  onHeight: (height) {
                    _menuItemHeights[item.id] = height;
                  },
                  child: MenuItemCard(item: item),
                );
              }
              return const SizedBox.shrink();
            }, childCount: displayList.length),
          ),
        ),
      ],
    );
  }

  /// 오류 페이지 표시
  Widget _buildErrorPage(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<MenuProvider>().clearError();
              context.read<StoreProvider>().clearError();
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _CategoryBarDelegate({required this.child, this.height = 60});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
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
