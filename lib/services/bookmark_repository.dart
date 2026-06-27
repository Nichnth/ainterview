import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookmark.dart';

class BookmarkRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference _bookmarksRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('bookmarks');
  }

  Future<Bookmark> addBookmark(String userId, Bookmark bookmark) async {
    final docRef = _bookmarksRef(userId).doc();
    final saved = bookmark.copyWith(id: docRef.id);
    await docRef.set(saved.toMap());
    return saved;
  }

  Future<void> updateBookmarkLabel(
    String userId,
    String bookmarkId,
    String newLabel,
  ) async {
    await _bookmarksRef(userId).doc(bookmarkId).update({'label': newLabel});
  }

  Future<void> deleteBookmark(String userId, String bookmarkId) async {
    await _bookmarksRef(userId).doc(bookmarkId).delete();
  }

  Future<List<Bookmark>> fetchBookmarks(String userId) async {
    if (userId.isEmpty) return [];
    final snapshot = await _bookmarksRef(userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      return Bookmark.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }).toList();
  }

  Stream<List<Bookmark>> watchBookmarks(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _bookmarksRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Bookmark.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
