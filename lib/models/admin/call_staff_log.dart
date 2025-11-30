class CallStaffLog {
  final String id;
  final String tableId;
  final String table;
  final String message;
  final String time;
  final bool resolved;

  CallStaffLog({
    required this.id,
    required this.tableId,
    required this.table,
    required this.message,
    required this.time,
    this.resolved = false,
  });
}
