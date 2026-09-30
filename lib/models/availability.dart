class TimeSlot {
  final String start;
  final String end;

  const TimeSlot({required this.start, required this.end});

  String get label => '$start – $end';

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(start: json['start'] as String, end: json['end'] as String);
  }
}

class Availability {
  final String date;
  final int durationMinutes;
  final List<TimeSlot> slots;

  const Availability({required this.date, required this.durationMinutes, required this.slots});

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      date: json['date'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      slots: ((json['slots'] as List?) ?? const [])
          .map((item) => TimeSlot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
