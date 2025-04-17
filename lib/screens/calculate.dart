int calculateMatchScore({
  required List<String> jobTechSkills,
  required List<String> jobSoftSkills,
  required List<String> userTechSkills,
  required List<String> userSoftSkills,
  required List<String> userLanguages,
  required List<String> userWorkExperience,
  required List<String> userQualifications,
  required String jobExperience,
  required String jobQualification,
}) {
  int score = 0;

  // Match technical skills
  for (var skill in userTechSkills) {
    if (jobTechSkills.contains(skill.toLowerCase())) score += 20;
  }
  // Match soft skills
  for (var skill in userSoftSkills) {
    if (jobSoftSkills.contains(skill.toLowerCase())) score += 15;
  }
  // Match languages (if present in job description or as a requirement)
  for (var lang in userLanguages) {
    if (jobTechSkills.contains(lang.toLowerCase()) ||
        jobSoftSkills.contains(lang.toLowerCase())) {
      score += 10;
    }
  }
  // Match work experience
  for (var exp in userWorkExperience) {
    if (jobExperience.toLowerCase().contains(exp.toLowerCase())) score += 25;
  }
  // Match qualifications
  for (var qual in userQualifications) {
    if (jobQualification.toLowerCase().contains(qual.toLowerCase()))
      score += 30;
  }

  return score;
}
