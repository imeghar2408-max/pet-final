import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:petcare_core/petcare_core.dart';

class UserApiService {
  static final UserApiService _instance = UserApiService._internal();
  factory UserApiService() => _instance;

  final ApiClient _client;

  UserApiService._internal() : _client = ApiClient(baseUrl: ApiConfig.baseUrl);

  ApiClient get client => _client;

  List<dynamic> _extractList(dynamic rawData) {
    if (rawData == null) return [];
    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {
        return [];
      }
    }
    if (rawData is List) return rawData;
    if (rawData is Map) {
      if (rawData['data'] is List) return rawData['data'] as List;
      if (rawData['providers'] is List) return rawData['providers'] as List;
      if (rawData['pets'] is List) return rawData['pets'] as List;
      if (rawData['bookings'] is List) return rawData['bookings'] as List;
      if (rawData['complaints'] is List) return rawData['complaints'] as List;
    }
    return [];
  }

  Map<String, dynamic> _extractMap(dynamic rawData) {
    if (rawData == null) return {};
    if (rawData is String) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {
        return {};
      }
    }
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    return {};
  }

  /// Check current user profile from backend
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await _client.post('/auth/me');
      if (res.data == null) return null;
      return _extractMap(res.data);
    } catch (_) {
      return null;
    }
  }

  /// Register new pet owner profile after first Firebase Phone sign-in
  Future<Map<String, dynamic>> registerPetOwner({
    required String name,
    String? email,
  }) async {
    final res = await _client.post(
      '/auth/register',
      data: {
        'role': 'PET_OWNER',
        'name': name.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },
    );
    return _extractMap(res.data);
  }

  /// Fetch all pets for the authenticated owner
  Future<List<Pet>> getPets() async {
    final res = await _client.get('/users/pets');
    final list = _extractList(res.data);
    return list.map((e) => Pet.fromJson(_extractMap(e))).toList();
  }

  /// Add a pet to owner's profile
  Future<Pet> addPet({
    required String name,
    required String species,
    String? breed,
    int? age,
    double? weightKg,
    String? notes,
    String? photoUrl,
  }) async {
    final res = await _client.post(
      '/users/pets',
      data: {
        'name': name.trim(),
        'species': species.trim(),
        if (breed != null && breed.trim().isNotEmpty) 'breed': breed.trim(),
        if (age != null) 'age': age,
        if (weightKg != null) 'weightKg': weightKg,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        if (photoUrl != null && photoUrl.trim().isNotEmpty) 'photoUrl': photoUrl.trim(),
      },
    );
    return Pet.fromJson(_extractMap(res.data));
  }

  /// Discover verified providers offering a specific service near owner's actual location
  Future<List<ProviderSummary>> getNearbyProviders({
    ServiceType? serviceType,
    required double lat,
    required double lng,
  }) async {
    final query = <String, dynamic>{
      'lat': lat.toString(),
      'lng': lng.toString(),
    };
    if (serviceType != null) {
      query['serviceType'] = backendEnumName(serviceType.name);
    }
    final res = await _client.get('/providers/nearby', query: query);
    final list = _extractList(res.data);
    return list.map((e) => ProviderSummary.fromJson(_extractMap(e))).toList();
  }

  /// Submit a real booking request
  Future<Booking> createBooking({
    required String providerId,
    required String petId,
    required ServiceType serviceType,
    required DateTime scheduledAt,
    required String addressText,
    required double lat,
    required double lng,
    String? notes,
  }) async {
    final res = await _client.post(
      '/bookings',
      data: {
        'providerId': providerId,
        'petId': petId,
        'serviceType': backendEnumName(serviceType.name),
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'addressText': addressText.trim(),
        'lat': lat,
        'lng': lng,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return Booking.fromJson(_extractMap(res.data));
  }

  /// Fetch bookings for current owner
  Future<List<Booking>> getMyBookings() async {
    final res = await _client.get('/bookings/mine');
    final list = _extractList(res.data);
    return list.map((e) => Booking.fromJson(_extractMap(e))).toList();
  }

  /// Update the live safe zone for an active booking
  Future<void> updateSafeZone({
    required String bookingId,
    required double lat,
    required double lng,
    required int radiusM,
  }) async {
    await _client.post(
      '/bookings/$bookingId/safe-zone',
      data: {
        'lat': lat,
        'lng': lng,
        'radiusM': radiusM,
        'safeZoneLat': lat,
        'safeZoneLng': lng,
        'safeZoneRadiusM': radiusM,
      },
    );
  }

  /// Rate and review provider after job completion
  Future<void> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    await _client.post(
      '/bookings/$bookingId/review',
      data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      },
    );
  }

  /// Create Razorpay payment order
  Future<Map<String, dynamic>> createPaymentOrder(String bookingId) async {
    final res = await _client.post('/payments/create-order', data: {'bookingId': bookingId});
    return _extractMap(res.data);
  }

  /// Verify Razorpay payment
  Future<Map<String, dynamic>> verifyPayment({
    required String bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final res = await _client.post(
      '/payments/verify',
      data: {
        'bookingId': bookingId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
    return _extractMap(res.data);
  }

  /// Submit support complaint
  Future<Complaint> submitComplaint({
    required String subject,
    required String description,
    required ComplaintCategory category,
    String? bookingId,
  }) async {
    final res = await _client.post(
      '/complaints',
      data: {
        'subject': subject.trim(),
        'description': description.trim(),
        'category': backendEnumName(category.name),
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
      },
    );
    return Complaint.fromJson(_extractMap(res.data));
  }

  /// List user's support complaints
  Future<List<Complaint>> getMyComplaints() async {
    final res = await _client.get('/complaints/mine');
    final list = _extractList(res.data);
    return list.map((e) => Complaint.fromJson(_extractMap(e))).toList();
  }
}