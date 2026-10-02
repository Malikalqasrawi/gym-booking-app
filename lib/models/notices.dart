import '../utils/dates.dart';
import 'booking.dart';

/// Sessions the gym cancelled that the member should see on the home screen: not dismissed yet
/// and not in the past. Soonest first.
List<Booking> gymCancellationNotices(List<Booking> bookings, Set<int> dismissed, DateTime now) {
  return bookings
      .where((b) =>
          b.status == BookingStatus.cancelled &&
          b.cancelledByGym &&
          !dismissed.contains(b.id) &&
          atTime(b.date, b.startTime).isAfter(now))
      .toList()
    ..sort((a, b) => atTime(a.date, a.startTime).compareTo(atTime(b.date, b.startTime)));
}
