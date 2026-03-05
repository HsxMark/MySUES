**English** · [简体中文](docs/CHANGELOG.zh-Hans.md)

MySUES follows [Semantic Versioning 2.0.0](http://semver.org/).

## 0.4.0-beta.1

`2026-03-06`

- 🌟 Add home screen widget support for Android and iOS. @HsxMark
- 🌟 Add acknowledgements page with sponsor information. @HsxMark
- 🌟 Add notice entry in More page. @HsxMark
- 🌟 Add tips to sync button for better guidance. @HsxMark
- 🐛 Fix exam import error on iOS. @HsxMark
- 🐛 Fix multiple schedule display and establishment errors. @HsxMark
- 🐛 Fix mini schedule display error on screen. @HsxMark
- 🐛 Fix score display: adjust GPA display style and remove specific score detail. @HsxMark
- 🛠 Update application package name and entry screen. @HsxMark
- 🛠 Update Flutter configuration for iOS device. @HsxMark

## 0.3.1-beta.1

`2026-02-27`

- 🌟 Add sync disclaimer dialog before importing data from WebVPN, reminding users to verify imported data. @HsxMark
- 🐛 Fix default max week count from 20 to 30 to accommodate longer semesters. @HsxMark
- 🛠 Improve schedule manager bottom sheet UI with handle bar, fixed height, and Liquid Glass effect support. @HsxMark

## 0.3.0-beta.1

`2026-02-26`

- 🌟 Add QQ group feedback entry (Group: 1045770691) to the first-launch disclaimer dialog. @HsxMark
- 🛠 Add Liquid Glass effect to the schedule switching page. @HsxMark
- 🛠 Upgrade project dependencies (characters, matcher, material_color_utilities, test_api). @HsxMark

## 0.2.0-beta.1

`2026-02-19`

- 🌟 Support course reminder notifications, alerting 15 minutes before class with course name and classroom info. @HsxMark
- 🌟 Support exam reminder notifications with customizable advance days (1–7 days) and notification time. @HsxMark
- 🛠 Configure Android notification permissions and boot-completed receiver for scheduled notifications.
- 🛠 Remove feature introduction page from About screen. @HsxMark

## 0.1.0-beta.1

`2026-02-10`

- **🔥 Implement schedule table with weekly view, supporting single/double week course display. #1** @HsxMark
- **🔥 Implement score transcript with GPA calculation and detailed score modal.** @HsxMark
- **🔥 Support fetching exam information from the academic system via WebVPN. #2** @HsxMark
- **🔥 Introduce Liquid Glass UI effect across the app, including bottom navigation bar, modals, menus, and profile page. #3** @HsxMark
- 🌟 Support WebVPN login integration via WebView for securely fetching academic data (schedule, scores, exams, student info). @HsxMark
- 🌟 Support fetching and auto-selecting semester when importing schedule from WebVPN. @HsxMark
- 🌟 Support PDF course schedule import for offline access. @HsxMark
- 🌟 Add profile page with student info display, profile editing, and custom wallpaper background. @HsxMark
- 🌟 Support dark mode with full app adaptation. @HsxMark
- 🌟 Support custom timetable configuration with user-defined time slots (up to 15 periods per day). @HsxMark
- 🌟 Support toggling weekend display in the schedule view. @HsxMark
- 🌟 Add splash screen and first-launch disclaimer modal for user agreement. @HsxMark
- 🌟 Add About page with changelog, feature introduction, open source licenses, privacy policy, and sponsor info. @HsxMark
- 🌟 Add user agreement and privacy policy pages with Markdown rendering. @HsxMark
- 🌟 Add auto-refresh logic for schedule, score, and exam data pages. @HsxMark
- 🐛 Fix screen display bug when setting personal background image. #4 @HsxMark
- 🐛 Fix score page not refreshing correctly after data updates. @HsxMark
- 🐛 Fix student ID display error on the profile page. @HsxMark
- 🐛 Fix WebVPN fetch error in Safari for iPhone users. @HsxMark
- 🐛 Fix schedule display issues during non-active week periods. @HsxMark
- 🐛 Fix weekend logic error in schedule calculation. @HsxMark
- 🐛 Fix multiple score calculation and storage bugs. @HsxMark
- 🐛 Fix exam display errors after fetching data. @HsxMark
- 🐛 Fix cookie handling issue causing repeated login prompts. @HsxMark
- 🐛 Fix color rendering error in schedule table cells. @HsxMark
- 🐛 Fix profile background image display error. @HsxMark
- 🛠 Delete auto-update function from changelog to fix related issues. #5 @HsxMark
- 🛠 Rewrite schedule data fetching logic for improved reliability. @HsxMark
- 🛠 Add entrance limitation to prevent unauthorized access before agreeing to terms. @HsxMark
