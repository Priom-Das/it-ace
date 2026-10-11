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
  'book_ds': StudyResource('Data Structure – Dr. Rafiqul Islam', null, 'Book'),
  'book_digital': StudyResource('Digital Logic and Computer Design – Morris Mano', null, 'Book'),
};

// English Comment: Which resources help with which topic (keys of studyResources).
const Map<String, List<String>> topicResources = {
  'C Programming': ['sanfoundry', 'tutorialspoint', 'geeksforgeeks', 'guru99', 'indiabix'],
  'Data Structure & Algorithm': ['sanfoundry', 'geeksforgeeks', 'gateoverflow', 'tutorialspoint', 'book_ds'],
  'Discrete Mathematics': ['geeksforgeeks', 'gateoverflow', 'tutorialspoint'],
  'Database Management System': ['sanfoundry', 'examveda', 'guru99', 'tutorialspoint', 'gateoverflow'],
  'Object Oriented Programming': ['javatpoint', 'beginnersbook', 'guru99', 'geeksforgeeks'],
  'Software Engineering': ['tutorialspoint', 'geeksforgeeks', 'javatpoint', 'examveda'],
  'Computer Networking': ['sanfoundry', 'tutorialspoint', 'geeksforgeeks', 'indiabix'],
  'Data Communication': ['sanfoundry', 'tutorialspoint', 'examveda'],
  'Cyber Security': ['tutorialspoint', 'geeksforgeeks', 'medium'],
  'Operating System': ['sanfoundry', 'geeksforgeeks', 'gateoverflow', 'guru99'],
  'Computer Architecture & Microprocessor': ['sanfoundry', 'gateoverflow', 'geeksforgeeks'],
  'Compiler Design': ['geeksforgeeks', 'tutorialspoint', 'gateoverflow'],
  'Digital Electronics': ['sanfoundry', 'tutorialspoint', 'book_digital'],
  'Circuit Analysis': ['sanfoundry', 'tutorialspoint'],
  'Computer Fundamentals': ['indiabix', 'examveda', 'examradar', 'sanfoundry'],
  'Artificial Intelligence': ['geeksforgeeks', 'tutorialspoint', 'medium'],
  'Internet of Things (IoT)': ['tutorialspoint', 'geeksforgeeks', 'medium'],
  'Data Center': ['geeksforgeeks', 'medium', 'tutorialspoint'],
  'ICT in Banking Sector': ['examveda', 'examradar', 'indiabix'],
  'Weekly Revision': ['examveda', 'indiabix', 'sanfoundry'],
  'Previous Year Questions': ['examradar', 'examveda', 'gateoverflow'],
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
// entry here, linkFor() falls back to a Google search limited to that site, so the link still lands on the topic.
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
  'Internet of Things (IoT)': {
    'examveda': 'https://www.examveda.com/computer-science/practice-mcq-question-on-internet-of-things-(iot)/',
    'tutorialspoint': 'https://www.tutorialspoint.com/internet_of_things/index.htm',
  },
};

// Sites where a search should ask for MCQs.
const Set<String> _mcqSites = {'examveda', 'examradar', 'indiabix', 'sanfoundry'};

class ResolvedLink {
  final String url;
  final bool isSearch; // true = Google search limited to the site, not a direct page
  const ResolvedLink(this.url, this.isSearch);
}

// English Comment: The best link for (topic, site): a direct page when known, else a site-limited search for the topic.
// Revision days have no single topic, so they open the site's home page.
ResolvedLink? linkFor(String topic, String sourceKey) {
  final res = studyResources[sourceKey];
  final siteUrl = res?.url;
  if (res == null || siteUrl == null) return null;

  final direct = topicDeepLinks[topic]?[sourceKey];
  if (direct != null) return ResolvedLink(direct, false);

  if (topic == 'Weekly Revision' || topic == 'Previous Year Questions') {
    return ResolvedLink(siteUrl, false);
  }
  final host = Uri.parse(siteUrl).host.replaceFirst('www.', '');
  final query = 'site:$host $topic${_mcqSites.contains(sourceKey) ? ' MCQ' : ''}';
  return ResolvedLink('https://www.google.com/search?q=${Uri.encodeQueryComponent(query)}', true);
}