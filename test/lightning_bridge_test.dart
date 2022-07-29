// ignore_for_file: prefer_const_constructors
import 'package:lightning_bridge/lightning_bridge.dart';
import 'package:scot_api/scot_api.dart';
import 'package:test/test.dart';

import 'samples/samples.dart';

void main() {
  group('VoteMapper', () {
    late VoteMapper voteMapper;
    late PostInfo postInfo;

    setUp(() async {
      postInfo = await sampleScotPostInfo();
      voteMapper = VoteMapper(postInfo, await sampleTokenInfo());
    });

    group('getUpvotes', () {
      test('returns proper number of upvoters', () async {
        final actual = voteMapper.getUpvotes();
        expect(actual, hasLength(159));
      });

      test('votes have real numbers', () async {
        final actual = voteMapper.getUpvotes();
        expect(actual, isNot(containsValue('NaN')));
      });

      test('success when no upvotes', () async {
        final noActiveVotesPostInfo = await sampleScotPostInfoNoActiveVotes();
        final myVoteMapper =
            VoteMapper(noActiveVotesPostInfo, await sampleTokenInfo());

        final actual = myVoteMapper.getUpvotes();
        expect(actual, hasLength(0));
      });
    });
    group('getDownvotes', () {
      test('returns proper number of downvoters', () async {
        final actual = voteMapper.getDownvotes();
        expect(actual, hasLength(1));
      });

      test('votes have real numbers', () async {
        final actual = voteMapper.getDownvotes();
        expect(actual, isNot(containsValue('NaN')));
      });
    });
  });
}
