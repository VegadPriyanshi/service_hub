
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
final String id;
final String title;
final String body;
final String type;
final String bookingId;
final bool isRead;
final DateTime? createdAt;

const NotificationModel({
required this.id,
required this.title,
required this.body,
required this.type,
required this.bookingId,
required this.isRead,
this.createdAt,
});

factory NotificationModel.fromMap(
String id,
Map<String, dynamic> data,
) {
final timestamp = data['createdAt'];

return NotificationModel(
id: id,
title: (data['title'] ?? '').toString(),
body: (data['body'] ?? '').toString(),
type: (data['type'] ?? 'booking_update').toString(),
bookingId: (data['bookingId'] ?? '').toString(),
isRead: data['isRead'] == true,
createdAt: timestamp is Timestamp
? timestamp.toDate()
    : null,
);
}

Map<String, dynamic> toMap() {
return {
'title': title,
'body': body,
'type': type,
'bookingId': bookingId,
'isRead': isRead,
'createdAt': FieldValue.serverTimestamp(),
};
}
}
