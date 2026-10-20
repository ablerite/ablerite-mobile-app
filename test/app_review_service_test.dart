import 'package:ableritemobile/services/app_review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeReviewRequester implements AppReviewRequester {
  _FakeReviewRequester({this.available = true});

  bool available;
  int requestCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async {
    requestCount += 1;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppReviewService serviceFor(_FakeReviewRequester requester) {
    return AppReviewService(
      campaignId: '1.0.2',
      requester: requester,
      isSupportedPlatform: () => true,
      promptDelay: Duration.zero,
    );
  }

  test('requests once on the second eligible app session', () async {
    final requester = _FakeReviewRequester();

    expect(
      await serviceFor(requester).registerEligibleSessionAndMaybeRequest(),
      isFalse,
    );
    expect(requester.requestCount, 0);

    expect(
      await serviceFor(requester).registerEligibleSessionAndMaybeRequest(),
      isTrue,
    );
    expect(requester.requestCount, 1);

    expect(
      await serviceFor(requester).registerEligibleSessionAndMaybeRequest(),
      isFalse,
    );
    expect(requester.requestCount, 1);
  });

  test('does not count the same running app session twice', () async {
    final requester = _FakeReviewRequester();
    final service = serviceFor(requester);

    expect(await service.registerEligibleSessionAndMaybeRequest(), isFalse);
    expect(await service.registerEligibleSessionAndMaybeRequest(), isFalse);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('app_review.1.0.2.eligible_sessions'), 1);
  });

  test(
    'retries in a later session when the native prompt is unavailable',
    () async {
      final requester = _FakeReviewRequester(available: false);

      await serviceFor(requester).registerEligibleSessionAndMaybeRequest();
      expect(
        await serviceFor(requester).registerEligibleSessionAndMaybeRequest(),
        isFalse,
      );

      requester.available = true;
      expect(
        await serviceFor(requester).registerEligibleSessionAndMaybeRequest(),
        isTrue,
      );
      expect(requester.requestCount, 1);
    },
  );
}
