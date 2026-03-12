/// Calculate age in years from [dateOfBirth] to [today] (defaults to now).
int calculateAge(DateTime dateOfBirth, [DateTime? today]) {
  final now = today ?? DateTime.now();
  var age = now.year - dateOfBirth.year;
  if (now.month < dateOfBirth.month ||
      (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
    age--;
  }
  return age;
}
