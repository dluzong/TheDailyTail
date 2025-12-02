import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostsProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get posts => _posts;
  bool get isLoading => _isLoading;

  Future<void> fetchPosts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      // Select Posts + Join Users table to get Author Name/Photo
      // We also get a count of comments (approximate via array length or separate query)
      final response = await _supabase.from('posts').select('''
        *,
        users:user_id (username, photo_url)
      ''').order('created_ts', ascending: false);

      _posts = List<Map<String, dynamic>>.from(response).map((data) {
        final authorData = data['users'] as Map<String, dynamic>?;
        
        // Parse the 'likes' array (List of UUIDs)
        final List<dynamic> likesArray = data['likes'] ?? [];
        final bool isLiked = currentUserId != null && likesArray.contains(currentUserId);
        
        // Parse the 'comments' array (if you are using the array column)
        // OR if you switched to table, we would do a count. 
        // Based on your schema having 'comments ARRAY', we use that size.
        final List<dynamic> commentsArray = data['comments'] ?? [];

        return {
          'post_id': data['post_id'],
          'user_id': data['user_id'],
          'author': authorData?['username'] ?? 'Unknown',
          'author_photo': authorData?['photo_url'],
          'title': data['title'] ?? 'No Title',
          'content': data['content'] ?? '',
          'category': data['category'] ?? 'General',
          'timeAgo': timeago.format(DateTime.parse(data['created_ts'])),
          'likes_count': likesArray.length,
          'likes_array': likesArray, // Keep for updates
          'comment_count': commentsArray.length,
          'liked': isLiked,
        };
      }).toList();

    } catch (e) {
      debugPrint('Error fetching posts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- LIKE LOGIC (Using Array) ---
  
  Future<void> toggleLike(int index) async {
    final post = _posts[index];
    final int postId = post['post_id'];
    final String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Create a copy of the list so we can modify it
    final List<dynamic> currentLikes = List.from(post['likes_array']);
    final bool wasLiked = post['liked'];

    // 1. Optimistic Update (Update UI instantly)
    if (wasLiked) {
      currentLikes.remove(userId);
    } else {
      currentLikes.add(userId);
    }
    
    // Update local state
    _posts[index]['liked'] = !wasLiked;
    _posts[index]['likes_count'] = currentLikes.length;
    _posts[index]['likes_array'] = currentLikes;
    notifyListeners();

    // 2. Send to DB (Background)
    try {
      await _supabase.from('posts').update({
        'likes': currentLikes // Send the updated array
      }).eq('post_id', postId);
    } catch (e) {
      debugPrint("Like failed, reverting: $e");
      // Revert if API fails
      await fetchPosts(); 
    }
  }

  // --- CREATE POST ---

  Future<void> createPost(String title, String content, String category) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('posts').insert({
      'user_id': user.id,
      'title': title,
      'content': content,
      'category': category,
      'likes': [], 
      'comments': [], 
    });
    
    await fetchPosts(); // Refresh feed to show new post
  }
}