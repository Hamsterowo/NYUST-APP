class CalendarEvent {
  final String id;
  final String date;
  final String name;
  final String link;
  final bool isImportant;

  CalendarEvent({
    required this.id,
    required this.date,
    required this.name,
    required this.link,
    this.isImportant = false,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      date: json['date'] as String,
      name: json['name'] as String,
      link: json['link'] as String,
      isImportant: json['isImportant'] ?? false,
    );
  }

  /// Helper to get a [DateTime] object from the date string
  DateTime getDateTime() {
    return DateTime.parse(date);
  }
}
