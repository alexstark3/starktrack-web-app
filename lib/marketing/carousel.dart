import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'carousel_config.dart';

class DashboardCarousel extends StatefulWidget {
  const DashboardCarousel({super.key});

  @override
  State<DashboardCarousel> createState() => _DashboardCarouselState();
}

class _DashboardCarouselState extends State<DashboardCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.7);
  int _currentIndex = 0;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    // Start at a high index for endless scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageController.animateToPage(
        1000, // Start at a high index
        duration: const Duration(milliseconds: 1),
        curve: Curves.easeInOut,
      );
    });
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel(); // Cancel any existing timer
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _pauseAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _resumeAutoScroll() {
    // Add a delay before resuming to prevent immediate auto-scroll after manual navigation
    Timer(const Duration(seconds: 5), _startAutoScroll);
  }

  String _getDescriptionForIndex(int index) {
    return CarouselConfig.getShortName(index);
  }

  String _getFullDescriptionForIndex(int index) {
    return CarouselConfig.getFullDescription(index);
  }

  String _getImageFilename(int index) {
    return CarouselConfig.getImageFilename(index);
  }

  void _nextPage() {
    _pauseAutoScroll();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _resumeAutoScroll();
  }

  void _previousPage() {
    _pauseAutoScroll();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _resumeAutoScroll();
  }


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Column(
      children: [
        SizedBox(
          height: isMobile ? 400 : 700,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: 2000, // Large number for endless scrolling
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index % 6; // Cycle through 0-5
                  });
                },
                itemBuilder: (context, index) {
                  final imageIndex = index % 6; // Cycle through 0-5
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colors.textColor.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            color: Colors.white, // Changed from colors.backgroundLight to white
                            child: Center( // Added Center widget to center the image
                              child: Image.asset(
                                'assets/dasboard_img/${_getImageFilename(imageIndex)}',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.white,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.dashboard,
                                          size: 80,
                                          color: colors.primaryBlue,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Dashboard ${imageIndex + 1}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: colors.primaryBlue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Description overlay at the bottom (only if description exists)
                          if (_getFullDescriptionForIndex(imageIndex).isNotEmpty)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  _getFullDescriptionForIndex(imageIndex),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Left invisible clickable area
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _previousPage,
                  child: Container(
                    width: screenWidth * 0.15, // 15% of screen width
                    color: Colors.transparent, // Invisible
                  ),
                ),
              ),
              // Right invisible clickable area
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    width: screenWidth * 0.15, // 15% of screen width
                    color: Colors.transparent, // Invisible
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Clickable navigation boxes - Responsive sizing
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(CarouselConfig.imageFilenames.length, (index) {
            final isActive = _currentIndex == index;
            return GestureDetector(
              onTap: () {
                _pauseAutoScroll();
                // Navigate directly to the specific image
                final currentPage = _pageController.page?.round() ?? 1000;
                final targetPage = currentPage - (_currentIndex - index);
                
                _pageController.animateToPage(
                  targetPage,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                // Resume auto-scroll after 5 seconds
                Timer(const Duration(seconds: 5), () {
                  _resumeAutoScroll();
                });
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 12, 
                  vertical: isMobile ? 4 : 8
                ),
                decoration: BoxDecoration(
                  color: isActive ? colors.primaryBlue : Colors.transparent,
                  border: Border.all(
                    color: isActive ? colors.primaryBlue : colors.primaryBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 4 : 6),
                ),
                child: Text(
                  _getDescriptionForIndex(index),
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 14,
                    color: isActive ? Colors.white : colors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
