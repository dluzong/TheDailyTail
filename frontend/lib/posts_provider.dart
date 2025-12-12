import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

// --- MODEL ---

class Post {
  final int postId;
  final String userId;
  final String authorName;
  final String authorPhoto;
  final String title;
  final String content;
  final List<String> categories;
  final String createdTs;
  final bool isLiked;
  final int likesCount;
  final int commentCount;
  // We keep the raw array for optimistic updates
  final List<String> likesArray;

  Post({
    required this.postId,
    required this.userId,
    required this.authorName,
    required this.authorPhoto,
    required this.title,
    required this.content,
    required this.categories,
    required this.createdTs,
    required this.isLiked,
    required this.likesCount,
    required this.commentCount,
    required this.likesArray,
  });

  factory Post.fromMap(Map<String, dynamic> map, String? currentUserId) {
    final authorData = map['users'] as Map<String, dynamic>?;

    // Parse Likes (Array of UUIDs)
    final List<dynamic> rawLikes = map['likes'] ?? [];
    final List<String> likesList = rawLikes.map((e) => e.toString()).toList();
    final bool liked =
        currentUserId != null && likesList.contains(currentUserId);

    // Parse Comments count from joined table
    final commentsData = map['comments'] as List<dynamic>?;
    final int commentCount = commentsData != null && commentsData.isNotEmpty
        ? (commentsData[0]['count'] as int? ?? 0)
        : 0;

    // Parse Categories (Array of Strings)
    final List<dynamic> rawCategories = map['category'] ?? [];
    final List<String> categoriesList =
        rawCategories.map((e) => e.toString()).toList();
    if (categoriesList.isEmpty) {
      categoriesList.add('General');
    }

    return Post(
      postId: map['post_id'],
      userId: map['user_id'] ?? '',
      authorName: authorData?['username'] ?? 'Unknown',
      authorPhoto: authorData?['photo_url'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      categories: categoriesList,
      createdTs: timeago.format(DateTime.parse(map['created_ts'])),
      isLiked: liked,
      likesCount: likesList.length,
      commentCount: commentCount,
      likesArray: likesList,
    );
  }

  // Helper for optimistic updates
  Post copyWith({
    bool? isLiked,
    int? likesCount,
    List<String>? likesArray,
    int? commentCount,
  }) {
    return Post(
      postId: postId,
      userId: userId,
      authorName: authorName,
      authorPhoto: authorPhoto,
      title: title,
      content: content,
      categories: categories,
      createdTs: createdTs,
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      commentCount: commentCount ?? this.commentCount,
      likesArray: likesArray ?? this.likesArray,
    );
  }
}

// --- PROVIDER ---

class PostsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true; // For pagination

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;

  // Pagination constants
  static const int _pageSize = 10;

  // Fetch initial posts (Refresh)
  Future<void> fetchPosts() async {
    _isLoading = true;
    _hasMore = true;
    notifyListeners();

    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from('posts')
          .select('''
        *,
        users:user_id (username, photo_url),
        comments(count)
      ''')
          .order('created_ts', ascending: false)
          .range(0, _pageSize - 1); // Fetch first 10

      final data = List<Map<String, dynamic>>.from(response);
      _posts = data.map((m) => Post.fromMap(m, currentUserId)).toList();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load More (Infinite Scroll)
  Future<void> loadMorePosts() async {
    if (!_hasMore || _isLoading) return;

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final start = _posts.length;
      final end = start + _pageSize - 1;

      final response = await _supabase.from('posts').select('''
        *,
        users:user_id (username, photo_url),
        comments(count)
      ''').order('created_ts', ascending: false).range(start, end);

      final data = List<Map<String, dynamic>>.from(response);

      if (data.isEmpty) {
        _hasMore = false;
      } else {
        final newPosts =
            data.map((m) => Post.fromMap(m, currentUserId)).toList();
        _posts.addAll(newPosts);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading more posts: $e');
    }
  }

  // --- LIKE LOGIC ---

  Future<void> toggleLike(int index) async {
    final post = _posts[index];
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final newLikesArray = List<String>.from(post.likesArray);
    final bool newLikedState = !post.isLiked;

    // 1. Optimistic Calculation
    if (newLikedState) {
      newLikesArray.add(currentUserId);
    } else {
      newLikesArray.remove(currentUserId);
    }

    // 2. Update Local State Immediately
    _posts[index] = post.copyWith(
      isLiked: newLikedState,
      likesCount: newLikesArray.length,
      likesArray: newLikesArray,
    );
    notifyListeners();

    // 3. Sync to DB
    try {
      await _supabase
          .from('posts')
          .update({'likes': newLikesArray}).eq('post_id', post.postId);
    } catch (e) {
      debugPrint("Like failed, reverting: $e");
      // Revert locally if DB fails
      _posts[index] = post; // Reverts to original object
      notifyListeners();
    }
  }

  // --- COMMENT LOGIC ---

  void incrementCommentCount(int index) {
    if (index < 0 || index >= _posts.length) return;
    final post = _posts[index];
    _posts[index] = post.copyWith(commentCount: post.commentCount + 1);
    notifyListeners();
  }

  void decrementCommentCount(int index) {
    if (index < 0 || index >= _posts.length) return;
    final post = _posts[index];
    if (post.commentCount > 0) {
      _posts[index] = post.copyWith(commentCount: post.commentCount - 1);
      notifyListeners();
    }
  }

  // --- CREATE POST ---

  Future<void> createPost(
      String title, String content, List<String> categories) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('posts').insert({
      'user_id': user.id,
      'title': title,
      'content': content,
      'category': categories,
      'likes': [],
      'comments': [],
    });

    // Refresh to show the new post at the top
    await fetchPosts();
  }
}
