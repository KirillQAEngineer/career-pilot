import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/models/profile.dart';

void main() {
  test('formats comma-separated profile lists for display', () {
    final profile = Profile.fromJson({
      'id': 1,
      'profession': 'QA Engineer',
      'level': 'Middle',
      'skills': 'Testing,REST API, Manual Testing',
      'technologies': 'Postman,Selenium,  Docker',
      'english_level': 'B2',
      'preferred_roles': 'QA Engineer,AQA',
      'resume_text': '',
    });

    expect(profile.skills, 'Testing, REST API, Manual Testing');
    expect(profile.technologies, 'Postman, Selenium, Docker');
    expect(profile.preferredRoles, 'QA Engineer, AQA');
  });
}
