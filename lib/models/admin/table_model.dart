class TableModel {
  final String id;
  final String name;
  final String storeId;

  const TableModel({
    required this.id,
    required this.name,
    required this.storeId,
  });

  // QR 코드에 들어갈 웹 URL 반환
  String get qrData => 'https://kit-osp-25-2-toss-place.web.app/?storeId=$storeId&tableId=$id';

  TableModel copyWith({String? id, String? name, String? storeId}) {
    return TableModel(
      id: id ?? this.id,
      name: name ?? this.name,
      storeId: storeId ?? this.storeId,
    );
  }
}
