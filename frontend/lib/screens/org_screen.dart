import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../posts_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _joined = widget.initiallyJoined;
  }

  Future<void> _confirmLeave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Org'),
        content: const Text('Are you sure you want to leave this org?'),
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
      setState(() => _joined = false);
      if (widget.onJoinChanged != null) widget.onJoinChanged!(_joined);
      Navigator.of(context).pop();
    }
  }

  void _onJoinPressed() {
    if (_joined) {
      _confirmLeave();
    } else {
      setState(() => _joined = true);
      if (widget.onJoinChanged != null) widget.onJoinChanged!(_joined);
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
    final memberCount = (widget.org['member_id'] as List?)?.length ?? 0;
    final description = widget.org['description'] ?? 'No description provided.';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                color: const Color(0xFFEEF7FB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBCD9EC)),
              ),
              child: Text('$memberCount members',
                  style: GoogleFonts.lato(
                      color: const Color(0xFF7496B3), fontSize: 12)),
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
                        color: const Color.fromARGB(255, 220, 220, 232),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search posts...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
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
