import 'package:dio/dio.dart';
import 'package:petcare_core/petcare_core.dart';

class UserApiService {
  static final UserApiService _instance = UserApiService._internal();
  factory UserApiService() => _instance;

  final ApiClient _client;

  UserApiService._internal() : _client = ApiClient(baseUrl: ApiConfig.baseUrl);

  ApiClient get client => _client;

  /// Check current user profile from backend
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await _client.post('/auth/me');
      if (res.data == null) return null;
      return res.data as Map<String, dynamic>;
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
    return res.data as Map<String, dynamic>;
  }

  /// Fetch all pets for the authenticated owner
  Future<List<Pet>> getPets() async {
    final res = await _client.get('/users/pets');
    final list = res.data as List;
    return list.map((e) => Pet.fromJson(e as Map<String, dynamic>)).toList();
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
    return Pet.fromJson(res.data as Map<String, dynamic>);
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
    final list = res.data as List;
    return list.map((e) => ProviderSummary.fromJson(e as Map<String, dynamic>)).toList();
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
    return Booking.fromJson(res.data as Map<String, dynamic>);
  }

  /// Fetch bookings for current owner
  Future<List<Booking>> getMyBookings() async {
    final res = await _client.get('/bookings/mine');
    final list = res.data as List;
    return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
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
    return res.data as Map<String, dynamic>;
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
    return res.data as Map<String, dynamic>;
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
    return Complaint.fromJson(res.data as Map<String, dynamic>);
  }

  /// List user's support complaints
  Future<List<Complaint>> getMyComplaints() async {
    final res = await _client.get('/complaints/mine');
    final list = res.data as List;
    return list.map((e) => Complaint.fromJson(e as Map<String, dynamic>)).toList();
  }
}
