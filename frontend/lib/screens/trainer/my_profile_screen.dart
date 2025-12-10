// lib/screens/trainer/my_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/gifts_tab.dart';
import '../../widgets/unlock_tab.dart';
import '../../widgets/boosts_tab.dart';
import '../../widgets/profile_header.dart';
import 'package:frontend/app_theme.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // FIX: Wrap entire content in SingleChildScrollView
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            const ProfileHeader(),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryOrange,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppTheme.primaryOrange,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Text(
                      'GIFTS',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'UNLOCK',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'BOOSTS',
                      style: TextStyle(
                        fontSize: isDesktop ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            // FIX: Use a constrained height for TabBarView
            SizedBox(
              height: screenHeight * 0.6, // 60% of screen height
              child: TabBarView(
                controller: _tabController,
                children: const [
                  GiftsTab(),
                  UnlockTab(),
                  BoostsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
