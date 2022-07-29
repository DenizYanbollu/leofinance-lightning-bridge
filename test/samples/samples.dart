import 'dart:convert';
import 'dart:io';

import 'package:scot_api/scot_api.dart';

Future<TokenInfo> sampleTokenInfo() async {
  final s = await File('test/samples/token_info.json').readAsString();
  return TokenInfo.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

Future<PostInfo> sampleScotPostInfo() async {
  final s = await File('test/samples/scot_post_info.json').readAsString();
  return PostInfo.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

Future<PostInfo> sampleScotPostInfoNoActiveVotes() async {
  final s = await File('test/samples/scot_post_info_no_active_votes.json')
      .readAsString();
  return PostInfo.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
