import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/presentation/state/language_provider.dart';
import 'package:shoply/core/localization/localization_helper.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _selectedLanguage = 'de';

  final List<Map<String, String>> _languages = [
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = ref.read(languageProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('language')),
      ),
      body: ListView.builder(
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final language = _languages[index];
          final isSelected = _selectedLanguage == language['code'];

          return RadioListTile<String>(
            title: Row(
              children: [
                Text(language['flag']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Text(language['name']!),
              ],
            ),
            value: language['code']!,
            groupValue: _selectedLanguage,
            onChanged: (value) async {
              setState(() => _selectedLanguage = value!);
              await ref.read(languageProvider.notifier).setLanguage(value!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sprache auf ${language['name']} geändert')),
                );
              }
            },
            activeColor: Colors.blue,
          );
        },
      ),
    );
  }
}
