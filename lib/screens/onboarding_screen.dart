import 'package:flutter/material.dart';

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

  static const List<_PageData> _pages = [
    _PageData(
      image: 'assets/images/example/MySUES-1024x1024@1x.png',
      isLogo: true,
      title: '欢迎使用苏伊士 My SUES',
      description: '一站式校园信息助手，让你的校园生活更便捷。',
    ),
    _PageData(
      image: 'assets/images/example/scheduledaily.PNG',
      secondaryImage: 'assets/images/example/scheduleinfo.PNG',
      isLogo: false,
      title: '查看课表',
      description: '快速查看每周或每日课程安排，支持导入教务系统课表。',
    ),
    _PageData(
      image: 'assets/images/example/scoreinfo.PNG',
      isLogo: false,
      title: '查看个人成绩',
      description: '随时查看各科成绩与绩点，掌握学业情况。',
    ),
    _PageData(
      image: 'assets/images/example/testinfo.PNG',
      isLogo: false,
      title: '查看考试信息',
      description: '及时获取考试时间与地点，不错过每场考试。',
    ),
    _PageData(
      image: 'assets/images/example/widget.PNG',
      isLogo: false,
      title: '桌面小组件',
      description: '将课表添加到桌面，无需打开应用即可查看。',
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

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
                    child: const Text('跳过'),
                  ),
                ),
              ),
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
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
                  children: List.generate(_pages.length, (index) {
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
                padding:
                    const EdgeInsets.only(left: 40, right: 40, bottom: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: _isLastPage
                      ? FilledButton(
                          onPressed: _nextPage,
                          child: const Text('进入 苏伊士'),
                        )
                      : OutlinedButton(
                          onPressed: _nextPage,
                          child: const Text('下一步'),
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
          Image.asset(
            page.image,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            page.description,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey[600]),
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
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            page.description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: page.secondaryImage != null
                ? Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: _buildImageContainer(page.image),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Center(
                          child: _buildImageContainer(page.secondaryImage!),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: _buildImageContainer(page.image),
                  ),
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
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
        ),
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
