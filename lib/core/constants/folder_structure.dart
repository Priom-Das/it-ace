// English Comment: Folder Tree Structure representation with Guideline folder and comprehensive IT subfolders.
final Map<String, List<String>> folderStructure = {
  'Guideline': [],
  'IT': [
    'Artificial Intelligence',
    'C Programming',
    'Data Communication',
    'Database Management System',
    'Digital Electronics',
    'Object Oriented Programming',
    'Operating System',
    'Software Engineering',
    'Computer Fundamentals',
    'Data Structure & Algorithm',
    'Computer Networking',
    'Computer Architecture & Microprocessor',
    'Discrete Mathematics',
    'Cyber Security',
    'Compiler Design',
    'Internet of Things (IoT)',
    'Data Center',
    'Circuit Analysis',
    'ICT in Banking Sector',
  ],
  'BANGLA': ['Literature', 'Grammar'],
  'ENGLISH': ['Literature', 'Grammar'],
  'GENERAL KNOWLEDGE': ['Bangladesh', 'International'],
  'MATHEMATICS': [],
  'ANALYTICAL ANALYSIS': [],
  'FOCUS WRITING': [],
  'PREVIOUS YEAR QUESTIONS': ['General', 'IT'],
};

// English Comment: Bangla, English and General Knowledge have sub folders with the same names (e.g. Literature,
// Grammar). In the database (lecture_materials.subject) these are stored as "<Folder> <Sub folder>",
// like "Bangla Literature", so the two Literature folders never get mixed up.
const Set<String> _prefixedParentFolders = {'BANGLA', 'ENGLISH', 'GENERAL KNOWLEDGE'};

String lectureSubjectKey(String parentFolder, String subFolder) {
  return _prefixedParentFolders.contains(parentFolder.toUpperCase())
      ? '$parentFolder $subFolder'
      : subFolder;
}

bool hasPrefixedSubfolders(String parentFolder) =>
    _prefixedParentFolders.contains(parentFolder.toUpperCase());

// English Comment: Folder names of a storage link, without the file name.
// ".../object/public/materials/Bangla/Literature/a.pdf" -> [Bangla, Literature]
List<String> storageFolders(String? url) {
  if (url == null) return const [];
  const marker = '/object/public/materials/';
  final start = url.indexOf(marker);
  if (start < 0) return const [];
  final parts = url.substring(start + marker.length).split('?').first.split('/');
  if (parts.length < 2) return const [];
  try {
    return parts.sublist(0, parts.length - 1).map(Uri.decodeComponent).toList();
  } catch (_) {
    return const [];
  }
}

// English Comment: True when a lecture row belongs to this sub folder. The folder the file is really stored in
// (from its PDF link) wins, so a file in Bangla/Literature shows under Literature even if its "subject"
// column only says "Bangla". Rows without a usable link fall back to the subject text.
bool lectureInSubFolder(Map<String, dynamic> row, String parentFolder, String subFolder) {
  final folders = storageFolders(row['pdf_url'] as String?);
  if (folders.length >= 2 && folders[0].toLowerCase() == parentFolder.toLowerCase()) {
    return folders[1].toLowerCase() == subFolder.toLowerCase();
  }
  final subject = (row['subject'] ?? '').toString().trim().toLowerCase();
  return subject == lectureSubjectKey(parentFolder, subFolder).toLowerCase();
}

// English Comment: False when the file is stored inside one of the parent's sub folders.
bool lectureDirectlyInParent(Map<String, dynamic> row, String parentFolder) {
  final folders = storageFolders(row['pdf_url'] as String?);
  return !(folders.length >= 2 && folders[0].toLowerCase() == parentFolder.toLowerCase());
}
