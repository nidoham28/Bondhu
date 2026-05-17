import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bondhu/features/stories/models/story_model.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final ValueChanged<String> onStorySeen;

  const StoryViewerScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
    required this.onStorySeen,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animController;

  static const _storyDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _animController = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener(_onAnimStatus);
    _animController.forward();

    widget.onStorySeen(widget.stories[_currentIndex].id);
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _goNext();
  }

  void _goNext() {
    if (_currentIndex < widget.stories.length - 1) {
      _currentIndex++;
      _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goPrevious() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.animateToPage(_currentIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _animController.reset();
    _animController.forward();
    widget.onStorySeen(widget.stories[index].id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.stories.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          return _StoryViewItem(
            story: story,
            animController: _animController,
            storyIndex: index,
            totalStories: widget.stories.length,
            onPrevious: _goPrevious,
            onNext: _goNext,
            onClose: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }
}

class _StoryViewItem extends StatelessWidget {
  final StoryModel story;
  final AnimationController animController;
  final int storyIndex;
  final int totalStories;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onClose;

  const _StoryViewItem({
    required this.story,
    required this.animController,
    required this.storyIndex,
    required this.totalStories,
    required this.onPrevious,
    required this.onNext,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Story Image ──
        if (story.storyImageUrl != null)
          story.storyImageUrl!.startsWith('http')
              ? Image.network(story.storyImageUrl!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)
              : Image.file(File(story.storyImageUrl!), fit: BoxFit.cover, width: double.infinity, height: double.infinity),

        // ── Bottom gradient ──
        if (story.textOverlay != null || story.location != null)
          const Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: SizedBox(
                height: 350,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── Top gradient ──
        const Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: SizedBox(
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Content Column ──
        Column(
          children: [
            _buildHeader(context),
            const Spacer(),
            if (story.textOverlay != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  story.textOverlay!,
                  style: TextStyle(
                    color: _hexToColor(story.textColor),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    fontFamily: story.fontFamily,
                    shadows: const [Shadow(offset: Offset(0, 1), blurRadius: 6, color: Colors.black87)],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),

            if (story.location != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(story.location!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

            if (story.musicUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    const Text('Playing audio...', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),

        // ── View Counter (For your own story) ──
        if (story.isYourStory)
          Positioned(
            bottom: 20,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text('${story.totalViews}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),

        // ── Tap navigation areas ──
        Row(
          children: [
            Expanded(child: GestureDetector(onTap: onPrevious)),
            const SizedBox(width: 100),
            Expanded(child: GestureDetector(onTap: onNext)),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: List.generate(totalStories, (i) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: _StoryProgressIndicator(
                      animController: animController,
                      isActive: i == storyIndex,
                      isComplete: i < storyIndex,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: story.profileImageUrl != null ? NetworkImage(story.profileImageUrl!) : null,
                  backgroundColor: Colors.grey[800],
                  child: story.profileImageUrl == null ? Text(story.displayName[0], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(story.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(story.timeAgo, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                )),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: onClose),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _hexToColor(String hexString) {
    final hex = hexString.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class _StoryProgressIndicator extends StatelessWidget {
  final AnimationController animController;
  final bool isActive;
  final bool isComplete;

  const _StoryProgressIndicator({
    required this.animController,
    required this.isActive,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animController,
      builder: (context, _) {
        final fillFraction = isComplete ? 1.0 : isActive ? animController.value : 0.0;
        return Container(
          height: 2.5,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(1.5)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1.5),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fillFraction,
              child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1.5))),
            ),
          ),
        );
      },
    );
  }
}