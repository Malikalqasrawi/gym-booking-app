import '../utils/dates.dart';

/// A branch closure or a trainer's time off, from startDate to endDate (inclusive),
/// either all day or between startTime and endTime on each of those days.
class BlockedTime {
  final int id;
  final int? branchId;
  final String? branchName;
  final int? trainerId;
  final String? trainerName;
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime;
  final String? endTime;
  final bool allDay;
  final String? reason;

  const BlockedTime({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.trainerId,
    required this.trainerName,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.allDay,
    required this.reason,
  });

  bool get isBranch => branchId != null;

  /// "Abdoun Branch" or "Sara Haddad".
  String get targetName => (isBranch ? branchName : trainerName) ?? '';

  /// "Mon 6 Oct", "Mon 6 Oct – Wed 8 Oct", plus ", 14:00 – 17:00" when not all day.
  String get whenLabel {
    final days = startDate == endDate ? prettyDate(startDate) : '${prettyDate(startDate)} – ${prettyDate(endDate)}';
    return allDay ? '$days, all day' : '$days, $startTime – $endTime';
  }

  factory BlockedTime.fromJson(Map<String, dynamic> json) => BlockedTime(
        id: (json['id'] as num).toInt(),
        branchId: (json['branchId'] as num?)?.toInt(),
        branchName: json['branchName'] as String?,
        trainerId: (json['trainerId'] as num?)?.toInt(),
        trainerName: json['trainerName'] as String?,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
        allDay: json['allDay'] as bool? ?? true,
        reason: json['reason'] as String?,
      );
}

/// What the admin fills in to block time. Set either [branchId] or [trainerId].
class BlockedTimeDraft {
  final int? branchId;
  final int? trainerId;
  final DateTime startDate;
  final DateTime endDate;
  final String? startTime; // both null for whole days
  final String? endTime;
  final String reason;

  const BlockedTimeDraft({
    this.branchId,
    this.trainerId,
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
    this.reason = '',
  });

  Map<String, dynamic> toJson() => {
        if (branchId != null) 'branchId': branchId,
        if (trainerId != null) 'trainerId': trainerId,
        'startDate': isoDate(startDate),
        'endDate': isoDate(endDate),
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      };

  /// The first problem the backend would also reject, or null. Messages match the backend's.
  String? get problem {
    if (endDate.isBefore(startDate)) return 'The end date is before the start date.';
    if (startTime != null && endTime != null && endTime!.compareTo(startTime!) <= 0) {
      return 'The end time must be after the start time.';
    }
    return null;
  }
}

/// How many bookings a block would cancel.
class BlockImpact {
  final int bookings;
  final int paidBookings;

  const BlockImpact({required this.bookings, required this.paidBookings});

  factory BlockImpact.fromJson(Map<String, dynamic> json) => BlockImpact(
        bookings: (json['bookings'] as num).toInt(),
        paidBookings: (json['paidBookings'] as num).toInt(),
      );
}

class BlockedTimeCreated {
  final BlockedTime blockedTime;
  final int cancelledBookings;
  final int refundedBookings;

  const BlockedTimeCreated({
    required this.blockedTime,
    required this.cancelledBookings,
    required this.refundedBookings,
  });

  factory BlockedTimeCreated.fromJson(Map<String, dynamic> json) => BlockedTimeCreated(
        blockedTime: BlockedTime.fromJson(json['blockedTime'] as Map<String, dynamic>),
        cancelledBookings: (json['cancelledBookings'] as num).toInt(),
        refundedBookings: (json['refundedBookings'] as num).toInt(),
      );
}
