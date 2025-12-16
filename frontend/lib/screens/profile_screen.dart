import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/app_layout.dart';
import 'user_settings.dart' as user_settings;
import 'dashboard_screen.dart';
import '../user_provider.dart';
import '../pet_provider.dart' as pet_provider;
import '../posts_provider.dart';
import 'pet_list.dart' as pet_list;
import 'all_pets_screen.dart';
import 'community_post_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? otherUsername; // null means viewing own profile
  final bool shouldAnimate; // whether to use slide-in animation

  const ProfileScreen({
    super.key,
    this.otherUsername,
    this.shouldAnimate = true,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  Map<String, dynamic>? _otherUserData;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool get _isOwnProfile => widget.otherUsername == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController?.addListener(() {
      if (mounted) setState(() {});
    });

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.shouldAnimate) {
        _slideController.forward(from: 0.0);
      }
    });

    final isOwn = widget.otherUsername == null;
    debugPrint(
        'ProfileScreen opened: otherUsername=${widget.otherUsername}, _isOwnProfile=$isOwn');
    if (!isOwn) {
      _loadOtherUserData();
    } else {
      // Fetch pets for own profile after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<pet_provider.PetProvider>().fetchPets();
        }
      });
    }
  }

  // Fetch other user's profile from UserProvider
  Future<void> _loadOtherUserData() async {
    if (widget.otherUsername == null) return;

    try {
      final userProvider = context.read<UserProvider>();
      final profile =
          await userProvider.fetchPublicProfile(widget.otherUsername!);

      if (profile != null && mounted) {
        // Fetch other user's pets
        final pets = await userProvider.fetchOtherUserPets(profile.userId);

        setState(() {
          _otherUserData = {
            'user_id': profile.userId,
            'username': profile.username,
            'name': profile.name,
            'bio': profile.bio,
            'photoUrl': profile.photoUrl,
            'roles': profile.roles,
            'followerIds': profile.followers,
            'followingIds': profile.following,
            'totalFollowers': profile.followers.length,
            'totalFollowing': profile.following.length,
            'pets': pets,
            'totalPosts': 0,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading other user data: $e');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    await _slideController.reverse();

    if (!mounted) return false;

    final navigator = Navigator.of(context);

    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }

    return false;
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : const Color(0xFF394957),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsTab() {
    final size = MediaQuery.of(context).size;

    // When viewing another user's profile
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
              // Create a temporary Pet object with safe defaults in case data is missing
              final displayPet = pet_provider.Pet(
                petId: 'mock_$index',
                userId: 'mock_user',
                name: (petMap['name'] ?? 'Unknown').toString(),
                species: (petMap['species'] ?? 'Dog').toString(),
                breed: (petMap['breed'] ?? 'Unknown').toString(),
                birthday:
                  (petMap['dob'] ?? petMap['birthday'])?.toString() ?? '',
                weight: (petMap['weight'] as num?)?.toDouble() ?? 0.0,
                imageUrl: petMap['imageUrl']?.toString() ?? '',
                status: petMap['status']?.toString() ?? 'owned',
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
        final currentUsername =
            context.read<UserProvider>().user?.username ?? '';
        final targetAuthorName =
            _isOwnProfile ? currentUsername : (widget.otherUsername ?? '');

        // Only show posts where author name matches
        final userPosts = postsProvider.posts
            .where((post) => post.authorName == targetAuthorName)
            .toList();

        if (userPosts.isEmpty) {
          return Center(
            child: Text(
              'No posts yet.',
              style: GoogleFonts.lato(
                fontSize: size.width * 0.04,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : const Color(0xFF394957),
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF394957),
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    Text(
                      post.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lato(
                        fontSize: size.width * 0.038,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF394957),
                      ),
                    ),
                    SizedBox(height: size.height * 0.015),
                    if (post.categories.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: post.categories.map((cat) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.03,
                              vertical: size.height * 0.007,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF3A5A75)
                                  : const Color(0xFFEEF7FB),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF4A6B85)
                                    : const Color(0xFFBCD9EC),
                              ),
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.lato(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF7496B3),
                                fontWeight: FontWeight.w600,
                                fontSize: size.width * 0.03,
                              ),
                            ),
                          );
                        }).toList(),
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
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF394957),
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
                              Icon(
                                Icons.comment_outlined,
                                size: size.width * 0.045,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF7496B3),
                              ),
                              SizedBox(width: size.width * 0.01),
                              Text(
                                '${post.commentCount}',
                                style: GoogleFonts.lato(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : const Color(0xFF394957),
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
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);

    // Get user data based on profile type
    String name;
    String username;
    String? profileImageUrl;
    List<String> roles;
    int totalPosts, totalFollowers, totalFollowing;

    if (_isOwnProfile) {
      final appUser = context.watch<UserProvider>().user;
      name = appUser?.name ?? 'Your Name';
      username = appUser?.username ?? 'username';
      profileImageUrl = appUser?.photoUrl;
      final rolesList = appUser?.roles;
      roles =
          (rolesList == null || rolesList.isEmpty) ? ['Visitor'] : rolesList;

      final postsProvider = context.watch<PostsProvider>();
      final currentUsername = username;
      totalPosts = postsProvider.posts
          .where((post) => post.authorName == currentUsername)
          .length;

      totalFollowers = appUser?.followers.length ?? 0;
      totalFollowing = appUser?.following.length ?? 0;
    } else {
      name = _otherUserData?['name'] ?? '';
      username = _otherUserData?['username'] ?? '';
      profileImageUrl = _otherUserData?['photoUrl'];
      final rolesList = _otherUserData?['roles'] as List<dynamic>?;
      roles = (rolesList == null || rolesList.isEmpty)
          ? ['Visitor']
          : rolesList.map((r) => r.toString()).toList();
      final postsProvider = context.watch<PostsProvider>();
      final otherUsername = widget.otherUsername ?? '';
      totalPosts = postsProvider.posts
          .where((post) => post.authorName == otherUsername)
          .length;
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
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: avatarSize / 2,
                          backgroundColor: const Color(0xFF7496B3),
                          // If URL exists and is not empty, load image. Otherwise null.
                          backgroundImage: (profileImageUrl != null &&
                                  profileImageUrl.isNotEmpty)
                              ? NetworkImage(profileImageUrl)
                              : null,
                          // Only show the Icon child if we DON'T have an image
                          child: (profileImageUrl == null ||
                                  profileImageUrl.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: avatarSize * 0.5,
                                )
                              : null,
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
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade300
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 28,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: roles.map((role) {
                                      // Color mapping for each role with dark mode support
                                      Color tagColor;
                                      switch (role.toLowerCase()) {
                                        case 'owner':
                                          tagColor =
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF1F4A5F)
                                                  : const Color(0xFF2C5F7F);
                                          break;
                                        case 'organizer':
                                          tagColor =
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF3A5A75)
                                                  : const Color(0xFF5A8DB3);
                                          break;
                                        case 'foster':
                                          tagColor =
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF5F8FA8)
                                                  : const Color.fromARGB(
                                                      255, 118, 178, 230);
                                          break;
                                        case 'visitor':
                                          tagColor =
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF2A4A65)
                                                  : const Color.fromARGB(
                                                      255, 156, 201, 234);
                                          break;
                                        default:
                                          tagColor =
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? const Color(0xFF4A6B85)
                                                  : const Color(0xFF7496B3);
                                      }

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: size.width * 0.04,
                                            vertical: size.height * 0.005,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tagColor,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Center(
                                            child: Text(
                                              role.isNotEmpty
                                                  ? role[0].toUpperCase() +
                                                      role
                                                          .substring(1)
                                                          .toLowerCase()
                                                  : role,
                                              style: GoogleFonts.inknutAntiqua(
                                                fontSize: 12 * textScale,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              // Follow button for other users' profiles (smaller, inline)
                              if (!_isOwnProfile) ...[
                                const SizedBox(height: 16),
                                Consumer<UserProvider>(
                                  builder: (context, userProvider, _) {
                                    final otherUserId =
                                        _otherUserData?['user_id'] as String?;
                                    final isFollowing = otherUserId != null &&
                                        (userProvider.user?.following
                                                .contains(otherUserId) ??
                                            false);

                                    return GestureDetector(
                                      onTap: () async {
                                        if (otherUserId == null) return;
                                        try {
                                          await userProvider
                                              .toggleFollow(otherUserId);
                                          await _loadOtherUserData();
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Failed to update follow status: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isFollowing
                                              ? const Color(0xFF7496B3)
                                                  .withOpacity(0.3)
                                              : Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFF7496B3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          isFollowing ? 'Following' : 'Follow',
                                          style: GoogleFonts.lato(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF7496B3),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
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
                  bottom: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF3A3A3A)
                        : Colors.grey[300]!,
                    width: 1,
                  ),
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
                size: size.width * 0.08,
                color: const Color(0xFF7496B3),
              ),
              tooltip: 'User Settings',
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const user_settings.UserSettingsScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);
                      return SlideTransition(
                          position: offsetAnimation, child: child);
                    },
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
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF4A6B85)
                  : const Color(0xFF7496B3),
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
                      .map((p) =>
                          pet_list.Pet(name: p.name, imageUrl: p.imageUrl))
                      .toList();
                  name = userProv.user?.name ?? 'Your name';
                } else {
                  final otherPets =
                      (_otherUserData?['pets'] as List<dynamic>?) ?? [];
                  displayPets = otherPets
                      .map((e) => pet_list.Pet(
                            name: e['name']?.toString() ?? 'Pet',
                            imageUrl: e['image_url']?.toString() ?? '',
                          ))
                      .toList();
                  final first = _otherUserData?['firstName']?.toString() ?? '';
                  final last = _otherUserData?['lastName']?.toString() ?? '';
                  name = '$first $last'.trim();
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
      showBackButton: !_isOwnProfile,
      onTabSelected: (_) {},
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) {
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: widget.shouldAnimate
            ? Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF121212)
                    : Colors.white,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: content,
                ),
              )
            : Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF121212)
                    : Colors.white,
                child: content,
              ),
      ),
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF394957),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: size.width * 0.035,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey[600],
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
    final userProvider = context.read<UserProvider>();
    final isOwn = _isOwnProfile;

    Future<List<Map<String, dynamic>>> fetchFollowers() async {
      if (isOwn) {
        final user = userProvider.user;
        final followerIds = user?.followers ?? [];
        if (followerIds.isEmpty) return [];
        return await userProvider.fetchUsersByIds(followerIds);
      } else {
        // For other users, get follower IDs from _otherUserData
        final followerIds =
            (_otherUserData?['followerIds'] as List<String>?) ?? [];
        if (followerIds.isEmpty) return [];
        return await userProvider.fetchUsersByIds(followerIds);
      }
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3A3A3A)
                    : Colors.grey.shade300,
              ),
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
                        'Followers',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inknutAntiqua(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF394957),
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
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchFollowers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Error loading users',
                                style: GoogleFonts.lato(color: Colors.red)));
                      }

                      final followers = snapshot.data ?? [];

                      if (followers.isEmpty) {
                        return Center(
                          child: Text(
                            'No followers yet.',
                            style: GoogleFonts.lato(color: Colors.grey[600]),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: followers.length,
                        itemBuilder: (context, index) {
                          final user = followers[index];
                          final name = user['name'] ?? 'Unknown';
                          final username = user['username'] ?? '';
                          final visitorUserId = user['user_id'] as String?;
                          final photoUrl = user['photo_url'] as String?;
                          final currentUserId = userProvider.user?.userId;

                          return ListTile(
                            onTap: () {
                              Navigator.of(context).pop(); // Close dialog
                              // Check if this is the current user's own account
                              final isOwnAccount = currentUserId != null &&
                                  visitorUserId == currentUserId;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    otherUsername:
                                        isOwnAccount ? null : username,
                                    shouldAnimate: false,
                                  ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF7496B3),
                              backgroundImage:
                                  (photoUrl != null && photoUrl.isNotEmpty)
                                      ? NetworkImage(photoUrl)
                                      : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            title: Text(
                              username,
                              style: GoogleFonts.inknutAntiqua(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              name,
                              style: GoogleFonts.lato(color: Colors.grey[600]),
                            ),
                          );
                        },
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
    final userProvider = context.read<UserProvider>();
    final isOwn = _isOwnProfile;

    Future<List<Map<String, dynamic>>> fetchFollowing() async {
      if (isOwn) {
        final user = userProvider.user;
        final followingIds = user?.following ?? [];
        if (followingIds.isEmpty) return [];
        return await userProvider.fetchUsersByIds(followingIds);
      } else {
        // For other users, get following IDs from _otherUserData
        final followingIds =
            (_otherUserData?['followingIds'] as List<String>?) ?? [];
        if (followingIds.isEmpty) return [];
        return await userProvider.fetchUsersByIds(followingIds);
      }
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3A3A3A)
                    : Colors.grey.shade300,
              ),
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : const Color(0xFF394957),
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
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchFollowing(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                            child: Text('Error loading users',
                                style: GoogleFonts.lato(color: Colors.red)));
                      }

                      final following = snapshot.data ?? [];

                      if (following.isEmpty) {
                        return Center(
                          child: Text(
                            'Not following anyone yet.',
                            style: GoogleFonts.lato(color: Colors.grey[600]),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: following.length,
                        itemBuilder: (context, index) {
                          final user = following[index];
                          final name = user['name'] ?? 'Unknown';
                          final username = user['username'] ?? '';
                          final visitedUserId = user['user_id'] as String?;
                          final photoUrl = user['photo_url'] as String?;
                          final currentUserId = userProvider.user?.userId;

                          return ListTile(
                            onTap: () {
                              Navigator.of(context).pop(); // Close dialog
                              // Check if this is the current user's own account
                              final isOwnAccount = currentUserId != null &&
                                  visitedUserId == currentUserId;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    otherUsername:
                                        isOwnAccount ? null : username,
                                    shouldAnimate: false,
                                  ),
                                ),
                              );
                            },
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF7496B3),
                              backgroundImage:
                                  (photoUrl != null && photoUrl.isNotEmpty)
                                      ? NetworkImage(photoUrl)
                                      : null,
                              child: (photoUrl == null || photoUrl.isEmpty)
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            title: Text(
                              username,
                              style: GoogleFonts.inknutAntiqua(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              name,
                              style: GoogleFonts.lato(color: Colors.grey[600]),
                            ),
                          );
                        },
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
