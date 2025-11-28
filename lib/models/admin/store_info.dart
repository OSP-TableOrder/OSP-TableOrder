class StoreInfoModel {
  final String storeName;
  final String notice;

  const StoreInfoModel({required this.storeName, required this.notice});

  // 데이터 수정 시 불변성을 유지하며 새로운 객체를 만들기 위한 메서드
  StoreInfoModel copyWith({String? storeName, String? notice}) {
    return StoreInfoModel(
      storeName: storeName ?? this.storeName,
      notice: notice ?? this.notice,
    );
  }

  // 초기 상태값 정의 (빈 값 방지용)
  factory StoreInfoModel.initial() {
    return const StoreInfoModel(storeName: "", notice: "");
  }
}
