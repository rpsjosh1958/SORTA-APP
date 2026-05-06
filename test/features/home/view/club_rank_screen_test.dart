import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorta/core/models/club_info.dart';
import 'package:sorta/core/providers/auth_provider.dart';
import 'package:sorta/core/providers/club_provider.dart';
import 'package:sorta/core/theme/app_theme.dart';
import 'package:sorta/features/home/view/club_rank_screen.dart';

const _testClubId = 'test-club-1';

const _testClub = ClubInfo(
  id: _testClubId,
  name: 'Brain Squad',
  code: 'ABC123',
  rank: 14,
  memberCount: 3,
  categories: ['ALL'],
);

final _testMembers = [
  const ClubMember(uid: 'u1', displayName: 'JoshT', clubScore: 4280, rank: 1, avatarSeed: 'u1'),
  const ClubMember(uid: 'u2', displayName: 'SarahK', clubScore: 3900, rank: 2, avatarSeed: 'u2'),
  const ClubMember(uid: 'u3', displayName: 'Mike22', clubScore: 3400, rank: 3, avatarSeed: 'u3'),
];

Widget _buildSubject() => ProviderScope(
      overrides: [
        clubInfoProvider(_testClubId)
            .overrideWith((_) => Stream.value(_testClub)),
        clubMembersProvider(_testClubId)
            .overrideWith((_) => Stream.value(_testMembers)),
        currentUserProvider.overrideWith((_) => null),
      ],
      child: MaterialApp(
        theme: AppThemeNotifier.light,
        home: const ClubRankScreen(clubId: _testClubId),
      ),
    );

void main() {
  testWidgets('ClubRankScreen shows club name', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('BRAIN SQUAD'), findsOneWidget);
  });

  testWidgets('ClubRankScreen shows member count stat pill', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('3 MEMBERS'), findsOneWidget);
  });

  testWidgets('ClubRankScreen shows rank stat pill', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.text('RANK #14'), findsOneWidget);
  });

  testWidgets('ClubRankScreen shows top member username', (tester) async {
    await tester.pumpWidget(_buildSubject());
    await tester.pump();
    expect(find.textContaining('JoshT'), findsWidgets);
  });
}
