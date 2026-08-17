/// Age-based class/course options for the studying occupation path.
class StudyOptions {
  StudyOptions._();

  static int ageFromDateOfBirth(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return 20;
    final now = DateTime.now();
    var age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age -= 1;
    }
    return age;
  }

  static List<String> optionsForAge(int age) {
    if (age < 14) {
      return List.generate(8, (i) => 'Class ${i + 1}');
    }
    if (age <= 17) {
      return const [
        'Class 9',
        'Class 10',
        'Class 11',
        'Class 12',
      ];
    }
    if (age <= 22) {
      return const [
        'BA',
        'BSc',
        'BCom',
        'BTech/BE',
        'Diploma',
        'Other',
      ];
    }
    return const [
      'Postgraduate',
      'Professional course',
      'Other',
    ];
  }

  static List<String> optionsForDateOfBirth(DateTime? dateOfBirth) {
    return optionsForAge(ageFromDateOfBirth(dateOfBirth));
  }
}
