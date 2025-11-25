import 'package:flutter/material.dart';
import 'pet_list.dart' as pet_list;
import '../shared/app_layout.dart';
import 'user_settings.dart' as user_settings;
import '../user_provider.dart';
import '../pet_provider.dart' as pet_provider;
import '../posts_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'all_pets_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? otherUsername; // null means viewing own profile

  const ProfileScreen({
    super.key,
    this.otherUsername,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  
  // Mock data for other users - TODO: replace with backend data
  Map<String, dynamic>? _otherUserData;
  
  bool get _isOwnProfile => widget.otherUsername == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (!_isOwnProfile) {
      _loadOtherUserData();
    }
  }

  void _loadOtherUserData() {
    // Generate mock data for other user
    _otherUserData = {
      'username': widget.otherUsername,
      'firstName': widget.otherUsername!.split(' ')[0],
      'lastName': widget.otherUsername!.split(' ').length > 1 ? widget.otherUsername!.split(' ')[1] : '',
      'role': 'Pet Owner',
      'bio': 'Pet lover and enthusiast. Love sharing moments with my furry friends!',
      'totalPosts': 12,
      'totalFollowers': 45,
      'totalFollowing': 32,
      'pets': [
        {
          'name': 'Max',
          'breed': 'Golden Retriever',
          'age': 3,
          'weight': 65,
        },
        {
          'name': 'Luna',
          'breed': 'Siamese Cat',
          'age': 2,
          'weight': 10,
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
    final bio = _isOwnProfile 
        ? "Hello I'm Anon! I have the cutest dog named Aries. He loves going to the park!!"
        : (_otherUserData?['bio'] ?? '');
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(size.width * 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: size.height * 0.015),
          Text(
            bio,
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

    // If viewing another user's profile, show mock data
    if (!_isOwnProfile) {
      final pets = _otherUserData?['pets'] as List<dynamic>? ?? [];
      
      if (pets.isEmpty) {
        return Center(
          child: Text(
            'No pets found.',
            style: GoogleFonts.lato(
              fontSize: size.width * 0.04,
              color: const Color(0xFF394957),
            ),
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
        child: Column(
          children: [
            ...List.generate(pets.length, (index) {
              final pet = pets[index];
              final mockPet = pet_provider.Pet(
                petId: index.toString(),
                name: pet['name'],
                breed: pet['breed'],
                age: pet['age'],
                weight: pet['weight'],
              );
              return Padding(
                padding: EdgeInsets.only(bottom: size.height * 0.02),
                child: pet_list.ExpandablePetCard(
                  pet: mockPet,
                ),
              );
            }),
            Center(
              child: Container(
                width: size.width * 0.2,
                height: 1.5,
                color: Colors.grey,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
              child: ElevatedButton(
                onPressed: () {
                  final petsList = pets
                      .map((p) => pet_list.Pet(
                            name: p['name'],
                            imageUrl: '',
                          ))
                      .toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllPetsScreen(
                        pets: petsList,
                        firstName: _otherUserData?['firstName'] ?? '',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7496B3),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.08,
                    vertical: size.height * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.lato(
                    fontSize: size.width * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Own profile: use PetProvider
    return Consumer<pet_provider.PetProvider>(
      builder: (context, petProv, _) {
        if (petProv.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (petProv.pets.isEmpty) {
          return Center(
            child: Text(
              'No pets found.',
              style: GoogleFonts.lato(
                fontSize: size.width * 0.04,
                color: const Color(0xFF394957),
              ),
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
              Center(
                child: Container(
                  width: size.width * 0.2,
                  height: 1.5,
                  color: Colors.grey,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
                child: Consumer<UserProvider>(
                  builder: (context, userProv, _) {
                    return ElevatedButton(
                      onPressed: () {
                        final pets = petProv.pets
                            .map((p) => pet_list.Pet(name: p.name, imageUrl: ''))
                            .toList();
                        final firstName = userProv.user?.firstName ?? 'Your';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllPetsScreen(
                              pets: pets,
                              firstName: firstName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7496B3),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.08,
                          vertical: size.height * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View All',
                        style: GoogleFonts.lato(
                          fontSize: size.width * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ),
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
        final targetAuthor = _isOwnProfile ? 'You' : widget.otherUsername!;
        final userPosts = postsProvider.posts
            .where((post) => post['author'] == targetAuthor)
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
          separatorBuilder: (context, index) => SizedBox(height: size.height * 0.02),
          itemBuilder: (context, index) {
            final post = userPosts[index];
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
                      post['title'] ?? '',
                      style: GoogleFonts.lato(
                        fontSize: size.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF394957),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    Text(
                      post['content'] ?? '',
                      style: GoogleFonts.lato(
                        fontSize: size.width * 0.038,
                        color: const Color(0xFF394957),
                      ),
                    ),
                    SizedBox(height: size.height * 0.015),
                    if (post['category'] != null && (post['category'] as String).isNotEmpty)
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
                          post['category'],
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
                        Icon(Icons.favorite_border, size: size.width * 0.045, color: const Color(0xFF7496B3)),
                        SizedBox(width: size.width * 0.01),
                        Text(
                          '${post['likes']}',
                          style: GoogleFonts.lato(
                            color: const Color(0xFF394957),
                            fontSize: size.width * 0.035,
                          ),
                        ),
                        SizedBox(width: size.width * 0.04),
                        Icon(Icons.comment_outlined, size: size.width * 0.045, color: const Color(0xFF7496B3)),
                        SizedBox(width: size.width * 0.01),
                        Text(
                          '${post['comments']}',
                          style: GoogleFonts.lato(
                            color: const Color(0xFF394957),
                            fontSize: size.width * 0.035,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          post['timeAgo'] ?? '',
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
      final child = const Center(child: CircularProgressIndicator());
      return _isOwnProfile
          ? AppLayout(currentIndex: 4, onTabSelected: (_) {}, child: child)
          : Scaffold(appBar: AppBar(), body: child);
    }

    final size = MediaQuery.of(context).size;
    final textScale = MediaQuery.of(context).textScaleFactor;

    // Get user data based on profile type
    String fullName, username, role;
    int totalPosts, totalFollowers, totalFollowing;
    
    if (_isOwnProfile) {
      final appUser = context.watch<UserProvider>().user;
      fullName = appUser != null
          ? '${appUser.firstName} ${appUser.lastName}'.trim()
          : 'Your Name';
      username = appUser?.username ?? 'username';
      role = appUser?.role ?? 'User';
      
      final postsProvider = context.watch<PostsProvider>();
      totalPosts = postsProvider.posts.where((post) => post['author'] == 'You').length;
      totalFollowers = 86;
      totalFollowing = postsProvider.posts
          .where((post) => postsProvider.isFollowing(post['author'] as String))
          .map((post) => post['author'])
          .toSet()
          .length;
    } else {
      fullName = '${_otherUserData?['firstName'] ?? ''} ${_otherUserData?['lastName'] ?? ''}'.trim();
      username = _otherUserData?['username'] ?? '';
      role = _otherUserData?['role'] ?? 'User';
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
                              fullName,
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
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.05,
                                  vertical: size.height * 0.005,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blue[100]!,
                                    width: size.width * 0.005,
                                  ),
                                ),
                                child: Text(
                                  role,
                                  style: GoogleFonts.inknutAntiqua(
                                    fontSize: 12 * textScale,
                                    color: const Color.fromARGB(255, 67, 145, 213),
                                  ),
                                ),
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
                    _buildStatColumn('Posts', totalPosts.toString(), onTap: null),
                    SizedBox(width: size.width * 0.08),
                    _buildStatColumn('Followers', totalFollowers.toString(), onTap: () => _showFollowersDialog(context)),
                    SizedBox(width: size.width * 0.08),
                    _buildStatColumn('Following', totalFollowing.toString(), onTap: () => _showFollowingDialog(context)),
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
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: size.width * 0.038),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Pets',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: size.width * 0.038),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Posts',
                        style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: size.width * 0.038),
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
        ],
      );

    // Wrap with appropriate layout
    if (_isOwnProfile) {
      return AppLayout(
        currentIndex: 4,
        onTabSelected: (_) {},
        child: content,
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF7496B3)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: content,
      );
    }
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
    // TODO: Replace with actual followers data from backend
    final count = _isOwnProfile ? 10 : ((_otherUserData?['totalFollowers'] as int?) ?? 5);
    final followers = List.generate(count, (index) => {
      'fullName': '${_isOwnProfile ? "Follower" : "User"} Name ${index + 1}',
      'username': '${_isOwnProfile ? "follower" : "user"}${index + 1}',
    });

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
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
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
                        'Followers',
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
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: followers.length,
                    itemBuilder: (context, index) {
                      final follower = followers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF7496B3),
                          child: Text(
                            follower['fullName']![0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          follower['username']!,
                          style: GoogleFonts.inknutAntiqua(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          follower['fullName']!,
                          style: GoogleFonts.lato(color: Colors.grey[600]),
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

  void _showFollowingDialog(BuildContext context) {
    List<Map<String, String>> following;
    
    if (_isOwnProfile) {
      final postsProvider = context.read<PostsProvider>();
      following = postsProvider.posts
          .where((post) => postsProvider.isFollowing(post['author'] as String))
          .map((post) => {
            'fullName': post['author'] as String,
            'username': (post['author'] as String).toLowerCase().replaceAll(' ', ''),
          })
          .toSet()
          .toList();
    } else {
      // Mock data for other users
      final count = (_otherUserData?['totalFollowing'] as int?) ?? 8;
      following = List.generate(count, (index) => {
        'fullName': 'Following User ${index + 1}',
        'username': 'following${index + 1}',
      });
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
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
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
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF7496B3),
                                child: Text(
                                  user['fullName']![0],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                user['username']!,
                                style: GoogleFonts.inknutAntiqua(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                user['fullName']!,
                                style: GoogleFonts.lato(color: Colors.grey[600]),
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

// Helper for onTabSelected placeholder
void _noop(int _) {}