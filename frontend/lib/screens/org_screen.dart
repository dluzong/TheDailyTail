import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../posts_provider.dart';
import '../organization_provider.dart';

class OrgScreen extends StatefulWidget {
  final Map<String, dynamic> org;
  final bool initiallyJoined;
  final void Function(bool joined)? onJoinChanged;

  const OrgScreen(
      {super.key,
      required this.org,
      this.initiallyJoined = true,
      this.onJoinChanged});

  @override
  State<OrgScreen> createState() => _OrgScreenState();
}

class _OrgScreenState extends State<OrgScreen> {
  late bool _joined;
  int _memberCount = 0;

  @override
  void initState() {
    super.initState();
    _joined = widget.initiallyJoined;
    if (widget.org['organization_members'] is List &&
        (widget.org['organization_members'] as List).isNotEmpty) {
      _memberCount =
          (widget.org['organization_members'][0]['count'] as int?) ?? 0;
    } else {
      _memberCount = 0;
    }
  }

  Future<void> _confirmLeave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Organization'),
        content:
            const Text('Are you sure you want to leave this organization?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Nevermind',
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB94A48),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Yes, leave',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _joined = false;
        if (_memberCount > 0) _memberCount -= 1;
      });

      if (widget.onJoinChanged != null) {
        widget.onJoinChanged!(false);
      } else {
        final orgId = widget.org['organization_id'] as String;
        final provider = context.read<OrganizationProvider>();
        await provider.leaveOrg(orgId);
      }
    }
  }

  Future<void> _onJoinPressed() async {
    if (_joined) {
      _confirmLeave();
    } else {
      setState(() {
        _joined = true;
        _memberCount += 1;
      });

      if (widget.onJoinChanged != null) {
        widget.onJoinChanged!(true);
      } else {
        final orgId = widget.org['organization_id'] as String;
        final provider = context.read<OrganizationProvider>();
        await provider.joinOrg(orgId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsProvider = Provider.of<PostsProvider>(context);

    // Filter Recent Activity: Posts where author is an Admin of this Org
    // widget.org['admin_id'] is a List<dynamic> of UUIDs from Supabase
    final List<dynamic> adminIds = widget.org['admin_id'] ?? [];

    // Filter posts from PostsProvider where userId is in adminIds
    final recentPosts =
        postsProvider.posts.where((p) => adminIds.contains(p.userId)).toList();

    // Map keys to DB columns
    final orgName = widget.org['name'] ?? 'Unnamed Org';

    final memberCount = _memberCount;

    final description = widget.org['description'] ?? 'No description provided.';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Expanded(
              child: Text(
                orgName,
                style: GoogleFonts.lato(
                    color: const Color(0xFF5F7C94),
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3A5A75)
                    : const Color(0xFFEEF7FB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF4A6B85)
                      : const Color(0xFFBCD9EC),
                ),
              ),
              child: Text('$memberCount members',
                  style: GoogleFonts.lato(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF7496B3),
                      fontSize: 12)),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton(
              onPressed: _onJoinPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _joined ? Colors.green : const Color(0xFF7496B3),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child:
                  Text(_joined ? 'Joined' : 'Join', style: GoogleFonts.lato()),
            ),
          )
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2A2A2A)
                            : const Color.fromARGB(255, 220, 220, 232),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF666666)
                                    : Colors.grey[400],
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF666666)
                                    : Colors.grey[400],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              labelColor: const Color(0xFF7496B3),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF7496B3),
              tabs: [
                Tab(
                    child: Text('Recent Activity',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold))),
                Tab(
                    child: Text('Description',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  // Recent Activity
                  recentPosts.isEmpty
                      ? Center(
                          child: Text('No recent activity.',
                              style: GoogleFonts.lato()))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: recentPosts.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final post = recentPosts[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor:
                                              const Color(0xFF7496B3),
                                          backgroundImage: post
                                                  .authorPhoto.isNotEmpty
                                              ? NetworkImage(post.authorPhoto)
                                              : null,
                                          child: post.authorPhoto.isEmpty
                                              ? const Icon(Icons.person,
                                                  color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Row(children: [
                                            Text(post.authorName,
                                                style: GoogleFonts.lato(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFEEF7FB),
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                              child: Text('admin',
                                                  style: GoogleFonts.lato(
                                                      color: const Color(
                                                          0xFF7496B3),
                                                      fontSize: 12)),
                                            ),
                                          ]),
                                        ),
                                        Text(post.createdTs,
                                            style: GoogleFonts.lato(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(post.title,
                                        style: GoogleFonts.lato(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text(post.content,
                                        style: GoogleFonts.lato()),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  // Description
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(description,
                        style: GoogleFonts.lato(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
