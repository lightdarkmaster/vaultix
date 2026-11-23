import '../../../core/constants/app_info.dart';

class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.intro,
    required this.sections,
  });
  final String title;
  final String intro;
  final List<LegalSection> sections;
}

const privacyPolicy = LegalDocument(
  title: 'Privacy Policy',
  intro: 'Vaultix is a local-first password manager. Your vault stays on '
      'your device. This policy explains exactly what that means.',
  sections: [
    LegalSection(
      'The short version',
      'Vaultix has no accounts, no servers, no analytics, no advertising and '
          'no tracking. The app does not send your passwords or any other '
          'personal data to the developer or to anyone else.',
    ),
    LegalSection(
      'What Vaultix stores on your device',
      'Entries you create (name, website address, username, password, notes, '
          'tags, category, favorite status and dates), your categories, and '
          'your app settings.\n\n'
          'Passwords and notes are encrypted with AES-256-GCM using a random '
          'vault key. That key is itself protected by a key derived from your '
          'master password with Argon2id.\n\n'
          'Entry names, website addresses, usernames and tags are stored '
          'without encryption inside the app\'s private database so that '
          'search works. Other apps cannot read this database on an '
          'unmodified device, but someone with full access to a rooted or '
          'compromised device could.',
    ),
    LegalSection(
      'Your master password',
      'Your master password is never stored, only used to derive a key. '
          'Because of this, nobody, including the developer, can recover it. '
          'If you forget it, your vault cannot be opened.',
    ),
    LegalSection(
      'PIN and biometric unlock',
      'If you enable quick unlock, a protected copy of your vault key is kept '
          'in Android Keystore-backed secure storage on your device. Biometric '
          'data (fingerprint or face) is handled entirely by Android; Vaultix '
          'only receives a yes or no result and never sees your biometric '
          'data. You can turn these off at any time in Settings.',
    ),
    LegalSection(
      'Clipboard',
      'When you copy a password or notes, Vaultix clears the clipboard after '
          'the delay you choose in Settings. While the data is on the '
          'clipboard, other apps on your device may be able to read it.',
    ),
    LegalSection(
      'Network access',
      'Vaultix does not use the internet. When you open a website from an '
          'entry, it opens in your browser or another app, which is governed '
          'by that app\'s own privacy policy.',
    ),
    LegalSection(
      'Backups and sharing',
      'Backups are encrypted with a separate backup password that you '
          'choose. When you share a backup file, the app or service you share '
          'it with receives that encrypted file. Keep the backup password '
          'safe; it cannot be recovered.',
    ),
    LegalSection(
      'Deleting your data',
      'You can erase everything at any time with Settings > Vault management '
          '> Clear vault data. Uninstalling Vaultix also removes its data from '
          'your device. Backup files you created remain wherever you saved or '
          'shared them until you delete them.',
    ),
    LegalSection(
      'Changes to this policy',
      'If this policy changes, the updated version will ship with a new '
          'version of the app. The date at the top shows when it was last '
          'updated.',
    ),
    LegalSection(
      'Contact',
      'Developer details are listed in Settings > About.',
    ),
  ],
);

const termsAndConditions = LegalDocument(
  title: 'Terms and Conditions',
  intro: 'By installing or using Vaultix you agree to these terms. If you do '
      'not agree, please do not use the app.',
  sections: [
    LegalSection(
      'Using Vaultix',
      'Vaultix is provided for your personal use to store and manage your own '
          'credentials. You agree to use it lawfully and only for information '
          'you have the right to store.',
    ),
    LegalSection(
      'Your responsibilities',
      'You are responsible for remembering your master password and any '
          'backup password, for keeping backups of data you cannot afford to '
          'lose, and for keeping your device secure and up to date.\n\n'
          'Vaultix cannot recover a forgotten master password or backup '
          'password. If you lose them, the data protected by them is '
          'permanently inaccessible.',
    ),
    LegalSection(
      'Security',
      'Vaultix uses well-established cryptography and follows a local-first '
          'design, but no software can be guaranteed to be completely secure. '
          'Your security also depends on your choices: using a strong, unique '
          'master password, protecting your device, and avoiding malware or '
          'modified (rooted) systems.',
    ),
    LegalSection(
      'No warranty',
      'Vaultix is provided "as is" and "as available", without warranties of '
          'any kind, express or implied, including fitness for a particular '
          'purpose and uninterrupted or error-free operation.',
    ),
    LegalSection(
      'Limitation of liability',
      'To the maximum extent permitted by law, the developer is not liable '
          'for any loss of data, loss of access to accounts, or other damages '
          'arising from the use of, or inability to use, Vaultix.',
    ),
    LegalSection(
      'Changes to these terms',
      'These terms may be updated with new versions of the app. Continued use '
          'after an update means you accept the updated terms.',
    ),
    LegalSection(
      'Contact',
      'Developer details are listed in Settings > About. '
          'Publisher: ${AppInfo.developerName}.',
    ),
  ],
);
