import 'package:flutter_test/flutter_test.dart';

import 'package:jobcompass_ui/features/applications/services/application_sort_service.dart';
import 'package:jobcompass_ui/models/application.dart';

void main() {
  const service = ApplicationSortService();

  Application makeApplication({
    required int id,
    required String status,
    required DateTime updatedAt,
    String? externalId,
    String? title,
  }) {
    return Application(
      id: id,
      jobTitle: title ?? 'Job $id',
      jobCompany: 'Company',
      jobUrl: 'https://example.com/jobs/$id',
      jobLocation: 'Berlin',
      jobWorkFormat: 'Remote',
      jobPublishedAt: '2026-07-10T10:00:00Z',
      jobDescription: null,
      jobSource: 'adzuna',
      jobExternalId: externalId ?? '$id',
      status: status,
      createdAt: DateTime.utc(2026, 7, 1),
      updatedAt: updatedAt,
      archivedAt: null,
    );
  }

  test('sorts applications by status priority', () {
    final applications = [
      makeApplication(
        id: 1,
        status: 'offer',
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
      makeApplication(
        id: 2,
        status: 'rejected',
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
      makeApplication(
        id: 3,
        status: 'technical_interview',
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
      makeApplication(
        id: 4,
        status: 'applied',
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
      makeApplication(
        id: 5,
        status: 'interview',
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
      makeApplication(
        id: 6,
        status: 'screening',
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
    ];

    final result = service.sort(applications);

    expect(result.map((application) => application.status), [
      'offer',
      'technical_interview',
      'interview',
      'screening',
      'applied',
      'rejected',
    ]);
  });

  test('sorts same status by updatedAt newest first', () {
    final applications = [
      makeApplication(
        id: 1,
        status: 'screening',
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
      makeApplication(
        id: 2,
        status: 'screening',
        updatedAt: DateTime.utc(2026, 7, 12),
      ),
      makeApplication(
        id: 3,
        status: 'screening',
        updatedAt: DateTime.utc(2026, 7, 11),
      ),
    ];

    final result = service.sort(applications);

    expect(result.map((application) => application.id), [2, 3, 1]);
  });

  test('does not mutate source list', () {
    final first = makeApplication(
      id: 1,
      status: 'offer',
      updatedAt: DateTime.utc(2026, 7, 10),
    );
    final second = makeApplication(
      id: 2,
      status: 'rejected',
      updatedAt: DateTime.utc(2026, 7, 10),
    );

    final applications = [first, second];

    service.sort(applications);

    expect(applications.map((application) => application.id), [1, 2]);
  });

  test('removes duplicate applications for the same vacancy', () {
    final older = makeApplication(
      id: 1,
      status: 'applied',
      updatedAt: DateTime.utc(2026, 7, 10),
      externalId: 'same-job',
      title: 'Senior Quality Engineer',
    );
    final newer = makeApplication(
      id: 2,
      status: 'interview',
      updatedAt: DateTime.utc(2026, 7, 12),
      externalId: 'same-job',
      title: 'Senior Quality Engineer',
    );

    final result = service.sort([older, newer]);

    expect(result, hasLength(1));
    expect(result.single.id, 2);
    expect(result.single.status, 'interview');
  });

  test('removes legacy duplicates with different ids but same fingerprint', () {
    final first = makeApplication(
      id: 1,
      status: 'applied',
      updatedAt: DateTime.utc(2026, 7, 10),
      externalId: '',
      title: 'Senior QA Engineer',
    );
    final second = makeApplication(
      id: 2,
      status: 'offer',
      updatedAt: DateTime.utc(2026, 7, 12),
      externalId: 'legacy-b',
      title: 'Senior QA Engineer',
    );

    final result = service.sort([first, second]);

    expect(result, hasLength(1));
    expect(result.single.id, 2);
  });
}
