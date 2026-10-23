
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/service_model.dart';

class ServiceRepository {
  ServiceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _servicesCollection =>
      _firestore.collection('services');

  Future<String> addService(ServiceModel service) async {
    final doc = _servicesCollection.doc();

    await doc.set({
      ...service.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<ServiceModel?> getServiceById(String serviceId) async {
    final snapshot = await _servicesCollection.doc(serviceId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return ServiceModel.fromMap(
      snapshot.id,
      snapshot.data()!,
    );
  }

  Future<List<ServiceModel>> getProviderServices(
      String providerId,
      ) async {
    final snapshot = await _servicesCollection
        .where('providerId', isEqualTo: providerId)
        .get();

    return snapshot.docs
        .map((doc) => ServiceModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<ServiceModel>> getActiveServices() async {
    final snapshot = await _servicesCollection
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => ServiceModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> updateService(ServiceModel service) async {
    if (service.id.isEmpty) {
      throw ArgumentError('Service ID cannot be empty.');
    }

    await _servicesCollection.doc(service.id).update(
      service.toMap()
        ..remove('createdAt'),
    );
  }

  Future<void> deleteService(String serviceId) async {
    if (serviceId.isEmpty) {
      throw ArgumentError('Service ID cannot be empty.');
    }

    await _servicesCollection.doc(serviceId).delete();
  }
}
