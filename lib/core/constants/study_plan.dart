// English Comment: Study resources (websites + books) and the weekly topic-wise study plan used by the dashboard.

class StudyResource {
  final String name;
  final String? url; // null = a book (shown, but nothing to open)
  final String note;
  const StudyResource(this.name, this.url, this.note);
}

// English Comment: Resource list from the COMPACT IT "Subject Wise Topics" sheet.
const Map<String, StudyResource> studyResources = {
  'examveda': StudyResource('ExamVeda', 'https://www.examveda.com/', 'MCQ practice'),
  'examradar': StudyResource('ExamRadar', 'http://www.examradar.com/', 'MCQ practice'),
  'indiabix': StudyResource('IndiaBix', 'https://www.indiabix.com/', 'MCQ practice'),
  'sanfoundry': StudyResource('Sanfoundry', 'https://www.sanfoundry.com/', 'Topic-wise MCQs'),
  'tutorialspoint': StudyResource('TutorialsPoint', 'https://www.tutorialspoint.com/', 'Concept tutorials'),
  'cse_sc': StudyResource('CSE (sc.edu)', 'https://www.cse.sc.edu/', 'University notes'),
  'stackoverflow': StudyResource('StackOverflow', 'https://www.stackoverflow.com/', 'Q&A'),
  'medium': StudyResource('Medium', 'https://www.medium.com/', 'Articles'),
  'javatpoint': StudyResource('JavaTpoint', 'https://www.javatpoint.com/', 'Concept tutorials'),
  'beginnersbook': StudyResource('BeginnersBook', 'https://www.beginnersbook.com/', 'Concept tutorials'),
  'guru99': StudyResource('Guru99', 'https://www.guru99.com/', 'Concept tutorials'),
  'geeksforgeeks': StudyResource('GeeksforGeeks', 'https://www.geeksforgeeks.org/', 'Concepts + problems'),
  'gateoverflow': StudyResource('GATE Overflow', 'https://gateoverflow.in/', 'Previous questions'),
  'sattacademy': StudyResource('SATT Academy', 'https://sattacademy.com/', 'Practice MCQs'),
  'satt_bb_ict': StudyResource(
    'SATT · BB ICT MCQs',
    'https://sattacademy.com/question-bank/বাংলাদেশ-ব্যাংক/তথ্য-ও-যোগাযোগ-প্রযুক্তি/mcq',
    'Bangladesh Bank ICT MCQs',
  ),
  'book_ds': StudyResource('Data Structure – Dr. Rafiqul Islam', null, 'Book'),
  'book_digital': StudyResource('Digital Logic and Computer Design – Morris Mano', null, 'Book'),
};

// English Comment: Which resources help with which topic (keys of studyResources).
const Map<String, List<String>> topicResources = {
  'C Programming': ['sanfoundry', 'tutorialspoint', 'geeksforgeeks', 'guru99', 'indiabix'],
  'Data Structure & Algorithm': ['sanfoundry', 'geeksforgeeks', 'gateoverflow', 'tutorialspoint', 'book_ds'],
  'Discrete Mathematics': ['geeksforgeeks', 'gateoverflow', 'tutorialspoint'],
  'Database Management System': ['sanfoundry', 'examveda', 'guru99', 'tutorialspoint', 'gateoverflow'],
  'Object Oriented Programming': ['sanfoundry', 'javatpoint', 'beginnersbook', 'guru99', 'geeksforgeeks'],
  'Software Engineering': ['sanfoundry', 'tutorialspoint', 'geeksforgeeks', 'javatpoint', 'examveda'],
  'Computer Networking': ['sanfoundry', 'tutorialspoint', 'geeksforgeeks', 'indiabix'],
  'Data Communication': ['sanfoundry', 'tutorialspoint', 'examveda'],
  'Cyber Security': ['sanfoundry', 'tutorialspoint', 'geeksforgeeks', 'medium'],
  'Operating System': ['sanfoundry', 'geeksforgeeks', 'gateoverflow', 'guru99'],
  'Computer Architecture & Microprocessor': ['sanfoundry', 'gateoverflow', 'geeksforgeeks'],
  'Compiler Design': ['sanfoundry', 'geeksforgeeks', 'tutorialspoint', 'gateoverflow'],
  'Digital Electronics': ['sanfoundry', 'tutorialspoint', 'book_digital'],
  'Circuit Analysis': ['sanfoundry', 'tutorialspoint'],
  'Computer Fundamentals': ['sanfoundry', 'indiabix', 'examveda', 'examradar'],
  'Artificial Intelligence': ['sanfoundry', 'geeksforgeeks', 'tutorialspoint', 'medium'],
  'Internet of Things (IoT)': ['sanfoundry', 'tutorialspoint', 'geeksforgeeks', 'medium'],
  'Data Center': ['geeksforgeeks', 'medium', 'tutorialspoint'],
  'ICT in Banking Sector': ['examveda', 'examradar', 'indiabix'],
  'Weekly Revision': ['sattacademy', 'examveda', 'indiabix', 'sanfoundry'],
  'Previous Year Questions': ['sattacademy', 'examradar', 'examveda', 'gateoverflow'],
  // General topics (SATT Academy pages, checked on the live site)
  'Bangla': ['sattacademy'],
  'English': ['sattacademy'],
  'Mathematics': ['sattacademy'],
  'General Knowledge': ['sattacademy'],
  'Current Affairs': ['sattacademy'],
  'Mental Ability': ['sattacademy'],
};

// English Comment: DateTime.weekday numbers (Mon=1 ... Sun=7) -> topics of that day.
// The week runs Saturday to Friday. Friday is revision + previous year questions.
const Map<int, List<String>> weeklyPlan = {
  6: ['C Programming', 'Data Structure & Algorithm', 'Discrete Mathematics'], // Saturday
  7: ['Database Management System', 'Object Oriented Programming', 'Software Engineering'], // Sunday
  1: ['Computer Networking', 'Data Communication', 'Cyber Security'], // Monday
  2: ['Operating System', 'Computer Architecture & Microprocessor', 'Compiler Design'], // Tuesday
  3: ['Digital Electronics', 'Circuit Analysis', 'Computer Fundamentals'], // Wednesday
  4: ['Artificial Intelligence', 'Internet of Things (IoT)', 'Data Center', 'ICT in Banking Sector'], // Thursday
  5: ['Weekly Revision', 'Previous Year Questions'], // Friday
};

// English Comment: Display order of the week and day names.
const List<int> weekOrder = [6, 7, 1, 2, 3, 4, 5];
const Map<int, String> weekdayNames = {
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
  7: 'Sunday',
};

// English Comment: Direct pages for a topic on a site (checked against the live sites). Where a topic has no
// entry here, linkFor() opens the site's home page (never a search).
const Map<String, Map<String, String>> topicDeepLinks = {
  'C Programming': {
    'indiabix': 'https://www.indiabix.com/c-programming/questions-and-answers/',
    'examveda': 'https://www.examveda.com/mcq-question-on-c-program/',
    'geeksforgeeks': 'https://www.geeksforgeeks.org/c/c-programming-language/',
    'tutorialspoint': 'https://www.tutorialspoint.com/cprogramming/index.htm',
  },
  'Data Structure & Algorithm': {
    'geeksforgeeks': 'https://www.geeksforgeeks.org/dsa/dsa-tutorial-learn-data-structures-and-algorithms/',
    'tutorialspoint': 'https://www.tutorialspoint.com/data_structures_algorithms/index.htm',
  },
  'Discrete Mathematics': {
    'geeksforgeeks': 'https://www.geeksforgeeks.org/engineering-mathematics/discrete-mathematics-tutorial/',
  },
  'Database Management System': {
    'indiabix': 'https://www.indiabix.com/database/questions-and-answers/',
    'examveda': 'https://www.examveda.com/mcq-question-on-database/',
    'geeksforgeeks': 'https://www.geeksforgeeks.org/dbms/',
    'tutorialspoint': 'https://www.tutorialspoint.com/dbms/index.htm',
  },
  'Object Oriented Programming': {
    'geeksforgeeks': 'https://www.geeksforgeeks.org/java/object-oriented-programming-oops-concept-in-java/',
  },
  'Software Engineering': {
    'geeksforgeeks': 'https://www.geeksforgeeks.org/software-engineering/',
    'tutorialspoint': 'https://www.tutorialspoint.com/software_engineering/index.htm',
  },
  'Computer Networking': {
    'indiabix': 'https://www.indiabix.com/networking/questions-and-answers/',
    'examveda': 'https://www.examveda.com/mcq-question-on-networking/',
  },
  'Operating System': {
    'geeksforgeeks': 'https://www.geeksforgeeks.org/operating-systems/',
    'tutorialspoint': 'https://www.tutorialspoint.com/operating_system/index.htm',
  },
  'Computer Architecture & Microprocessor': {
    'geeksforgeeks': 'https://www.geeksforgeeks.org/computer-organization-and-architecture-tutorials/',
    'tutorialspoint': 'https://www.tutorialspoint.com/computer_logical_organization/index.htm',
  },
  'Compiler Design': {
    'geeksforgeeks': 'https://www.geeksforgeeks.org/compiler-design/',
    'tutorialspoint': 'https://www.tutorialspoint.com/compiler_design/index.htm',
  },
  'Digital Electronics': {
    'indiabix': 'https://www.indiabix.com/digital-electronics/questions-and-answers/',
    'geeksforgeeks': 'https://www.geeksforgeeks.org/digital-electronics-logic-design-tutorials/',
  },
  'Circuit Analysis': {
    'indiabix': 'https://www.indiabix.com/electronics/questions-and-answers/',
  },
  'Computer Fundamentals': {
    'examveda': 'https://www.examveda.com/mcq-question-on-computer-fundamentals/',
    'tutorialspoint': 'https://www.tutorialspoint.com/computer_concepts/index.htm',
  },
  'Artificial Intelligence': {
    'examveda': 'https://www.examveda.com/computer-science/practice-mcq-question-on-artificial-intelligence/',
    'geeksforgeeks': 'https://www.geeksforgeeks.org/artificial-intelligence/',
    'tutorialspoint': 'https://www.tutorialspoint.com/artificial_intelligence/index.htm',
  },
  'Bangla': {'sattacademy': 'https://sattacademy.com/all-mcq/বাংলা'},
  'English': {'sattacademy': 'https://sattacademy.com/all-mcq/english'},
  'Mathematics': {'sattacademy': 'https://sattacademy.com/all-mcq/গণিত'},
  'General Knowledge': {'sattacademy': 'https://sattacademy.com/all-mcq/সাধারণ-জ্ঞান'},
  'Current Affairs': {'sattacademy': 'https://sattacademy.com/gk'},
  'Mental Ability': {'sattacademy': 'https://sattacademy.com/all-mcq/মানসিক-দক্ষতা'},
  'Internet of Things (IoT)': {
    'examveda': 'https://www.examveda.com/computer-science/practice-mcq-question-on-internet-of-things-(iot)/',
    'tutorialspoint': 'https://www.tutorialspoint.com/internet_of_things/index.htm',
  },
};

// English Comment: Sanfoundry MCQ index page of each topic (found on the live site).
const Map<String, String> _sanfoundryPages = {
  'C Programming': 'https://www.sanfoundry.com/c-interview-questions-answers/',
  'Data Structure & Algorithm': 'https://www.sanfoundry.com/1000-data-structure-questions-answers/',
  'Database Management System': 'https://www.sanfoundry.com/1000-database-management-system-questions-answers/',
  'Computer Networking': 'https://www.sanfoundry.com/computer-network-questions-answers/',
  'Data Communication': 'https://www.sanfoundry.com/1000-digital-communications-questions-answers/',
  'Operating System': 'https://www.sanfoundry.com/operating-system-questions-answers/',
  'Computer Architecture & Microprocessor': 'https://www.sanfoundry.com/1000-computer-organization-architecture-questions-answers/',
  'Digital Electronics': 'https://www.sanfoundry.com/1000-digital-circuits-questions-answers/',
  'Circuit Analysis': 'https://www.sanfoundry.com/1000-basic-electrical-engineering-questions-answers/',
  'Computer Fundamentals': 'https://www.sanfoundry.com/1000-computer-fundamentals-questions-answers/',
  'Software Engineering': 'https://www.sanfoundry.com/software-engineering-questions-answers/',
  'Compiler Design': 'https://www.sanfoundry.com/1000-compilers-questions-answers/',
  'Cyber Security': 'https://www.sanfoundry.com/1000-cyber-security-questions-answers/',
  'Artificial Intelligence': 'https://www.sanfoundry.com/artificial-intelligence-questions-answers/',
  'Internet of Things (IoT)': 'https://www.sanfoundry.com/1000-iot-questions-answers/',
  'Object Oriented Programming': 'https://www.sanfoundry.com/1000-object-oriented-programming-oops-questions-answers/',
};

class ResolvedLink {
  final String url;
  final bool isSearch; // always false now: only direct pages are linked
  const ResolvedLink(this.url, this.isSearch);
}

// English Comment: The direct page for (topic, site), or null when there is no verified page. Nothing falls back to
// a search any more: a topic simply shows only the links that open a real page.
// Revision days have no single topic, so they open the site's home page.
ResolvedLink? linkFor(String topic, String sourceKey) {
  final res = studyResources[sourceKey];
  final siteUrl = res?.url;
  if (res == null || siteUrl == null) return null;

  if (sourceKey == 'satt_bb_ict') return ResolvedLink(siteUrl, false);

  if (sourceKey == 'sanfoundry') {
    final page = _sanfoundryPages[topic];
    if (page != null) return ResolvedLink(page, false);
  }

  final direct = topicDeepLinks[topic]?[sourceKey];
  if (direct != null) return ResolvedLink(direct, false);

  // SATT has no page for this topic: open its job question bank.
  if (sourceKey == 'sattacademy') return const ResolvedLink('https://sattacademy.com/question-bank', false);

  // No verified topic page: open the site's home page (never a search), so the link is still there under "more".
  return ResolvedLink(siteUrl, false);
}

// True when the link opens a real page for this topic, false when it only opens the site's home page.
bool hasTopicPage(String topic, String sourceKey) {
  if (sourceKey == 'satt_bb_ict') return true;
  if (sourceKey == 'sanfoundry' && _sanfoundryPages[topic] != null) return true;
  return topicDeepLinks[topic]?[sourceKey] != null;
}

const Set<String> _nonItTopics = {
  'Bangla',
  'English',
  'Mathematics',
  'General Knowledge',
  'Current Affairs',
  'Mental Ability',
  'Weekly Revision',
  'Previous Year Questions',
};

// English Comment: Resources shown for a topic. IT topics get the Bangladesh Bank ICT MCQ page first (real practice),
// topics the user typed in themselves get SATT's job question bank.
List<String> resourcesForTopic(String topic) {
  final base = topicResources[topic];
  if (base == null) return const ['sattacademy'];
  final withPractice = _nonItTopics.contains(topic) ? base : ['satt_bb_ict', ...base];
  return [
    for (final key in withPractice)
      if (studyResources[key] != null) key,
  ];
}

// English Comment: Ready-made weekly plans for different target exams. Each day is Saturday..Friday by DateTime.weekday.
class StudyPreset {
  final String id;
  final String name;
  final String description;
  final Map<int, List<String>> days;
  const StudyPreset(this.id, this.name, this.description, this.days);
}

const String defaultPresetId = 'it_full';
const String customPresetId = 'custom';

const List<StudyPreset> studyPresets = [
  StudyPreset('it_full', 'IT Officer · all IT subjects', 'Covers all 19 IT subjects through the week.', weeklyPlan),
  StudyPreset('bank_it', 'Bank IT Officer · IT + General', 'Core IT subjects mixed with Bangla, English, Math and GK.', {
    6: ['C Programming', 'Data Structure & Algorithm', 'Mathematics'],
    7: ['Database Management System', 'Object Oriented Programming', 'English'],
    1: ['Computer Networking', 'Data Communication', 'Bangla'],
    2: ['Operating System', 'Computer Architecture & Microprocessor', 'General Knowledge'],
    3: ['Software Engineering', 'Cyber Security', 'Mental Ability'],
    4: ['Digital Electronics', 'Computer Fundamentals', 'Current Affairs', 'ICT in Banking Sector'],
    5: ['Weekly Revision', 'Previous Year Questions'],
  }),
  StudyPreset('ntrca_ict', 'NTRCA · ICT Lecturer', 'General (Bangla, English, Math, GK) twice a week plus ICT subjects.', {
    6: ['Bangla', 'English', 'Digital Electronics'],
    7: ['Mathematics', 'General Knowledge', 'C Programming'],
    1: ['Bangla', 'English', 'Database Management System'],
    2: ['Mathematics', 'General Knowledge', 'Computer Networking'],
    3: ['Current Affairs', 'Data Communication', 'Computer Fundamentals'],
    4: ['English', 'Mathematics', 'Object Oriented Programming'],
    5: ['Weekly Revision', 'Previous Year Questions'],
  }),
  StudyPreset('general_job', 'General Job · Bangla, English, Math, GK', 'For exams with only general subjects.', {
    6: ['Bangla', 'Mathematics'],
    7: ['English', 'General Knowledge'],
    1: ['Mathematics', 'Mental Ability'],
    2: ['Bangla', 'Current Affairs'],
    3: ['English', 'General Knowledge'],
    4: ['Computer Fundamentals', 'Mental Ability', 'Current Affairs'],
    5: ['Weekly Revision', 'Previous Year Questions'],
  }),
];

StudyPreset presetById(String id) =>
    studyPresets.firstWhere((p) => p.id == id, orElse: () => studyPresets.first);