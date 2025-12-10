// lib/screens/trainer/trainer_dashboard_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/gradient_elevated_button.dart';
import '../../app_theme.dart';

class TrainerDashboardShell extends ConsumerStatefulWidget {
  final Widget child;

  const TrainerDashboardShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<TrainerDashboardShell> createState() =>
      _TrainerDashboardShellState();
}

class _TrainerDashboardShellState extends ConsumerState<TrainerDashboardShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.person,
      label: 'My Profile',
      route: '/trainer-dashboard',
    ),
    NavigationItem(
      icon: Icons.card_giftcard,
      label: 'Gift Exchange',
      route: '/trainer-dashboard/gift-exchange',
    ),
    NavigationItem(
      icon: Icons.calendar_today,
      label: 'Calendar',
      route: '/trainer-dashboard/calendar',
    ),
    NavigationItem(
      icon: Icons.people,
      label: 'Friends',
      route: '/trainer-dashboard/friends',
    ),
    NavigationItem(
      icon: Icons.payment,
      label: 'Payment',
      route: '/trainer-dashboard/payment',
    ),
    NavigationItem(
      icon: Icons.settings,
      label: 'Settings',
      route: '/trainer-dashboard/settings',
    ),
    NavigationItem(
      icon: Icons.help_outline,
      label: 'Help & Support',
      route: '/trainer-dashboard/support',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(context, isDesktop),
      drawer: isDesktop ? null : _buildMobileDrawer(),
      body: isDesktop
          ? Row(
              children: [
                _buildDesktopSidebar(),
                Expanded(
                  child: widget.child,
                ),
              ],
            )
          : widget.child,
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomNav(),
    );
  }

  AppBar _buildAppBar(BuildContext context, bool isDesktop) {
    return AppBar(
      backgroundColor: const Color(0xFF353C3A),
      leading: isDesktop
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/fitneks_icon.png',
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.fitness_center, color: Colors.white),
              ),
            )
          : IconButton(
              icon: Consumer(
                builder: (context, ref, child) {
                  final profileAsync = ref.watch(profileProvider);
                  return profileAsync.when(
                    data: (profile) => CircleAvatar(
                      radius: 16,
                      backgroundImage: profile.profilePictureUrl != null &&
                              profile.profilePictureUrl!.isNotEmpty
                          ? NetworkImage(profile.profilePictureUrl!)
                          : const AssetImage('assets/images/default_avatar.png')
                              as ImageProvider,
                    ),
                    loading: () => const CircleAvatar(
                        radius: 16, backgroundColor: Colors.grey),
                    error: (e, s) => const CircleAvatar(
                        radius: 16, child: Icon(Icons.person)),
                  );
                },
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
      title: !isDesktop
          ? Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey[400], size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null,
      actions: [
        if (isDesktop) ...[
          Container(
            width: 300,
            height: 36,
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[700],
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          GradientElevatedButton.icon(
            onPressed: () => _showGoLiveDialog(context),
            icon: Image.asset(
              'assets/images/fitneks_icon.png',
              width: 20,
              height: 20,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.play_arrow, size: 20, color: Colors.white),
            ),
            label: const Text('GO LIVE', style: TextStyle(color: Colors.white)),
            style: ButtonStyle(
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () => context.go('/trainer-dashboard'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  context.go('/trainer-dashboard/settings');
                  break;
                case 'support':
                  context.go('/trainer-dashboard/support');
                  break;
                case 'feedback':
                  context.go('/trainer-dashboard/feedback');
                  break;
                case 'logout':
                  ref.read(authProvider.notifier).logout(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(
                  value: 'support', child: Text('Help & Support')),
              const PopupMenuItem(
                  value: 'feedback', child: Text('Give Feedback')),
              const PopupMenuItem(value: 'logout', child: Text('Log Out')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final profileAsync = ref.watch(profileProvider);
              return profileAsync.when(
                data: (profile) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.go('/profile/${profile.username}');
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: profile.profilePictureUrl != null &&
                                  profile.profilePictureUrl!.isNotEmpty
                              ? NetworkImage(profile.profilePictureUrl!)
                              : const AssetImage(
                                      'assets/images/default_avatar.png')
                                  as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${profile.username}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => const SizedBox(height: 150),
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;

                return ListTile(
                  leading: Icon(
                    item.icon,
                    color:
                        isSelected ? AppTheme.primaryOrange : Colors.grey[700],
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryOrange
                          : Colors.grey[700],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppTheme.primaryOrange.withOpacity(0.1),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    context.go(item.route);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text('Log out'),
            onTap: () => ref.read(authProvider.notifier).logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final profileAsync = ref.watch(profileProvider);
              return profileAsync.when(
                data: (profile) => DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFA500), Color(0xFFFF6B00)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/profile/${profile.username}');
                          },
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                profile.profilePictureUrl != null &&
                                        profile.profilePictureUrl!.isNotEmpty
                                    ? NetworkImage(profile.profilePictureUrl!)
                                    : const AssetImage(
                                            'assets/images/default_avatar.png')
                                        as ImageProvider,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${profile.username}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => const DrawerHeader(
                  child: Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                ),
                error: (err, stack) => const DrawerHeader(
                  child: Center(child: Icon(Icons.error, color: Colors.white)),
                ),
              );
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                return ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(item.route);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.grey),
            title: const Text('Log out'),
            onTap: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.inbox_outlined),
              onPressed: () => _showNotifications(context),
            ),
            ElevatedButton(
              onPressed: () => _showGoLiveDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
              ),
              child: Image.asset(
                'assets/images/fitneks_icon.png',
                width: 24,
                height: 24,
                color: Colors.white,
                errorBuilder: (c, e, s) =>
                    const Icon(Icons.play_arrow, color: Colors.white, size: 24),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go('/trainer-dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGoLiveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Go Live'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Create Class'),
              hoverColor: AppTheme.secondaryOrange.withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                context.go('/trainer-dashboard/create-class');
              },
            ),
            ListTile(
              title: const Text('Create Challenge'),
              hoverColor: const Color(0xFFFF6B00).withOpacity(0.1),
              onTap: () {
                Navigator.pop(context);
                context.go('/trainer-dashboard/create-challenge');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.favorite, color: Colors.red),
                    title: Text('New follower!'),
                    subtitle: Text('John Doe started following you'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
