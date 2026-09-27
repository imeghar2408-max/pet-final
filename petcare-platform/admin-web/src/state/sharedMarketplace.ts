import { useState, useEffect } from 'react';

export interface ProviderDocumentItem {
  id: string;
  documentType: string;
  title: string;
  issuingOrg?: string;
  documentUrl: string;
  issueDate?: string;
  expiryDate?: string;
  status: string;
  rejectionReason?: string;
}

export interface MarketplaceProvider {
  id: string;
  name: string;
  phone: string;
  email: string;
  profilePhoto?: string;
  dateOfBirth?: string;
  addressCity?: string;
  emergencyContact?: string;
  bio: string;
  yearsExperience: number;
  serviceRadiusKm: number;
  skills?: string;
  isAvailable: boolean;
  ratingAvg: number;
  ratingCount: number;
  verificationStatus: 'DRAFT' | 'SUBMITTED' | 'UNDER_REVIEW' | 'APPROVED' | 'REJECTED' | 'SUSPENDED';
  rejectionReason?: string;
  suspensionReason?: string;
  idDocumentUrl?: string;
  lat: number;
  lng: number;
  services: Array<{ type: string; label: string; priceInr: number; durationMin: number; enabled: boolean }>;
  documents: ProviderDocumentItem[];
}

export interface MarketplaceBooking {
  id: string;
  petId: string;
  petName: string;
  species: string;
  breed?: string;
  providerId: string;
  providerName: string;
  providerPhoto?: string;
  providerRatingAvg: number;
  providerRatingCount: number;
  serviceType: string;
  scheduledAt: string;
  addressText: string;
  lat: number;
  lng: number;
  priceInr: number;
  status: 'REQUESTED' | 'ACCEPTED' | 'IN_PROGRESS' | 'COMPLETED' | 'REJECTED';
  declineReason?: string;
  notes?: string;
  ownerName: string;
  ownerPhone: string;
  safeZoneLat: number;
  safeZoneLng: number;
  safeZoneRadiusM: number;
  paymentStatus: 'UNPAID' | 'PAID';
  rating?: number;
  reviewComment?: string;
  serviceStartedAt?: number;
  serviceCompletedAt?: number;
  serviceDurationSeconds?: number;
}

export interface LiveProviderTelemetry {
  lat: number;
  lng: number;
  distanceM: number;
  isInside: boolean;
  updatedAtText: string;
  timestamp: number;
}

// Initial Marketplace Providers
let globalProviders: MarketplaceProvider[] = [
  {
    id: 'prov-1',
    name: 'Rahul Sharma',
    phone: '+91 98765 43210',
    email: 'rahul.care@example.com',
    profilePhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    dateOfBirth: '1995-04-18',
    addressCity: 'Defence Colony, New Delhi',
    emergencyContact: '+91 98110 54321 (Brother)',
    bio: 'Certified canine behavioral specialist and pet caretaker with 4+ years of professional experience. Specializes in leash manners, active walks, and medication management.',
    yearsExperience: 4,
    serviceRadiusKm: 8,
    skills: 'Pet CPR, Canine First Aid, Leash Training, Reactive Dog Handling',
    isAvailable: true,
    ratingAvg: 4.9,
    ratingCount: 38,
    verificationStatus: 'APPROVED',
    idDocumentUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
    lat: 28.5729,
    lng: 77.2289,
    services: [
      { type: 'WALKING', label: 'Dog Walking', priceInr: 350, durationMin: 60, enabled: true },
      { type: 'PET_SITTING', label: 'Pet Sitting', priceInr: 500, durationMin: 60, enabled: true },
      { type: 'GROOMING', label: 'Grooming', priceInr: 800, durationMin: 90, enabled: true },
      { type: 'TRAINING', label: 'Basic Training', priceInr: 700, durationMin: 60, enabled: false },
      { type: 'BOARDING', label: 'Overnight Boarding', priceInr: 1200, durationMin: 720, enabled: false },
      { type: 'VET_VISIT', label: 'Vet Escort Visit', priceInr: 600, durationMin: 120, enabled: false },
    ],
    documents: [
      {
        id: 'doc-1',
        documentType: 'GOVT_ID',
        title: 'National Identity / Aadhaar Card',
        issuingOrg: 'UIDAI',
        documentUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
        issueDate: '2019-06-12',
        status: 'APPROVED',
      },
      {
        id: 'doc-2',
        documentType: 'CERTIFICATION',
        title: 'Pet First-Aid & CPR Certification',
        issuingOrg: 'International Association of Canine Professionals (IACP)',
        documentUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=400&q=80',
        issueDate: '2022-03-15',
        expiryDate: '2027-03-15',
        status: 'APPROVED',
      },
    ],
  },
  {
    id: 'prov-2',
    name: 'Meera Deshmukh',
    phone: '+91 98220 12345',
    email: 'meera.petcare@example.com',
    profilePhoto: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
    dateOfBirth: '1998-11-20',
    addressCity: 'Saket, New Delhi',
    emergencyContact: '+91 98220 98765 (Father)',
    bio: 'Veterinary assistant with passion for gentle care of senior dogs and shy cats. Experienced in post-operative care.',
    yearsExperience: 3,
    serviceRadiusKm: 6,
    skills: 'Oral Medication, Subcutaneous Injections, Senior Pet Comfort',
    isAvailable: false,
    ratingAvg: 4.8,
    ratingCount: 22,
    verificationStatus: 'SUBMITTED',
    idDocumentUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
    lat: 28.5245,
    lng: 77.2066,
    services: [
      { type: 'PET_SITTING', label: 'Pet Sitting', priceInr: 450, durationMin: 60, enabled: true },
      { type: 'VET_VISIT', label: 'Vet Visit Assistance', priceInr: 550, durationMin: 90, enabled: true },
      { type: 'WALKING', label: 'Dog Walking', priceInr: 300, durationMin: 45, enabled: true },
    ],
    documents: [
      {
        id: 'doc-3',
        documentType: 'GOVT_ID',
        title: 'Passport / Govt Photo ID',
        issuingOrg: 'Ministry of External Affairs',
        documentUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
        issueDate: '2021-08-10',
        expiryDate: '2031-08-10',
        status: 'PENDING',
      },
      {
        id: 'doc-4',
        documentType: 'CERTIFICATION',
        title: 'Veterinary Support Assistant Diploma',
        issuingOrg: 'National Animal Care Institute',
        documentUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=400&q=80',
        issueDate: '2023-01-20',
        status: 'PENDING',
      },
    ],
  },
  {
    id: 'prov-3',
    name: 'Aman Verma',
    phone: '+91 97110 88990',
    email: 'aman.verma@example.com',
    profilePhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
    dateOfBirth: '1996-03-14',
    addressCity: 'Hauz Khas, New Delhi',
    emergencyContact: '+91 97110 11223 (Spouse)',
    bio: 'Experienced dog walker passionate about high-energy working breeds and agility exercises.',
    yearsExperience: 2,
    serviceRadiusKm: 5,
    skills: 'Leash control, Agility playtime, Basic puppy commands',
    isAvailable: false,
    ratingAvg: 4.6,
    ratingCount: 14,
    verificationStatus: 'REJECTED',
    rejectionReason: 'Government ID uploaded is blurred and address proof does not match personal registration details. Please upload a clear color scan of your Aadhaar or Passport.',
    idDocumentUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
    lat: 28.5494,
    lng: 77.2001,
    services: [
      { type: 'WALKING', label: 'Dog Walking', priceInr: 320, durationMin: 45, enabled: true },
      { type: 'PET_SITTING', label: 'Pet Sitting', priceInr: 450, durationMin: 60, enabled: true },
    ],
    documents: [
      {
        id: 'doc-5',
        documentType: 'GOVT_ID',
        title: 'National ID (Blurry Scan)',
        issuingOrg: 'UIDAI',
        documentUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
        issueDate: '2018-04-12',
        status: 'REJECTED',
        rejectionReason: 'Blurry photo, text illegible',
      },
      {
        id: 'doc-6',
        documentType: 'CERTIFICATION',
        title: 'Canine Play & Socialization Certificate',
        issuingOrg: 'Delhi Pet Academy',
        documentUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=400&q=80',
        issueDate: '2023-04-10',
        status: 'PENDING',
      },
    ],
  },
  {
    id: 'prov-4',
    name: 'Kavita Sen',
    phone: '+91 99887 76655',
    email: 'kavita.sen@example.com',
    profilePhoto: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=200&q=80',
    dateOfBirth: '1992-09-05',
    addressCity: 'Greater Kailash 1, New Delhi',
    emergencyContact: '+91 99887 11223 (Sister)',
    bio: 'Professional feline & canine boarding specialist with dedicated indoor play space.',
    yearsExperience: 5,
    serviceRadiusKm: 10,
    skills: 'Boarding, Grooming, Cat Handling, First-Aid',
    isAvailable: false,
    ratingAvg: 4.7,
    ratingCount: 29,
    verificationStatus: 'SUSPENDED',
    suspensionReason: 'Account temporarily suspended pending investigation into an unnotified absence on September 25. Please contact partner-support@petcare.com.',
    idDocumentUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
    lat: 28.5535,
    lng: 77.2345,
    services: [
      { type: 'BOARDING', label: 'Overnight Boarding', priceInr: 1100, durationMin: 720, enabled: true },
      { type: 'GROOMING', label: 'Grooming', priceInr: 750, durationMin: 90, enabled: true },
    ],
    documents: [
      {
        id: 'doc-7',
        documentType: 'GOVT_ID',
        title: 'Passport Verification',
        issuingOrg: 'Govt of India',
        documentUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
        issueDate: '2020-05-18',
        status: 'APPROVED',
      },
    ],
  },
];

// Initial realistic marketplace bookings
let globalBookings: MarketplaceBooking[] = [
  {
    id: 'bk-101',
    petId: 'pet-1',
    petName: 'Bruno',
    species: 'Dog',
    breed: 'Golden Retriever',
    providerId: 'prov-1',
    providerName: 'Rahul Sharma',
    providerPhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    providerRatingAvg: 4.9,
    providerRatingCount: 38,
    serviceType: 'Dog Walking',
    scheduledAt: 'Today · 4:30 PM',
    addressText: 'A-42 Defence Colony, Near Park 3, New Delhi',
    lat: 28.5729,
    lng: 77.2289,
    priceInr: 350,
    status: 'ACCEPTED',
    notes: 'Bruno loves brisk walks! Harness is by the entrance coat rack.',
    ownerName: 'Priya Sharma',
    ownerPhone: '+91 98112 34567',
    safeZoneLat: 28.5729,
    safeZoneLng: 77.2289,
    safeZoneRadiusM: 500,
    paymentStatus: 'UNPAID',
  },
  {
    id: 'bk-102',
    petId: 'pet-2',
    petName: 'Milo',
    species: 'Cat',
    breed: 'Persian',
    providerId: 'prov-1',
    providerName: 'Rahul Sharma',
    providerPhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    providerRatingAvg: 4.9,
    providerRatingCount: 38,
    serviceType: 'Pet Sitting',
    scheduledAt: 'Tomorrow · 10:00 AM',
    addressText: 'Flat 304, Green Meadows, Saket',
    lat: 28.5245,
    lng: 77.2066,
    priceInr: 500,
    status: 'REQUESTED',
    notes: 'Please refill wet food bowl and refresh water fountain.',
    ownerName: 'Vikram Mehta',
    ownerPhone: '+91 99234 56789',
    safeZoneLat: 28.5245,
    safeZoneLng: 77.2066,
    safeZoneRadiusM: 500,
    paymentStatus: 'UNPAID',
  },
  {
    id: 'bk-103',
    petId: 'pet-3',
    petName: 'Bella',
    species: 'Dog',
    breed: 'Beagle',
    providerId: 'prov-1',
    providerName: 'Rahul Sharma',
    providerPhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    providerRatingAvg: 4.9,
    providerRatingCount: 38,
    serviceType: 'Dog Walking',
    scheduledAt: 'Yesterday · 5:00 PM',
    addressText: 'Block C, Vasant Vihar',
    lat: 28.5583,
    lng: 77.1637,
    priceInr: 350,
    status: 'COMPLETED',
    notes: 'Great walk through the green belt.',
    ownerName: 'Ananya Roy',
    ownerPhone: '+91 97123 45678',
    safeZoneLat: 28.5583,
    safeZoneLng: 77.1637,
    safeZoneRadiusM: 500,
    paymentStatus: 'PAID',
    rating: 5,
    reviewComment: 'Rahul took great care of Bella. Very prompt and communicative!',
    serviceDurationSeconds: 2700,
  },
];

let globalTelemetry: LiveProviderTelemetry | null = null;
const listeners = new Set<() => void>();

function notify() {
  listeners.forEach((listener) => listener());
}

export function haversineDistanceM(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

export const MarketplaceStore = {
  // Provider operations
  getProviders(): MarketplaceProvider[] {
    return [...globalProviders];
  },

  getCurrentProvider(): MarketplaceProvider {
    return { ...globalProviders[0] };
  },

  // CRITICAL MARKETPLACE RULE: Only APPROVED providers are discoverable to Pet Owners
  getNearbyApprovedProviders(ownerLat: number, ownerLng: number, serviceType?: string) {
    return globalProviders
      .filter((p) => (p.verificationStatus === 'APPROVED' || (p.verificationStatus as any) === 'VERIFIED') && p.isAvailable)
      .map((p) => {
        const dMeters = haversineDistanceM(ownerLat, ownerLng, p.lat, p.lng);
        const matchedService = p.services.find((s) => s.enabled && (!serviceType || s.label.toLowerCase() === serviceType.toLowerCase()));
        return {
          id: p.id,
          name: p.name,
          ratingAvg: p.ratingAvg,
          ratingCount: p.ratingCount,
          yearsExperience: p.yearsExperience,
          priceInr: matchedService?.priceInr ?? p.services.find((s) => s.enabled)?.priceInr ?? 350,
          durationMin: matchedService?.durationMin ?? 60,
          serviceType: matchedService?.label ?? p.services[0]?.label ?? 'Dog Walking',
          bio: p.bio,
          photo: p.profilePhoto || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
          distanceKm: parseFloat((dMeters / 1000).toFixed(1)),
          lat: p.lat,
          lng: p.lng,
          isAvailable: p.isAvailable,
        };
      })
      .sort((a, b) => a.distanceKm - b.distanceKm);
  },

  updateProviderProfile(providerId: string, updates: Partial<MarketplaceProvider>) {
    globalProviders = globalProviders.map((p) =>
      p.id === providerId ? { ...p, ...updates } : p
    );
    notify();
  },

  addProviderDocument(providerId: string, doc: Omit<ProviderDocumentItem, 'id' | 'status'>) {
    const newDoc: ProviderDocumentItem = {
      ...doc,
      id: `doc-${Date.now()}`,
      status: 'PENDING',
    };
    globalProviders = globalProviders.map((p) => {
      if (p.id === providerId) {
        return {
          ...p,
          documents: [newDoc, ...p.documents],
          idDocumentUrl: doc.documentType === 'GOVT_ID' ? doc.documentUrl : p.idDocumentUrl,
        };
      }
      return p;
    });
    notify();
    return newDoc;
  },

  submitProviderVerification(providerId: string) {
    globalProviders = globalProviders.map((p) => {
      if (p.id === providerId) {
        return {
          ...p,
          verificationStatus: 'SUBMITTED',
          rejectionReason: undefined,
        };
      }
      return p;
    });
    notify();
  },

  registerNewProvider(provider: Omit<MarketplaceProvider, 'id' | 'ratingAvg' | 'ratingCount' | 'verificationStatus'>): MarketplaceProvider {
    const newProv: MarketplaceProvider = {
      ...provider,
      id: `prov-${Date.now()}`,
      ratingAvg: 5.0,
      ratingCount: 0,
      verificationStatus: 'SUBMITTED',
      isAvailable: false,
    };
    globalProviders = [newProv, ...globalProviders];
    notify();
    return newProv;
  },

  setProviderVerification(providerId: string, status: MarketplaceProvider['verificationStatus'], rejectionReason?: string, suspensionReason?: string) {
    globalProviders = globalProviders.map((p) => {
      if (p.id === providerId) {
        return {
          ...p,
          verificationStatus: status,
          rejectionReason: rejectionReason ?? (status === 'APPROVED' ? undefined : p.rejectionReason),
          suspensionReason: suspensionReason ?? (status === 'APPROVED' ? undefined : p.suspensionReason),
          isAvailable: status === 'APPROVED' ? p.isAvailable : false,
          documents: status === 'APPROVED' ? p.documents.map((d) => ({ ...d, status: 'APPROVED' })) : p.documents,
        };
      }
      return p;
    });
    notify();
  },

  setProviderAvailability(providerId: string, isAvailable: boolean) {
    const p = globalProviders.find((x) => x.id === providerId);
    if (!p) return;
    if (isAvailable && p.verificationStatus !== 'APPROVED') {
      alert('Only approved and verified providers can go online.');
      return;
    }
    globalProviders = globalProviders.map((x) =>
      x.id === providerId ? { ...x, isAvailable } : x
    );
    notify();
  },

  // Booking operations
  getBookings(): MarketplaceBooking[] {
    return [...globalBookings];
  },

  getBookingById(id: string): MarketplaceBooking | undefined {
    return globalBookings.find((b) => b.id === id);
  },

  getTelemetry(): LiveProviderTelemetry | null {
    return globalTelemetry;
  },

  // Owner action: Create new booking request
  createBooking(booking: Omit<MarketplaceBooking, 'id' | 'status' | 'paymentStatus'>): MarketplaceBooking {
    const newBooking: MarketplaceBooking = {
      ...booking,
      id: `bk-${Date.now()}`,
      status: 'REQUESTED',
      paymentStatus: 'UNPAID',
    };
    globalBookings = [newBooking, ...globalBookings];
    notify();
    return newBooking;
  },

  // Provider action: Accept or Decline
  respondBooking(bookingId: string, accept: boolean, declineReason?: string) {
    globalBookings = globalBookings.map((b) =>
      b.id === bookingId
        ? {
            ...b,
            status: accept ? 'ACCEPTED' : 'REJECTED',
            declineReason: accept ? undefined : declineReason,
          }
        : b
    );
    notify();
  },

  // Provider action: Start service (begins GPS streaming)
  startService(bookingId: string, initialLat?: number, initialLng?: number) {
    const now = Date.now();
    globalBookings = globalBookings.map((b) =>
      b.id === bookingId ? { ...b, status: 'IN_PROGRESS', serviceStartedAt: now } : b
    );

    const b = globalBookings.find((x) => x.id === bookingId);
    if (b) {
      const lat = initialLat ?? b.safeZoneLat + 0.0008;
      const lng = initialLng ?? b.safeZoneLng + 0.0008;
      const dist = Math.round(haversineDistanceM(b.safeZoneLat, b.safeZoneLng, lat, lng));
      globalTelemetry = {
        lat,
        lng,
        distanceM: dist,
        isInside: dist <= b.safeZoneRadiusM,
        updatedAtText: 'Live now',
        timestamp: now,
      };
    }
    notify();
  },

  // Provider action: Live GPS update while service is IN_PROGRESS
  updateProviderGps(lat: number, lng: number) {
    const activeBooking = globalBookings.find((b) => b.status === 'IN_PROGRESS');
    if (activeBooking) {
      const dist = Math.round(haversineDistanceM(activeBooking.safeZoneLat, activeBooking.safeZoneLng, lat, lng));
      globalTelemetry = {
        lat,
        lng,
        distanceM: dist,
        isInside: dist <= activeBooking.safeZoneRadiusM,
        updatedAtText: 'Live now',
        timestamp: Date.now(),
      };
      notify();
    }
  },

  // Provider action: Complete service (immediately stops GPS & terminates live tracking)
  completeService(bookingId: string, durationSeconds?: number) {
    const now = Date.now();
    globalBookings = globalBookings.map((b) => {
      if (b.id === bookingId) {
        const dur = durationSeconds ?? (b.serviceStartedAt ? Math.round((now - b.serviceStartedAt) / 1000) : 1800);
        return {
          ...b,
          status: 'COMPLETED',
          serviceCompletedAt: now,
          serviceDurationSeconds: dur,
        };
      }
      return b;
    });
    globalTelemetry = null; // Stops live location updates
    notify();
  },

  // Owner action: Set/update safe-zone radius while IN_PROGRESS
  updateSafeZone(bookingId: string, radiusM: number) {
    globalBookings = globalBookings.map((b) => {
      if (b.id === bookingId) {
        return { ...b, safeZoneRadiusM: radiusM };
      }
      return b;
    });

    if (globalTelemetry) {
      const b = globalBookings.find((x) => x.id === bookingId);
      if (b) {
        globalTelemetry = {
          ...globalTelemetry,
          isInside: globalTelemetry.distanceM <= radiusM,
        };
      }
    }
    notify();
  },

  // Owner action: Pay after service completion
  payBooking(bookingId: string) {
    globalBookings = globalBookings.map((b) =>
      b.id === bookingId ? { ...b, paymentStatus: 'PAID' } : b
    );
    notify();
  },

  // Owner action: Rate provider after service completion
  rateBooking(bookingId: string, rating: number, comment?: string) {
    globalBookings = globalBookings.map((b) =>
      b.id === bookingId ? { ...b, rating, reviewComment: comment } : b
    );
    notify();
  },

  subscribe(listener: () => void) {
    listeners.add(listener);
    return () => {
      listeners.delete(listener);
    };
  },
};

export function useMarketplace() {
  const [bookings, setBookings] = useState<MarketplaceBooking[]>(MarketplaceStore.getBookings());
  const [telemetry, setTelemetry] = useState<LiveProviderTelemetry | null>(MarketplaceStore.getTelemetry());
  const [providers, setProviders] = useState<MarketplaceProvider[]>(MarketplaceStore.getProviders());

  useEffect(() => {
    const unsub = MarketplaceStore.subscribe(() => {
      setBookings(MarketplaceStore.getBookings());
      setTelemetry(MarketplaceStore.getTelemetry());
      setProviders(MarketplaceStore.getProviders());
    });
    return unsub;
  }, []);

  return {
    bookings,
    telemetry,
    providers,
    currentProvider: MarketplaceStore.getCurrentProvider(),
    createBooking: MarketplaceStore.createBooking,
    respondBooking: MarketplaceStore.respondBooking,
    startService: MarketplaceStore.startService,
    updateProviderGps: MarketplaceStore.updateProviderGps,
    completeService: MarketplaceStore.completeService,
    updateSafeZone: MarketplaceStore.updateSafeZone,
    payBooking: MarketplaceStore.payBooking,
    rateBooking: MarketplaceStore.rateBooking,
    updateProviderProfile: MarketplaceStore.updateProviderProfile,
    addProviderDocument: MarketplaceStore.addProviderDocument,
    submitProviderVerification: MarketplaceStore.submitProviderVerification,
    registerNewProvider: MarketplaceStore.registerNewProvider,
    setProviderVerification: MarketplaceStore.setProviderVerification,
    setProviderAvailability: MarketplaceStore.setProviderAvailability,
    getNearbyApprovedProviders: MarketplaceStore.getNearbyApprovedProviders,
  };
}
