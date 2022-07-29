import 'dart:convert';

import 'package:hive_api/hive_api.dart' as hive_api;
import 'package:lightning_api/lightning_api.dart';
import 'package:lightning_bridge/lightning_bridge.dart';
import 'package:scot_api/scot_api.dart' as scot_api;

Account buildAccount(
  hive_api.Account hiveAccount,
  scot_api.Account tribeAccount,
) {
  return Account(
    id: hiveAccount.id,
    name: hiveAccount.name,
    reputation: hiveAccount.reputation,
    profile: _parseProfileFromMetadata(hiveAccount.postingJsonMetadata),
    jsonMetadata: hiveAccount.jsonMetadata,
    postingJsonMetadata: hiveAccount.postingJsonMetadata,
    lastOwnerUpdate: hiveAccount.lastAccountUpdate,
    lastAccountUpdate: hiveAccount.lastAccountUpdate,
    created: hiveAccount.created,
    postCount: hiveAccount.postCount,
    canVote: hiveAccount.canVote,
    upvoteManabar: _convertHiveManabar(hiveAccount.votingManabar),
    downvoteManabar: _convertHiveManabar(hiveAccount.downvoteManabar),
    votingPower: hiveAccount.votingPower,
    balance: _fromHive(hiveAccount.balance),
    savingsBalance: _fromHive(hiveAccount.savingsBalance),
    hbdBalance: _fromHbd(hiveAccount.hbdBalance),
    hbdLastUpdate: hiveAccount.hbdSecondsLastUpdate,
    hbdLastInterestPayment: hiveAccount.hbdLastInterestPayment,
    savingsHbdBalance: _fromHbd(hiveAccount.savingsHbdBalance),
    savingsHbdLastUpdate: hiveAccount.savingsHbdSecondsLastUpdate,
    savingsHbdLastInterestPayment: hiveAccount.savingsHbdLastInterestPayment,
    savingsWithdrawRequests: hiveAccount.savingsWithdrawRequests,
    rewardHbdBalance: _fromHbd(hiveAccount.rewardHbdBalance),
    rewardHiveBalance: _fromHive(hiveAccount.rewardHiveBalance),
    rewardVestingBalance: _fromVests(hiveAccount.rewardVestingBalance),
    rewardVestingHive: _fromHive(hiveAccount.rewardVestingHive),
    vestingShares: _fromVests(hiveAccount.vestingShares),
    delegatedVestingShares: _fromVests(hiveAccount.delegatedVestingShares),
    receivedVestingShares: _fromVests(hiveAccount.receivedVestingShares),
    vestingWithdrawRate: _fromVests(hiveAccount.vestingWithdrawRate),
    postVotingPower: _fromVests(hiveAccount.postVotingPower),
    nextVestingWithdrawal: hiveAccount.nextVestingWithdrawal,
    withdrawn: hiveAccount.withdrawn,
    toWithdraw: hiveAccount.toWithdraw,
    withdrawRoutes: hiveAccount.withdrawRoutes,
    pendingTransfers: hiveAccount.pendingTransfers,
    curationRewards: hiveAccount.curationRewards,
    postingRewards: hiveAccount.postingRewards,
    lastPost: hiveAccount.lastPost,
    lastRootPost: hiveAccount.lastRootPost,
    lastVoteTime: hiveAccount.lastVoteTime,
    pendingClaimedAccounts: hiveAccount.pendingClaimedAccounts,
    governanceVoteExpiration: hiveAccount.governanceVoteExpirationTs,
    openRecurrentTransfers: hiveAccount.openRecurrentTransfers,
    vestingBalance: _fromHive(hiveAccount.vestingBalance),
    tribeEarnedToken: tribeAccount.earnedToken,
    tribeUpvotePower: tribeAccount.votingPower,
    tribeDownvotePower: tribeAccount.downvotingPower,
    tribeSymbol: tribeAccount.symbol,
    tribeEarnedMiningToken: tribeAccount.earnedMiningToken,
    tribeEarnedStakingToken: tribeAccount.earnedStakingToken,
    tribeEarnedOtherToken: tribeAccount.earnedOtherToken,
    tribeLastUpvoteTime: tribeAccount.lastVoteTime,
    tribeLastDownvoteTime: tribeAccount.lastDownvoteTime,
    tribeLastPostTime: tribeAccount.lastPost,
    tribeLastRootPostTime: tribeAccount.lastRootPost,
    tribeLastWonMiningClaim: tribeAccount.lastWonMiningClaim,
    tribeLastWonStakingClaim: tribeAccount.lastWonStakingClaim,
    tribeIsMuted: tribeAccount.muted,
    tribePendingToken: tribeAccount.pendingToken,
    tribePrecision: tribeAccount.precision,
    tribeStakedMiningPower: tribeAccount.stakedMiningPower,
    tribeStakedTokens: tribeAccount.stakedTokens,
    tribeUpvoteWeightMultiplier: tribeAccount.voteWeightMultiplier,
    tribeDownvoteWeightMultiplier: tribeAccount.downvoteWeightMultiplier,
  );
}

Profile? _parseProfileFromMetadata(String metadata) {
  try {
    final hiveProfile = hive_api.ProfileMetadata.fromJson(
      jsonDecode(metadata) as Map<String, dynamic>,
    ).profile;
    return Profile(
      name: hiveProfile?.name,
      about: hiveProfile?.about,
      website: hiveProfile?.website,
      location: hiveProfile?.location,
      coverImage: hiveProfile?.coverImage,
      profileImage: hiveProfile?.profileImage,
    );
  } catch (e, s) {
    print('Could not parse profile from metadata: $e');
    print(s);
    print('metadata $metadata');
    return null;
  }
}

Manabar _convertHiveManabar(hive_api.Manabar hiveManabar) {
  return Manabar(
    currentMana: hiveManabar.currentMana,
    lastUpdateTime: DateTime.fromMillisecondsSinceEpoch(
      hiveManabar.lastUpdateTime * 1000,
      isUtc: true,
    ),
  );
}

double _fromHive(String s) => _removeAndConvert(s, r' HIVE$');
double _fromHbd(String s) => _removeAndConvert(s, r' HBD$');
double _fromVests(String s) => _removeAndConvert(s, r' VESTS$');

double _removeAndConvert(String s, String p) =>
    double.parse(s.replaceFirst(RegExp(p), ''));

Comments buildComments(
  hive_api.Discussion discussion,
  scot_api.PostInfo tribePost,
  Map<String, scot_api.PostInfo?> tribeComments, {
  required scot_api.TokenInfo tokenInfo,
}) {
  // Extract the children of each of the comments, and discard those that
  //  weren't found in the tribeComments
  final children = discussion.comments.map(
    (ap, post) => MapEntry('@$ap', post.replies.map((v) => '@$v').toList()),
  )..removeWhere((ap, _) => !tribeComments.containsKey(ap.substring(1)));

  final comments = children.map(
    (ap, _) => MapEntry(
      ap,
      // Because we have already discuarded those not found in tribeComments,
      // this will never return null
      _extractComment(
        ap.substring(1),
        hiveComments: discussion.comments,
        tribeComments: tribeComments,
        tokenInfo: tokenInfo,
      )!,
    ),
  );

  // Add the replies to the parent post to the list of children (they are not
  // part of the earlier discussion.comments map).
  children['@${discussion.post.author}/${discussion.post.permlink}'] =
      discussion.post.replies.map((v) => '@$v').toList()
        ..removeWhere((ap) => !tribeComments.containsKey(ap.substring(1)));

  return Comments(
    parent: Authorperm(discussion.post.author, discussion.post.permlink),
    children: children,
    items: comments,
  );
}

Comment? _extractComment(
  String authorperm, {
  required Map<String, hive_api.Post> hiveComments,
  required Map<String, scot_api.PostInfo?> tribeComments,
  required scot_api.TokenInfo tokenInfo,
}) {
  // Should not be null (but ok if it does)
  final hivePost = hiveComments[authorperm];

  // Null if we don't find the comment in scotbot
  final tribePost = tribeComments[authorperm];

  // print('hivePost: $hivePost');
  // print('tribePost: $tribePost');

  if (hivePost == null || tribePost == null) {
    return null;
  }

  return buildComment(hivePost, tribePost, tokenInfo: tokenInfo);

  // final replies = hivePost.replies
  //     .map((authorPerm) => _buildComment(authorPerm,
  //         hiveComments: hiveComments,
  //         tribeComments: tribeComments,
  //         tokenInfo: tokenInfo))
  //     .whereType<Content>() // Remove nulls
  //     .toList();
  // return buildComment(hivePost, tribePost,
  //     replies: replies, tokenInfo: tokenInfo);
}

// Comment _mergeComment(String authorperm) {
//   // print('mergeComment $authorperm');
//   final hiveComment = discussion.comments[authorperm]!;
//   final tribeComment = tribeCommentData[permlinks.indexOf(authorperm)];

//   List<Content> replies = [];
//   if (hiveComment.replies.isNotEmpty) {
//     replies = hiveComment.replies.map(mergeComment).toList();
//   }

//   return _mergeContent(hiveComment, tribeComment, replies: replies);
// }

Post buildPost(
  hive_api.Post hivePost,
  scot_api.PostInfo tribePost, {
  required scot_api.TokenInfo tokenInfo,
}) {
  // final upvotes =
  //     tribePost.activeVotes.where((v) => v.rshares > 0 || v.percent > 0);
  // final downvotes =
  //     tribePost.activeVotes.where((v) => v.rshares < 0 || v.percent < 0);

  final voteMapper = VoteMapper(tribePost, tokenInfo);
  // final upvoteValues = _getVoteValues(hivePost, tribePost,
  //     votes: upvotes,
  //     rsharesTotal: _calcRsharesTotal(upvotes),
  //     tokenInfo: tokenInfo);
  // final downvoteValues = _getVoteValues(hivePost, tribePost,
  //     votes: downvotes,
  //     rsharesTotal: _calcRsharesTotal(downvotes),
  //     tokenInfo: tokenInfo);

  return Post(
    id: hivePost.postId,
    author: hivePost.author,
    permlink: hivePost.permlink,
    category: hivePost.category,
    title: hivePost.title,
    body: hivePost.body,
    jsonMetadata: hivePost.jsonMetadata,
    created: hivePost.created,
    updated: hivePost.updated,
    numChildren: hivePost.children,
    netRshares: hivePost.netRshares,
    authorReputation: hivePost.authorReputation ?? 0,
    stats: hivePost.stats,
    url: hivePost.url,
    beneficiaries: hivePost.beneficiaries,
    maxAcceptedPayout: hivePost.maxAcceptedPayout,
    community: hivePost.community ?? '',
    communityTitle: hivePost.communityTitle ?? '',
    tribePendingToken: tribePost.pendingToken,
    tribePrecision: tribePost.precision,
    tribeToken: tribePost.token,
    tribeIsMuted: tribePost.muted,
    tribeScoreHot: tribePost.scoreHot,
    tribeScorePromoted: tribePost.scorePromoted,
    tribeScoreTrend: tribePost.scoreTrend,
    tribeTotalPayoutValue: tribePost.totalPayoutValue,
    tribeTotalVoteWeight: tribePost.totalVoteWeight,
    tribeVoteRshares: tribePost.voteRshares,
    upvotes: _convertHiveVotes(
      hivePost.activeVotes,
      where: (av) => av.rshares > 0,
    ),
    downvotes: _convertHiveVotes(
      hivePost.activeVotes,
      where: (av) => av.rshares < 0,
    ),
    tribeUpvotes: voteMapper.getUpvotes(),
    tribeDownvotes: voteMapper.getDownvotes(),
  );
}

Map<String, int> _convertHiveVotes(
  List<hive_api.ActiveVote> activeVotes, {
  required bool Function(hive_api.ActiveVote) where,
}) {
  return {
    for (final av in activeVotes.where(where)) av.voter: av.rshares,
  };
}

Comment buildComment(
  hive_api.Post hivePost,
  scot_api.PostInfo tribePost, {
  required scot_api.TokenInfo tokenInfo,
}) {
  final voteMapper = VoteMapper(tribePost, tokenInfo);

  return Comment(
    id: hivePost.postId,
    author: hivePost.author,
    permlink: hivePost.permlink,
    category: hivePost.category,
    title: hivePost.title,
    body: hivePost.body,
    parentAuthor: hivePost.parentAuthor!,
    parentPermlink: hivePost.parentPermlink!,
    jsonMetadata: hivePost.jsonMetadata,
    created: hivePost.created,
    updated: hivePost.updated,
    depth: hivePost.depth,
    numChildren: hivePost.children,
    netRshares: hivePost.netRshares,
    authorReputation: hivePost.authorReputation ?? 0,
    stats: hivePost.stats,
    url: hivePost.url,
    beneficiaries: hivePost.beneficiaries,
    maxAcceptedPayout: hivePost.maxAcceptedPayout,
    community: hivePost.community ?? '',
    communityTitle: hivePost.communityTitle ?? '',
    tribePendingToken: tribePost.pendingToken,
    tribePrecision: tribePost.precision,
    tribeToken: tribePost.token,
    tribeIsMuted: tribePost.muted,
    tribeScoreHot: tribePost.scoreHot,
    tribeScorePromoted: tribePost.scorePromoted,
    tribeScoreTrend: tribePost.scoreTrend,
    tribeTotalPayoutValue: tribePost.totalPayoutValue,
    tribeTotalVoteWeight: tribePost.totalVoteWeight,
    tribeVoteRshares: tribePost.voteRshares,
    upvotes: _convertHiveVotes(
      hivePost.activeVotes,
      where: (av) => av.rshares > 0,
    ),
    downvotes: _convertHiveVotes(
      hivePost.activeVotes,
      where: (av) => av.rshares < 0,
    ),
    tribeUpvotes: voteMapper.getUpvotes(),
    tribeDownvotes: voteMapper.getDownvotes(),
  ); //hivePost.replies);
}
