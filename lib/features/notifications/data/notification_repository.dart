
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/notification_model.dart';

class NotificationRepository {
NotificationRepository({
FirebaseFirestore? firestore,
FirebaseAuth? auth,
})  : _firestore = firestore ?? FirebaseFirestore.instance,
_auth = auth ?? FirebaseAuth.instance;

final FirebaseFirestore _firestore;
final FirebaseAuth _auth;

String? get _userId => _auth.currentUser?.uid;

CollectionReference<Map<String, dynamic>> _notifications(
String userId,
) {
return _firestore
    .collection('users')
    .doc(userId)
    .collection('notifications');
}

/// Listen to the signed-in user's notifications.
Stream<List<NotificationModel>> watchNotifications() {
final userId = _userId;

if (userId == null) {
return Stream.value(<NotificationModel>[]);
}

return _notifications(userId)
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map(
(doc) => NotificationModel.fromMap(
doc.id,
doc.data(),
),
)
    .toList(),
);
}

/// Save a notification for a user.
Future<void> saveNotification({
required String userId,
required String title,
required String body,
required String bookingId,
String type = 'booking_update',
}) async {
final ref = _notifications(userId).doc();

await ref.set({
'title': title,
'body': body,
'type': type,
'bookingId': bookingId,
'isRead': false,
'createdAt': FieldValue.serverTimestamp(),
});
}

/// Mark one notification as read.
Future<void> markAsRead(String notificationId) async {
final userId = _userId;
if (userId == null) return;

await _notifications(userId)
    .doc(notificationId)
    .update({'isRead': true});
}

/// Mark all notifications as read.
Future<void> markAllAsRead() async {
final userId = _userId;
if (userId == null) return;

final snapshot = await _notifications(userId)
    .where('isRead', isEqualTo: false)
    .get();

if (snapshot.docs.isEmpty) return;

final batch = _firestore.batch();

for (final doc in snapshot.docs) {
batch.update(doc.reference, {'isRead': true});
}

await batch.commit();
}
}
