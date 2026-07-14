import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../features/job/services/job_details_api.dart';
import '../models/job.dart';

final jobDetailsApiProvider = Provider<JobDetailsApi>(
  (ref) => JobDetailsApi(ApiClient.dio),
);

final jobMatchProvider = FutureProvider.autoDispose.family<int, Job>((
  ref,
  job,
) async {
  final api = ref.read(jobDetailsApiProvider);
  return api.fetchMatch(job);
});
