import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/create_stream_provider.dart';
import '../../providers/auth_provider.dart';
import 'pages/name_description_page.dart';
import 'pages/monetization_page.dart';
import 'pages/configuration_page.dart';
import 'pages/scheduling_page.dart';
import 'pages/workout_details_page.dart';
import 'pages/muscle_focus_page.dart';
import 'pages/summary_page.dart';
import 'package:go_router/go_router.dart';


class CreateStreamScreen extends ConsumerStatefulWidget {
  final String? livestreamId;
  
  const CreateStreamScreen({
    Key? key,
    this.livestreamId,
  }) : super(key: key);

  @override
  ConsumerState<CreateStreamScreen> createState() => _CreateStreamScreenState();
}

class _CreateStreamScreenState extends ConsumerState<CreateStreamScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    
    // ✅ Load existing data if editing
    if (widget.livestreamId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadLivestreamData();
      });
    }
  }

  // ✅ Add this method to load existing livestream data
  Future<void> _loadLivestreamData() async {
  final authState = ref.read(authProvider);
  final token = authState.token;
  
  // ✅ Debug: Check if token exists
  print('🔑 Token exists: ${token != null}');
  print('🆔 Event ID: ${widget.livestreamId}');
  
  if (token == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in again'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }
  
  try {
    final repository = ref.read(livestreamRepositoryProvider);
    print('📡 Fetching livestream by event ID...');
    
    final livestream = await repository.getLivestreamByEventId(widget.livestreamId!, token);
    
    print('✅ Livestream loaded successfully');
    
    // Populate the form
    ref.read(createStreamProvider.notifier).loadFromLivestream(livestream);
    
    // Jump to summary page (page 6)
    _pageController.jumpToPage(6);
    setState(() {
      _currentPage = 6;
    });
  } catch (e) {
    print('❌ Error loading livestream: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load stream: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    final state = ref.watch(createStreamProvider);
    
    switch (_currentPage) {
      case 0: // Name & Description
        return state.title != null && state.title!.isNotEmpty &&
               state.title!.length <= 50 &&
               state.description != null && state.description!.isNotEmpty &&
               state.description!.length <= 200;
      case 1: // Monetization - always valid
        return true;
      case 2: // Configuration
        return state.maxParticipants != null;
      case 3: // Scheduling
        return state.goLiveNow || state.scheduledAt != null;
      case 4: // Workout Details
        return state.equipmentNeeded.isNotEmpty && state.workoutStyle != null;
      case 5: // Muscle Focus - always valid
        return true;
      case 6: // Summary - always valid
        return true;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_currentPage < 6 && _canProceed()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.livestreamId != null ? 'Edit Live Stream' : 'Create Live Stream'),  // ✅ Dynamic title
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentPage > 0) {
              _previousPage();
            } else {
              context.go('/trainer-dashboard');
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / 7,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4D00)),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Step ${_currentPage + 1} of 7',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                NameDescriptionPage(pageController: _pageController),
                MonetizationPage(pageController: _pageController),
                ConfigurationPage(pageController: _pageController),
                SchedulingPage(pageController: _pageController),
                WorkoutDetailsPage(pageController: _pageController),
                MuscleFocusPage(pageController: _pageController),
                SummaryPage(pageController: _pageController),
              ],
            ),
          ),
          if (_currentPage < 6)
            Consumer(
              builder: (context, ref, child) {
                final canProceed = _canProceed();
                
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            child: const Text('Back'),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: canProceed ? _nextPage : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4D00),
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}