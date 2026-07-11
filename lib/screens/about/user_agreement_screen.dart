import 'package:flutter/material.dart';
import 'package:mysues/l10n/l10n.dart';

import 'legal_document_screen.dart';

class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) => LegalDocumentScreen(
    title: context.l10n.userAgreement,
    assetBaseName: 'agreement',
  );
}
