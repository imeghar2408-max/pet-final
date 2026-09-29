import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:petcare_core/petcare_core.dart';
import '../../core/api_service.dart';
import '../../core/location_service.dart';
import '../../core/theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/petcare_card.dart';
import 'provider_detail_screen.dart';

class ProviderListScreen extends StatefulWidget {
  final ServiceType serviceType;

  const ProviderListScreen({super.key, required this.serviceType});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  List<ProviderSummary> _providers = [];
  Position? _ownerPosition;
  bool _isLoading = true;
  bool _isLocationDenied = false;
  String? _error;
  bool _showMap = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndProviders();
  }

  Future<void> _fetchLocationAndProviders() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isLocationDenied = false;
    });

    final pos = await LocationService().acquirePosition(
      context: context,
      showRationaleFirst: true,
    );

    if (pos == null) {
      if (mounted) {
        setState(() {
          _isLocationDenied = true;
          _isLoading = false;
        });
      }
      return;
    }

    _ownerPosition = pos;

    try {
      final list = await UserApiService().getNearbyProviders(
        serviceType: widget.serviceType,
        lat: pos.latitude,
        lng: pos.longitude,
      );
      if (mounted) {
        setState(() {
          _providers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Set<Marker> _buildMapMarkers() {
    final markers = <Marker>{};

    if (_ownerPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('owner_pos'),
          position: LatLng(_ownerPosition!.latitude, _ownerPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    for (final p in _providers) {
    final lat = _ownerPosition != null ? _ownerPosition!.latitude + 0.005 : 0.0;
final lng = _ownerPosition != null ? _ownerPosition!.longitude + 0.005 : 0.0;
      markers.add(
        Marker(
          markerId: MarkerId(p.id),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: p.name,
            snippet: '₹${p.offeringFor(widget.serviceType)?.priceInr ?? ''} • ${p.ratingAvg}★',
            onTap: () => _openProviderDetail(p),
          ),
        ),
      );
    }

    return markers;
  }

  void _openProviderDetail(ProviderSummary provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProviderDetailScreen(
          provider: provider,
          preselectedService: widget.serviceType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PetColors.background,
      appBar: AppBar(
        title: Text('${widget.serviceType.label} Nearby'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && !_isLocationDenied && _providers.isNotEmpty)
            IconButton(
              icon: Icon(_showMap ? Icons.view_list_rounded : Icons.map_outlined),
              tooltip: _showMap ? 'List View' : 'Map View',
              onPressed: () => setState(() => _showMap = !_showMap),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(PetColors.dark),
            ),
            SizedBox(height: 16),
            Text(
              'Finding nearby verified caregivers...',
              style: TextStyle(fontSize: 14, color: PetColors.darkMuted),
            ),
          ],
        ),
      );
    }

    if (_isLocationDenied) {
      return EmptyStateView(
        icon: Icons.location_off_rounded,
        iconColor: PetColors.dark,
        title: 'Location Permission Needed',
        description:
            'PetCare needs device GPS access to find verified providers close to your home and to stream live location during walks.',
        buttonLabel: 'Enable Location',
        onButtonPressed: _fetchLocationAndProviders,
      );
    }

    if (_error != null) {
      return EmptyStateView(
        icon: Icons.error_outline_rounded,
        iconColor: PetColors.error,
        title: 'Unable to load providers',
        description: _error!,
        buttonLabel: 'Try Again',
        onButtonPressed: _fetchLocationAndProviders,
      );
    }

    if (_providers.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        iconColor: PetColors.darkLight,
        title: 'No providers available nearby right now.',
        description: 'Try another service or expand your search area.',
        buttonLabel: 'Refresh Search',
        onButtonPressed: _fetchLocationAndProviders,
      );
    }

    if (_showMap && _ownerPosition != null) {
      return Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_ownerPosition!.latitude, _ownerPosition!.longitude),
              zoom: 14,
            ),
            markers: _buildMapMarkers(),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (ctrl) => _mapController = ctrl,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _providers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final p = _providers[i];
                  final offering = p.offeringFor(widget.serviceType);
                  return GestureDetector(
                    onTap: () => _openProviderDetail(p),
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: PetColors.sageLight,
                            backgroundImage: p.profilePhoto != null ? NetworkImage(p.profilePhoto!) : null,
                            child: p.profilePhoto == null
                                ? Text(p.name[0], style: const TextStyle(fontWeight: FontWeight.w700, color: PetColors.sage))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: PetColors.dark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.ratingAvg} ★ (${p.ratingCount})',
                                  style: const TextStyle(fontSize: 12, color: PetColors.darkMuted),
                                ),
                                const SizedBox(height: 4),
                                if (offering != null)
                                  Text(
                                    '₹${offering.priceInr} / ${offering.durationMin} mins',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: PetColors.dark),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: PetColors.dark,
      onRefresh: _fetchLocationAndProviders,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _providers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final provider = _providers[i];
          final offering = provider.offeringFor(widget.serviceType);

          return PetCareCard(
            hasShadow: true,
            onTap: () => _openProviderDetail(provider),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: PetColors.sageLight,
                      backgroundImage: provider.profilePhoto != null && provider.profilePhoto!.isNotEmpty
                          ? NetworkImage(provider.profilePhoto!)
                          : null,
                      child: provider.profilePhoto == null || provider.profilePhoto!.isEmpty
                          ? Text(
                              provider.name.isNotEmpty ? provider.name[0].toUpperCase() : 'P',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: PetColors.sage,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  provider.name,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: PetColors.dark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.verified_rounded, color: PetColors.sage, size: 16),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: PetColors.amberLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 13, color: PetColors.amber),
                                    const SizedBox(width: 3),
                                    Text(
                                      provider.ratingCount > 0
                                          ? provider.ratingAvg.toStringAsFixed(1)
                                          : 'New',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: PetColors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (provider.ratingCount > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '(${provider.ratingCount})',
                                  style: const TextStyle(fontSize: 12, color: PetColors.darkMuted),
                                ),
                              ],
/*
if (provider.distanceKm != null) ...[
  Text(
    '•  ${provider.distanceKm} km away',
    style: const TextStyle(fontSize: 12, color: PetColors.darkMuted),
  ),
],
*/
                              if (provider.yearsExperience != null && provider.yearsExperience! > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '•  ${provider.yearsExperience} yrs exp',
                                  style: const TextStyle(fontSize: 12, color: PetColors.darkMuted),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (offering != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${offering.priceInr}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: PetColors.dark,
                            ),
                          ),
                          Text(
                            '${offering.durationMin} mins',
                            style: const TextStyle(fontSize: 11, color: PetColors.darkLight),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (provider.bio != null && provider.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    provider.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: PetColors.darkMuted,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PetColors.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: PetColors.success),
                          SizedBox(width: 5),
                          Text(
                            'Available',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: PetColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'View & Book',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: PetColors.dark,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: PetColors.dark),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
