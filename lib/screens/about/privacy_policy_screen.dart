import 'package:flutter/material.dart';
import 'package:mysues/l10n/l10n.dart';

import 'legal_document_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => LegalDocumentScreen(
    title: context.l10n.privacyPolicy,
    assetBaseName: 'privacy',
  );
}
