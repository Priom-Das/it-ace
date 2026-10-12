// English Comment: Dashboard card for bank job practice using SATT Academy's bank question banks.
// Every link is a direct page that was checked on the live site.
import 'package:flutter/material.dart';

import '../../core/utils/open_link.dart';

class _Link {
  final String label;
  final String url;
  final IconData icon;
  const _Link(this.label, this.url, this.icon);
}

const String _bb = 'https://sattacademy.com/question-bank/বাংলাদেশ-ব্যাংক';

// Bangladesh Bank, by subject. ICT is first because it matters most for IT officer posts.
const List<_Link> _bbSubjects = [
  _Link('ICT', '$_bb/তথ্য-ও-যোগাযোগ-প্রযুক্তি/mcq', Icons.computer_outlined),
  _Link('Math', '$_bb/গণিত/mcq', Icons.calculate_outlined),
  _Link('English', '$_bb/english/mcq', Icons.translate),
  _Link('Bangla', '$_bb/বাংলা/mcq', Icons.menu_book_outlined),
  _Link('GK', '$_bb/সাধারণ-জ্ঞান/mcq', Icons.public),
  _Link('Mental Ability', '$_bb/মানসিক-দক্ষতা/mcq', Icons.psychology_outlined),
];

const List<_Link> _otherBanks = [
  _Link('Sonali Bank', 'https://sattacademy.com/question-bank/সোনালী-ব্যাংক-পিএলসি/mcq', Icons.account_balance_outlined),
  _Link('Janata Bank', 'https://sattacademy.com/question-bank/জনতা-ব্যাংক-পিএলসি/mcq', Icons.account_balance_outlined),
  _Link('Agrani Bank', 'https://sattacademy.com/question-bank/অগ্রণী-ব্যাংক-পিএলসি/mcq', Icons.account_balance_outlined),
  _Link('Rupali Bank', 'https://sattacademy.com/question-bank/রূপালী-ব্যাংক-পিএলসি/mcq', Icons.account_balance_outlined),
];

class BankPracticeCard extends StatelessWidget {
  const BankPracticeCard({super.key});

  static const Color _purple = Color(0xFF6B4EE6);

  Widget _chips(BuildContext context, List<_Link> links) {
    return Wrap(
      spacing: 6,
      children: [
        for (final l in links)
          ActionChip(
            avatar: Icon(l.icon, size: 18),
            label: Text(l.label, style: const TextStyle(fontSize: 13)),
            backgroundColor: Colors.white,
            onPressed: () => openLink(context, l.url),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final heading = TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]);
    return Card(
      elevation: 0,
      color: const Color(0xFFF3EEFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, color: _purple),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Bank Job Practice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Bank recruitment MCQs with answers and explanations (SATT Academy).',
              style: TextStyle(color: Colors.grey[800], fontSize: 13),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => openLink(context, '$_bb/mcq'),
              icon: const Icon(Icons.quiz_outlined, size: 18),
              label: const Text('Bangladesh Bank · all MCQs'),
            ),
            const SizedBox(height: 12),
            Text('Bangladesh Bank by subject', style: heading),
            const SizedBox(height: 4),
            _chips(context, _bbSubjects),
            const SizedBox(height: 12),
            Text('Other banks', style: heading),
            const SizedBox(height: 4),
            _chips(context, _otherBanks),
          ],
        ),
      ),
    );
  }
}