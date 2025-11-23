import 'package:flutter/foundation.dart';

import 'package:table_order/models/customer/store.dart';
import 'package:table_order/service/customer/store_service.dart';

class StoreProvider with ChangeNotifier {
  final StoreService _service = StoreService();

  List<Store> _stores = [];

  Future<void> loadStore() async {
    _stores = await _service.getStores();
    notifyListeners();
  }
}
