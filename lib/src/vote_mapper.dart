import 'dart:math';

import 'package:scot_api/scot_api.dart';

class VoteMapper {
  VoteMapper(this.post, this.tokenInfo);

  final TokenInfo tokenInfo;
  final PostInfo post;

  Map<String, double> getUpvotes() {
    final upvotes = _getUpvotes();
    return _getVoteValues(upvotes);
  }

  Map<String, double> getDownvotes() {
    final downvotes = _getDownvotes();
    return _getVoteValues(downvotes);
  }

  List<ActiveVote> _getUpvotes() =>
      post.activeVotes.where((v) => v.percent >= 0).toList();

  List<ActiveVote> _getDownvotes() =>
      post.activeVotes.where((v) => v.percent < 0).toList();

  // Previous version of this function was doing unnecessary calculations.
  // To put simply, without adding curve detail, it was doing this to get
  // rshares of single vote: total rshares + rshares of vote - total rshares.
  // That's no different than just using rshares of vote, so I used that
  // instead.
  //
  // Other than that, there were a calculation made if total rshare count
  // was 0, but that's simply impossible to happen as that means no votes,
  // which would not just dry run our iterator, is also would return early
  // before that happening due to votes.isEmpty check. So that also got
  // removed.
  Map<String, double> _getVoteValues(List<ActiveVote> votes) {
    if (votes.isEmpty) {
      return {};
    }

    final denom = pow(10, post.precision);
    final rewardData = _buildRewardData(post, tokenInfo);

    final simpleVotes = <String, double>{};

    for (final vote in votes) {
      // rshares = vote value * denom
      // we apply the curve to it and later divide by denom to get vote value
      // so, rshares / denom = vote value
      simpleVotes[vote.voter] =
          _applyRewardsCurve(vote.rshares, rewardData) / denom;
    }

    return simpleVotes;
  }

  num _applyRewardsCurve(num r, _RewardData rewardData) =>
      (pow(max(0, r), rewardData.authorCurveExponent) * rewardData.rewardPool) /
      rewardData.pendingRshares;

  _RewardData _buildRewardData(PostInfo post, TokenInfo tokenInfo) =>
      _RewardData(
        authorCurveExponent: post.authorCurveExponent,
        rewardPool: tokenInfo.rewardPool,
        pendingRshares: tokenInfo.pendingRshares,
      );
}

class _RewardData {
  const _RewardData({
    required this.authorCurveExponent,
    required this.rewardPool,
    required this.pendingRshares,
  });

  final num authorCurveExponent;
  final num rewardPool;
  final num pendingRshares;
}
