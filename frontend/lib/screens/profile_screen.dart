import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_layout.dart';
import 'user_settings.dart' as user_settings;
import '../user_provider.dart';
import '../pet_provider.dart' as pet_provider;
import '../posts_provider.dart';
import 'pet_list.dart' as pet_list;
import 'all_pets_screen.dart';
import 'community_post_screen.dart'; // Added for navigation to post details

class ProfileScreen extends StatefulWidget {
  final String? otherUsername; // null means viewing own profile

  const ProfileScreen({
    super.key,
    this.otherUsername,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Map<String, dynamic>? _otherUserData;

  bool get _isOwnProfile => widget.otherUsername == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController?.addListener(() {
      if (mounted) setState(() {});
    });
    if (!_isOwnProfile) {
      _loadOtherUserData();
    }
  }

  // TODO: Replace this with a real fetch from Supabase 'users' table by username
  void _loadOtherUserData() {
    _otherUserData = {
      'username': widget.otherUsername,
      'firstName': widget.otherUsername!.split(' ')[0],
      'lastName': widget.otherUsername!.split(' ').length > 1
          ? widget.otherUsername!.split(' ')[1]
          : '',
      'role': 'Pet Owner',
      'bio':
          'Pet lover and enthusiast. Love sharing moments with my furry friends!',
      'totalPosts': 12,
      'totalFollowers': 45,
      'totalFollowing': 32,
      'pets': [
        // Mock data for other users stays until we add "fetchUserProfile" logic
        {
          'name': 'Max',
          'breed': 'Golden Retriever',
          'age': 3,
          'weight': 65.0,
          'imageUrl': '',
        },
      ],
    };
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildAboutTab() {
    final size = MediaQuery.of(context).size;
    String bio;

    if (_isOwnProfile) {
      final appUser = context.watch<UserProvider>().user;
      bio = appUser?.bio ?? "Hello! I don't have a bio yet :[";
    } else {
      bio = _otherUserData?['bio'] ??
          "Thanks for visiting! I don't have a bio yet :[";
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(size.width * 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: size.height * 0.015),
          Text(
            bio,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: size.width * 0.038,
              color: const Color(0xFF394957),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsTab() {
    final size = MediaQuery.of(context).size;

    // A. Viewing another user's profile (Mock Data for now)
    if (!_isOwnProfile) {
      final pets = _otherUserData?['pets'] as List<dynamic>? ?? [];

      if (pets.isEmpty) {
        return Center(
          child: Text(
            'No pets found.',
            style: GoogleFonts.lato(
                fontSize: size.width * 0.04, color: const Color(0xFF394957)),
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
        child: Column(
          children: [
            ...List.generate(pets.length, (index) {
              final petMap = pets[index];
              // Create a temporary Pet object with mock data
              final displayPet = pet_provider.Pet(
                petId: 'mock_$index',
                userId: 'mock_user',
                name: petMap['name'],
                breed: petMap['breed'],
                age: petMap['age'],
                weight: petMap['weight'],
                imageUrl: petMap['imageUrl'] ?? '',
                status: 'owned',
                savedMeals: [],
                savedMedications: [],
              );

              return Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.02),
                child: pet_list.ExpandablePetCard(pet: displayPet),
              );
            }),
            Center(
              child: Container(
                width: size.width * 0.2,
                height: 1.5,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    // B. Viewing OWN profile (Real Data)
    return Consumer<pet_provider.PetProvider>(
      builder: (context, petProv, _) {
        if (petProv.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (petProv.pets.isEmpty) {
          return Center(
            child: Text(
              'No pets found. Add one in settings!',
              style: GoogleFonts.lato(
                  fontSize: size.width * 0.04, color: const Color(0xFF394957)),
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
          child: Column(
            children: [
              ...List.generate(petProv.pets.length, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: size.height * 0.02),
                  child: pet_list.ExpandablePetCard(
                    pet: petProv.pets[index],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: size.width * 0.2,
                  height: 1.5,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostsTab() {
    final size = MediaQuery.of(context).size;
    return Consumer<PostsProvider>(
      builder: (context, postsProvider, _) {
        final targetAuthorName = _isOwnProfile ? 'You' : widget.otherUsername;

        // Filter posts where author name matches.
        // Note: Ideally, we should filter by userId, but for now matching Name logic from CommunityScreen
        final userPosts = postsProvider.posts
            .where((post) => post.authorName == targetAuthorName)
            .toList();

        if (userPosts.isEmpty) {
          return Center(
            child: Text(
              'No posts yet.',
              style: GoogleFonts.lato(
                fontSize: size.width * 0.04,
                color: const Color(0xFF394957),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(size.width * 0.04),
          itemCount: userPosts.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: size.height * 0.02),
          itemBuilder: (context, index) {
            final post = userPosts[index];
            // Find real index for toggleLike
            final realIndex = postsProvider.posts.indexOf(post);

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(size.width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: GoogleFonts.lato(
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF394957),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    Text(
                      post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: size.width * 0.038,
                        color: const Color(0xFF394957),
                      ),
                    ),
                    SizedBox(height: size.height * 0.015),
                    if (post.category.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.03,
                          vertical: size.height * 0.007,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF7FB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBCD9EC)),
                        ),
                        child: Text(
                          post.category,
                          style: GoogleFonts.lato(
                            color: const Color(0xFF7496B3),
                            fontWeight: FontWeight.w600,
                            fontSize: size.width * 0.03,
                          ),
                        ),
                      ),
                    SizedBox(height: size.height * 0.015),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => postsProvider.toggleLike(realIndex),
                          child: Row(
                            children: [
                              Icon(
                                  post.isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: size.width * 0.045,
                                  color: post.isLiked
                                      ? Colors.red
                                      : const Color(0xFF7496B3)),
                              SizedBox(width: size.width * 0.01),
                              Text(
                                '${post.likesCount}',
                                style: GoogleFonts.lato(
                                  color: const Color(0xFF394957),
                                  fontSize: size.width * 0.035,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: size.width * 0.04),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CommunityPostScreen(postIndex: realIndex),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(Icons.comment_outlined,
                                  size: size.width * 0.045,
                                  color: const Color(0xFF7496B3)),
                              SizedBox(width: size.width * 0.01),
                              Text(
                                '${post.commentCount}',
                                style: GoogleFonts.lato(
                                  color: const Color(0xFF394957),
                                  fontSize: size.width * 0.035,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          post.createdTs,
                          style: GoogleFonts.lato(
                            fontSize: size.width * 0.03,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      const child = Center(child: CircularProgressIndicator());
      return _isOwnProfile
          ? AppLayout(currentIndex: 4, onTabSelected: (_) {}, child: child)
          : Scaffold(appBar: AppBar(), body: child);
    }

    final size = MediaQuery.of(context).size;
    final textScale = MediaQuery.of(context).textScaleFactor;

    // Get user data based on profile type
    String name;
    String username;
    List<String> roles;
    int totalPosts, totalFollowers, totalFollowing;

    if (_isOwnProfile) {
      final appUser = context.watch<UserProvider>().user;
      name = appUser?.name ?? 'Your Name';
      username = appUser?.username ?? 'username';
      final rolesList = appUser?.roles;
      roles =
          (rolesList == null || rolesList.isEmpty) ? ['Visitor'] : rolesList;

      final postsProvider = context.watch<PostsProvider>();
      totalPosts =
          postsProvider.posts.where((post) => post.authorName == 'You').length;

      // TODO: Implement Followers count in DB. For now hardcoded or 0.
      totalFollowers = 86;

      // Using the real 'following' list from UserProvider
      totalFollowing = appUser?.following.length ?? 0;
    } else {
      name =
          '${_otherUserData?['firstName'] ?? ''} ${_otherUserData?['lastName'] ?? ''}'
              .trim();
      username = _otherUserData?['username'] ?? '';
      roles = [_otherUserData?['role'] ?? 'User'];
      totalPosts = (_otherUserData?['totalPosts'] as int?) ?? 0;
      totalFollowers = (_otherUserData?['totalFollowers'] as int?) ?? 0;
      totalFollowing = (_otherUserData?['totalFollowing'] as int?) ?? 0;
    }

    double avatarSize = size.width * 0.25;

    final content = Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: EdgeInsets.all(size.width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: avatarSize / 2,
                        backgroundColor: const Color(0xFF7496B3),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: avatarSize * 0.5,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: size.width * 0.04),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inknutAntiqua(
                                  fontSize: 20 * textScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                username,
                                style: GoogleFonts.inknutAntiqua(
                                  fontSize: 16 * textScale,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.center,
                                  children: roles.map((role) {
                                    // Map role to color based on user_settings_dialogs.dart
                                    final roleColors = {
                                      'owner': const Color(0xFF2C5F7F),
                                      'organizer': const Color(0xFF5A8DB3),
                                      'foster': const Color.fromARGB(255, 118, 178, 230),
                                      'visitor': const Color.fromARGB(255, 156, 201, 234),
                                    };
                                    
                                    final roleLower = role.toLowerCase();
                                    final color = roleColors[roleLower] ?? const Color(0xFF7496B3);
                                    
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: size.width * 0.04,
                                        vertical: size.height * 0.005,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        role[0].toUpperCase() + role.substring(1),
                                        style: GoogleFonts.inknutAntiqua(
                                          fontSize: 12 * textScale,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: size.height * 0.02),
                  // User Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildStatColumn('Posts', totalPosts.toString(),
                          onTap: null),
                      SizedBox(width: size.width * 0.08),
                      _buildStatColumn('Followers', totalFollowers.toString(),
                          onTap: () => _showFollowersDialog(context)),
                      SizedBox(width: size.width * 0.08),
                      _buildStatColumn('Following', totalFollowing.toString(),
                          onTap: () => _showFollowingDialog(context)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: size.height * 0.02),
            // Tab Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController!,
                labelColor: const Color(0xFF7496B3),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF7496B3),
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Text(
                      'About',
                      style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.038),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Pets',
                      style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.038),
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Posts',
                      style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: size.width * 0.038),
                    ),
                  ),
                ],
              ),
            ),
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController!,
                children: [
                  _buildAboutTab(),
                  _buildPetsTab(),
                  _buildPostsTab(),
                ],
              ),
            ),
          ],
        ),
        // Settings button (only for own profile)
        if (_isOwnProfile)
          Positioned(
            top: size.height * 0.01,
            right: size.width * 0.02,
            child: IconButton(
              icon: Icon(
                Icons.settings,
                size: size.width * 0.07,
                color: const Color(0xFF7496B3),
              ),
              tooltip: 'User Settings',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const user_settings.UserSettingsPage(
                      currentIndex: 4,
                      onTabSelected: _noop,
                    ),
                  ),
                );
              },
            ),
          ),
        // Pet View All button
        if (_tabController != null && _tabController!.index == 1)
          Positioned(
            right: size.width * 0.04,
            bottom: size.height * 0.02,
            child: FloatingActionButton.extended(
              heroTag: 'view_all_pets_fab',
              backgroundColor: const Color(0xFF7496B3),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.view_list),
              label: Text(
                'View All',
                style: GoogleFonts.lato(fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                List<pet_list.Pet> displayPets;
                String name;

                if (_isOwnProfile) {
                  final petProv = context.read<pet_provider.PetProvider>();
                  final userProv = context.read<UserProvider>();
                  displayPets = petProv.pets
                      .map((p) => pet_list.Pet(name: p.name, imageUrl: p.imageUrl))
                      .toList();
                  name = userProv.user?.name ?? 'Your name';
                } else {
                  final otherPets = (_otherUserData?['pets'] as List<dynamic>?) ?? [];
                  displayPets = otherPets
                      .map((e) => pet_list.Pet(
                            name: e['name']?.toString() ?? 'Pet',
                            imageUrl: e['imageUrl']?.toString() ?? '',
                          ))
                      .toList();
                  final first = _otherUserData?['firstName']?.toString() ?? '';
                  final last = _otherUserData?['lastName']?.toString() ?? '';
                  name = (first + ' ' + last).trim();
                  if (name.isEmpty) {
                    name = _otherUserData?['username']?.toString() ?? 'User';
                  }
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllPetsScreen(
                      pets: displayPets,
                      name: name,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );

    return AppLayout(
      currentIndex: 4,
      onTabSelected: (_) {},
      showBackButton: !_isOwnProfile,
      child: content,
    );
  }

  Widget _buildStatColumn(String label, String value, {VoidCallback? onTap}) {
    final size = MediaQuery.of(context).size;
    final child = Container(
      width: size.width * 0.25,
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: size.width * 0.04,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF394957),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: size.width * 0.035,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }
    return child;
  }

  void _showFollowersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Followers"),
        content: const Text("Follower list implementation coming soon!"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"))
        ],
      ),
    );
  }

  void _showFollowingDialog(BuildContext context) {
    List<Map<String, String>> following;

    if (_isOwnProfile) {
      // Use real data from UserProvider
      final user = context.read<UserProvider>().user;
      final followingIds = user?.following ?? [];

      // TODO: Fetch user details for these IDs. For now, display IDs or placeholder.
      following = followingIds
          .map((id) => {
                'fullName': 'User ID',
                'username': id.substring(0, 8),
              })
          .toList();
    } else {
      // Mock for others
      following = [];
    }

    showDialog(
      context: context,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            constraints: const BoxConstraints(maxWidth: 340, maxHeight: 400),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF7496B3)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Following',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF394957),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(height: 2, color: Color(0xFF5F7C94)),
                const SizedBox(height: 12),
                Flexible(
                  child: following.isEmpty
                      ? Center(
                          child: Text(
                            'Not following anyone yet.',
                            style: GoogleFonts.lato(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: following.length,
                          itemBuilder: (context, index) {
                            final user = following[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF7496B3),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                user['username']!,
                                style: GoogleFonts.inknutAntiqua(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                user['fullName']!,
                                style:
                                    GoogleFonts.lato(color: Colors.grey[600]),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _noop(int _) {}
