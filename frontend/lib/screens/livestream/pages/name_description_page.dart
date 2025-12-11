import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/create_stream_provider.dart';

/// Page 1: Stream name and description
class NameDescriptionPage extends ConsumerWidget {
  final PageController pageController;
  
  const NameDescriptionPage({
    Key? key,
    required this.pageController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createStreamProvider);
    final notifier = ref.read(createStreamProvider.notifier);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Name Your Stream',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          // Title field
          TextFormField(
            initialValue: state.title,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: 'Stream Title',
              hintText: 'Enter a catchy title for your stream',
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF4D00), width: 2),
              ),
              counterText: '${state.title?.length ?? 0}/50',
            ),
            onChanged: notifier.updateTitle,
          ),
          const SizedBox(height: 24),
          
          // Description field
          TextFormField(
            initialValue: state.description,
            maxLength: 200,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Describe what participants can expect',
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFF4D00), width: 2),
              ),
              alignLabelWithHint: true,
              counterText: '${state.description?.length ?? 0}/200',
            ),
            onChanged: notifier.updateDescription,
          ),
          
          const SizedBox(height: 16),
          Text(
            'This information will be visible to all users browsing streams.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}