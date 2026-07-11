import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mysues/l10n/legacy_text.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.assetBaseName,
  });

  final String title;
  final String assetBaseName;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final suffix = languageCode == 'zh' ? 'zh' : 'en';
    final assetPath = 'assets/legal/${assetBaseName}_$suffix.md';

    return Scaffold(
      appBar: AppBar(title: LText(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: LText(snapshot.error.toString()));
          }
          return Markdown(
            data: snapshot.data ?? '',
            padding: const EdgeInsets.all(16),
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  p: const TextStyle(fontSize: 14, height: 1.5),
                  h3: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 2,
                  ),
                ),
          );
        },
      ),
    );
  }
}
