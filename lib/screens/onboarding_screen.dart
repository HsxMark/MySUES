import 'package:flutter/material.dart';
import 'package:mysues/l10n/l10n.dart';

class OnboardingScreen extends StatefulWidget {
  /// When true, completing the tutorial will NOT write to SharedPreferences.
  final bool isReview;

  const OnboardingScreen({super.key, this.isReview = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_PageData> _pages(BuildContext context) => [
    _PageData(
      image: 'assets/images/MySUES.png',
      isLogo: true,
      title: context.l10n.welcomeToMySues,
      description: context.l10n.yourAllInOneCampusAssistantForASimpler,
    ),
    _PageData(
      image: 'assets/images/example/scheduledaily.png',
      secondaryImage: 'assets/images/example/scheduleinfo.PNG',
      isLogo: false,
      title: context.l10n.viewSchedule,
      description: context.l10n.viewWeeklyOrDailyClassesAndImportSchedulesFrom,
    ),
    _PageData(
      image: 'assets/images/example/scoreinfo.PNG',
      isLogo: false,
      title: context.l10n.viewGrades,
      description: context.l10n.reviewGradesAndGpaWheneverYouNeedThem,
    ),
    _PageData(
      image: 'assets/images/example/testinfo.PNG',
      isLogo: false,
      title: context.l10n.viewExams,
      description: context.l10n.keepTrackOfExamTimesAndLocations,
    ),
    _PageData(
      image: 'assets/images/example/widget.PNG',
      isLogo: false,
      title: context.l10n.homeScreenWidget,
      description: context.l10n.addYourScheduleToTheHomeScreenForQuick,
    ),
  ];

  static const _pageCount = 5;

  bool get _isLastPage => _currentPage == _pageCount - 1;

  void _nextPage() {
    if (!_isLastPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pages = _pages(context);

    return PopScope(
      canPop: widget.isReview,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Skip button (top-right)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 16),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.skip),
                  ),
                ),
              ),
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = pages[index];
                    if (page.isLogo) {
                      return _buildWelcomePage(context, page);
                    }
                    return _buildFeaturePage(context, page);
                  },
                ),
              ),
              // Dots indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pages.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              // Bottom button
              Padding(
                padding: const EdgeInsets.only(left: 40, right: 40, bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: _isLastPage
                      ? FilledButton(
                          onPressed: _nextPage,
                          child: Text(context.l10n.enterMySues),
                        )
                      : OutlinedButton(
                          onPressed: _nextPage,
                          child: Text(context.l10n.next),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Welcome page: centered logo + text
  Widget _buildWelcomePage(BuildContext context, _PageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(page.image, width: 120, height: 120, fit: BoxFit.contain),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            page.description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Feature page: title on top, screenshot in center, description below
  Widget _buildFeaturePage(BuildContext context, _PageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            page.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            page.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: page.secondaryImage != null
                ? Row(
                    children: [
                      Expanded(
                        child: Center(child: _buildImageContainer(page.image)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Center(
                          child: _buildImageContainer(page.secondaryImage!),
                        ),
                      ),
                    ],
                  )
                : Center(child: _buildImageContainer(page.image)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImageContainer(String imagePath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(imagePath, fit: BoxFit.contain),
      ),
    );
  }
}

class _PageData {
  final String image;
  final String? secondaryImage;
  final bool isLogo;
  final String title;
  final String description;

  const _PageData({
    required this.image,
    this.secondaryImage,
    required this.isLogo,
    required this.title,
    required this.description,
  });
}
