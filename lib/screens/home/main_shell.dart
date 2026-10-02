import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../state/session_controller.dart';
import '../admin/admin_bookings_screen.dart';
import '../admin/admin_branches_screen.dart';
import '../admin/admin_trainers_screen.dart';
import '../booking/branch_map_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../trainer/trainer_requests_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

enum AppTab { home, book, bookings, sessions, trainers, branches, profile }

/// Lets screens inside the shell switch tabs, e.g. the home screen's "My bookings" tile.
class TabSwitcher extends InheritedWidget {
  const TabSwitcher({super.key, required this.select, required super.child});

  final ValueChanged<AppTab> select;

  static void goTo(BuildContext context, AppTab tab) =>
      context.getInheritedWidgetOfExactType<TabSwitcher>()?.select(tab);

  @override
  bool updateShouldNotify(TabSwitcher oldWidget) => false;
}

/// The logged-in app: one page per tab and a bottom navigation bar, with tabs for the user's role.
/// A tab's page is built fresh each time it is opened, so it always shows current data.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _Destination {
  const _Destination(this.tab, this.label, this.icon, this.selectedIcon, this.page);

  final AppTab tab;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

class _MainShellState extends State<MainShell> {
  AppTab _tab = AppTab.home;

  static const _home = _Destination(AppTab.home, 'Home', Icons.home_outlined, Icons.home, HomeScreen());
  static const _profile =
      _Destination(AppTab.profile, 'Profile', Icons.person_outline, Icons.person, ProfileScreen());

  static List<_Destination> _destinationsFor(UserRole role) => switch (role) {
        UserRole.member => const [
            _home,
            _Destination(AppTab.book, 'Book', Icons.map_outlined, Icons.map, BranchMapScreen()),
            _Destination(AppTab.bookings, 'Bookings', Icons.event_note_outlined, Icons.event_note, MyBookingsScreen()),
            _profile,
          ],
        UserRole.trainer => const [
            _home,
            _Destination(AppTab.sessions, 'Sessions', Icons.event_available_outlined, Icons.event_available,
                TrainerRequestsScreen()),
            _profile,
          ],
        UserRole.admin => const [
            _home,
            _Destination(AppTab.bookings, 'Bookings', Icons.event_note_outlined, Icons.event_note,
                AdminBookingsScreen()),
            _Destination(AppTab.trainers, 'Trainers', Icons.groups_outlined, Icons.groups, AdminTrainersScreen()),
            _Destination(AppTab.branches, 'Branches', Icons.store_mall_directory_outlined,
                Icons.store_mall_directory, AdminBranchesScreen()),
            _profile,
          ],
      };

  void _select(AppTab tab) {
    if (tab != _tab) setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink(); // briefly null while logging out

    final destinations = _destinationsFor(user.role);
    final found = destinations.indexWhere((d) => d.tab == _tab);
    final index = found < 0 ? 0 : found;

    return TabSwitcher(
      select: _select,
      // Back on another tab returns to Home instead of leaving the app.
      child: PopScope(
        canPop: index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _select(AppTab.home);
        },
        child: Scaffold(
          body: destinations[index].page,
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) => _select(destinations[i].tab),
            destinations: [
              for (final d in destinations)
                NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
            ],
          ),
        ),
      ),
    );
  }
}
