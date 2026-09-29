import React, { useState, useEffect, useRef } from 'react';
import { useMarketplace, MarketplaceStore, MarketplaceProvider } from '../state/sharedMarketplace';

// Design tokens matching the modern minimal premium pet-care aesthetic
const C = {
  primary: '#1A1F1D',       // deep charcoal
  primaryDark: '#0F1211',
  primaryLight: '#EBECE9',
  sage: '#2E6B56',          // muted sage green primary for provider
  sageLight: '#EBF3EF',
  sageBorder: '#C7DDD4',
  coral: '#D9534F',         // muted coral accent
  coralLight: '#FDF0ED',
  coralBorder: '#F8CCC4',
  amber: '#C67D19',
  amberLight: '#FBF4E9',
  amberBorder: '#F3DFC1',
  dark: '#1A1F1D',
  darkMuted: '#57605A',
  darkLight: '#8B948E',
  border: '#E5E2DA',
  borderSubtle: '#F2F1EC',
  background: '#FAF9F6',    // warm off-white neutral
  surface: '#FFFFFF',
  surfaceMuted: '#F3F1EC',
  error: '#C84B46',
  errorBg: '#FDF0EF',
  success: '#2E7D52',
  successBg: '#EDF6F1',
};

export interface BookingItem {
  id: string;
  petName: string;
  species: string;
  breed?: string;
  serviceType: string;
  scheduledAt: string;
  addressText: string;
  lat: number;
  lng: number;
  priceInr: number;
  status: 'REQUESTED' | 'ACCEPTED' | 'IN_PROGRESS' | 'COMPLETED' | 'REJECTED';
  notes?: string;
  ownerName: string;
  ownerPhone?: string;
  safeZoneLat?: number;
  safeZoneLng?: number;
  safeZoneRadiusM?: number;
  rating?: number;
}

export interface ChatMessage {
  id: string;
  senderId: 'provider' | 'owner';
  senderName: string;
  text: string;
  sentAt: string;
}

export default function ProviderAppInteractivePreview() {
  const {
    providers: storeProviders,
    bookings: marketplaceBookings,
    respondBooking,
    startService,
    updateProviderGps,
    completeService,
    setProviderVerification,
    registerNewProvider,
  } = useMarketplace();

  // Active provider account being viewed/tested
  const [selectedProviderId, setSelectedProviderId] = useState<string>('prov-1');

  // Look up current provider profile from shared store
  const activeProvider: MarketplaceProvider | undefined =
    storeProviders.find((p) => p.id === selectedProviderId) || storeProviders[0];

  // Navigation flow state:
  // 'welcome' = "Become a PetCare Provider" landing
  // 'auth' = Phone & OTP verification
  // 'onboarding_personal' = Personal details step
  // 'onboarding_professional' = Professional details & services
  // 'onboarding_docs' = Verify Your Identity & Documents
  // 'status_screen' = Under Review / Rejected / Suspended display
  // 'dashboard' = Approved provider workspace (tabs: requests, active, history, profile)
  // 'tracking' = Active GPS tracking view
  // 'chat' = Chat with pet owner
  const [currentView, setCurrentView] = useState<
    | 'welcome'
    | 'auth'
    | 'onboarding_personal'
    | 'onboarding_professional'
    | 'onboarding_docs'
    | 'status_screen'
    | 'dashboard'
    | 'tracking'
    | 'chat'
  >('dashboard');

  const [activeTab, setActiveTab] = useState<'requests' | 'active' | 'history' | 'profile'>('requests');

  // Onboarding Form State
  const [formData, setFormData] = useState({
    name: 'Vikram Sethi',
    phone: '+91 98450 11223',
    email: 'vikram.sethi@example.com',
    profilePhoto: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
    dateOfBirth: '1996-08-12',
    addressCity: 'Defence Colony, New Delhi',
    emergencyContact: '+91 98450 99887 (Father)',
    bio: 'Professional pet caretaker & certified trainer with 3 years of hands-on experience with dogs and cats.',
    yearsExperience: 3,
    serviceRadiusKm: 8,
    skills: 'Leash Training, Canine CPR, Puppy Socialization, Oral Medication',
    isAvailable: true,
    services: [
      { type: 'WALKING', label: 'Dog Walking', priceInr: 350, durationMin: 60, enabled: true },
      { type: 'PET_SITTING', label: 'Pet Sitting', priceInr: 500, durationMin: 60, enabled: true },
      { type: 'GROOMING', label: 'Grooming', priceInr: 800, durationMin: 90, enabled: true },
      { type: 'TRAINING', label: 'Basic Training', priceInr: 700, durationMin: 60, enabled: false },
      { type: 'BOARDING', label: 'Overnight Boarding', priceInr: 1200, durationMin: 720, enabled: false },
      { type: 'VET_VISIT', label: 'Vet Visit Assistance', priceInr: 600, durationMin: 120, enabled: false },
    ],
    // Document Uploads
    govtIdTitle: 'National Identity / Aadhaar Card',
    govtIdOrg: 'Govt of India (UIDAI)',
    govtIdUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
    addressProofTitle: 'Electricity Utility Bill / Lease Agreement',
    addressProofUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80',
    // Training & Certification Details
    certName: 'Canine First-Aid & Emergency Response Certificate',
    certIssuingOrg: 'International Association of Canine Professionals',
    certIssueDate: '2023-02-15',
    certExpiryDate: '2028-02-15',
    certUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=400&q=80',
  });

  // Re-submission state for rejected provider
  const [resubmitGovtIdUrl, setResubmitGovtIdUrl] = useState(
    'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?auto=format&fit=crop&w=400&q=80'
  );
  const [resubmitNotes, setResubmitNotes] = useState('Re-uploaded clear high-resolution scanned copy of Govt ID.');

  // Phone Auth State
  const [phoneInput, setPhoneInput] = useState('9845011223');
  const [otpInput, setOtpInput] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [authLoading, setAuthLoading] = useState(false);

  // Active tracking session state
  const [activeTrackingBooking, setActiveTrackingBooking] = useState<BookingItem | null>(null);
  const [trackingGps, setTrackingGps] = useState<{ lat: number; lng: number } | null>(null);
  const [gpsWatchId, setGpsWatchId] = useState<number | null>(null);
  const [gpsUpdateSecondsAgo, setGpsUpdateSecondsAgo] = useState(0);
  const [sessionSeconds, setSessionSeconds] = useState(0);
  const [safeZoneAlert, setSafeZoneAlert] = useState<string | null>(null);
  const [isSimulatedBreach, setIsSimulatedBreach] = useState(false);
  const [actionNotice, setActionNotice] = useState<string | null>(null);

  // Chat state
  const [chatBooking, setChatBooking] = useState<BookingItem | null>(null);
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([
    {
      id: 'msg-1',
      senderId: 'owner',
      senderName: 'Priya Sharma',
      text: 'Hi! Bruno is ready for his evening walk whenever you arrive.',
      sentAt: '4:22 PM',
    },
    {
      id: 'msg-2',
      senderId: 'provider',
      senderName: activeProvider?.name || 'Rahul',
      text: 'Hello Priya! I just reached your gate, putting on his harness now.',
      sentAt: '4:26 PM',
    },
  ]);
  const [chatInputText, setChatInputText] = useState('');

  // Notice helper
  const showNotice = (msg: string) => {
    setActionNotice(msg);
    setTimeout(() => setActionNotice(null), 3500);
  };

  // Synchronize screen state with selected provider verification status
  useEffect(() => {
    if (!activeProvider) return;
    if (activeProvider.verificationStatus === 'APPROVED') {
      setCurrentView('dashboard');
    } else {
      setCurrentView('status_screen');
    }
  }, [selectedProviderId, activeProvider?.verificationStatus]);

  // Acquire realistic device coordinates
  useEffect(() => {
    if ('geolocation' in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          setTrackingGps({ lat: pos.coords.latitude, lng: pos.coords.longitude });
        },
        () => {
          setTrackingGps({ lat: 28.5729, lng: 77.2289 });
        },
        { enableHighAccuracy: true, timeout: 6000 }
      );
    } else {
      setTrackingGps({ lat: 28.5729, lng: 77.2289 });
    }
  }, []);

  // Tracking ticker
  useEffect(() => {
    let interval: ReturnType<typeof setInterval>;
    if (currentView === 'tracking' && activeTrackingBooking) {
      interval = setInterval(() => {
        setSessionSeconds((s) => s + 1);
        setGpsUpdateSecondsAgo((s) => (s >= 10 ? 1 : s + 1));
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [currentView, activeTrackingBooking]);

  // Format seconds to mm:ss
  const formatTimer = (totalSec: number) => {
    const m = Math.floor(totalSec / 60);
    const s = totalSec % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  // Auth Handlers
  const handleSendOtp = () => {
    if (!phoneInput || phoneInput.length < 10) {
      showNotice('Please enter a valid 10-digit mobile number');
      return;
    }
    setAuthLoading(true);
    setTimeout(() => {
      setAuthLoading(false);
      setOtpSent(true);
      setOtpInput('4829'); // Pre-fill mock OTP for smooth testing
      showNotice('OTP sent via SMS (Code: 4829)');
    }, 500);
  };

  const handleVerifyOtp = () => {
    if (!otpInput || otpInput.length < 4) {
      showNotice('Please enter 4-digit verification code');
      return;
    }
    setAuthLoading(true);
    setTimeout(() => {
      setAuthLoading(false);
      setFormData((prev) => ({ ...prev, phone: `+91 ${phoneInput}` }));
      setCurrentView('onboarding_personal');
      showNotice('Mobile verified! Please provide your personal details.');
    }, 500);
  };

  // Finish Onboarding & Submit to Admin
  const handleFinalSubmitApplication = () => {
    const newProv = registerNewProvider({
      name: formData.name,
      phone: formData.phone,
      email: formData.email,
      profilePhoto: formData.profilePhoto,
      dateOfBirth: formData.dateOfBirth,
      addressCity: formData.addressCity,
      emergencyContact: formData.emergencyContact,
      bio: formData.bio,
      yearsExperience: Number(formData.yearsExperience) || 2,
      serviceRadiusKm: Number(formData.serviceRadiusKm) || 5,
      skills: formData.skills,
      isAvailable: false,
      idDocumentUrl: formData.govtIdUrl,
      lat: 28.5729,
      lng: 77.2289,
      services: formData.services,
      documents: [
        {
          id: `doc-${Date.now()}-1`,
          documentType: 'GOVT_ID',
          title: formData.govtIdTitle,
          issuingOrg: formData.govtIdOrg,
          documentUrl: formData.govtIdUrl,
          issueDate: '2020-01-15',
          status: 'PENDING',
        },
        {
          id: `doc-${Date.now()}-2`,
          documentType: 'CERTIFICATION',
          title: formData.certName,
          issuingOrg: formData.certIssuingOrg,
          documentUrl: formData.certUrl,
          issueDate: formData.certIssueDate,
          expiryDate: formData.certExpiryDate,
          status: 'PENDING',
        },
      ],
    });

    setSelectedProviderId(newProv.id);
    setCurrentView('status_screen');
    showNotice('Application submitted! Your profile is now under review by PetCare Admin.');
  };

  // Resubmit application after rejection
  const handleResubmitRejected = () => {
    if (!activeProvider) return;
    MarketplaceStore.submitProviderVerification(activeProvider.id);
    MarketplaceStore.addProviderDocument(activeProvider.id, {
      documentType: 'GOVT_ID',
      title: 'Updated Government ID (Clear Scan)',
      issuingOrg: 'UIDAI',
      documentUrl: resubmitGovtIdUrl,
      issueDate: '2022-01-01',
    });
    showNotice('Updated documents submitted! Status changed to SUBMITTED.');
  };

  // Booking accept / decline
  const handleRespondBooking = (bookingId: string, accept: boolean) => {
    respondBooking(bookingId, accept);
    showNotice(accept ? 'Booking accepted! Moved to Active Jobs.' : 'Booking declined.');
    if (accept) {
      setActiveTab('active');
    }
  };

  // Start Service
  const handleStartService = (b: BookingItem) => {
    // 1. Update booking status to IN_PROGRESS in shared store
    startService(b.id, trackingGps?.lat, trackingGps?.lng);
    const updated = { ...b, status: 'IN_PROGRESS' as const };
    setActiveTrackingBooking(updated);
    setSessionSeconds(0);
    setGpsUpdateSecondsAgo(0);
    setIsSimulatedBreach(false);
    setSafeZoneAlert(null);

    // 2. Start real device GPS watching and stream to store
    if ('geolocation' in navigator) {
      try {
        const id = navigator.geolocation.watchPosition(
          (pos) => {
            setTrackingGps({ lat: pos.coords.latitude, lng: pos.coords.longitude });
            setGpsUpdateSecondsAgo(0);
            updateProviderGps(pos.coords.latitude, pos.coords.longitude);
          },
          () => {},
          { enableHighAccuracy: true, maximumAge: 5000 }
        );
        setGpsWatchId(id);
      } catch (_) {}
    }

    setCurrentView('tracking');
    showNotice('Service started! Real-time GPS sharing is now active with the pet owner.');
  };

  // Complete Service
  const handleCompleteService = () => {
    if (!activeTrackingBooking) return;

    if (gpsWatchId !== null && 'geolocation' in navigator) {
      navigator.geolocation.clearWatch(gpsWatchId);
      setGpsWatchId(null);
    }

    completeService(activeTrackingBooking.id);

    const fee = activeTrackingBooking.priceInr;
    const durationMins = Math.max(1, Math.round(sessionSeconds / 60));
    setActiveTrackingBooking(null);
    setCurrentView('dashboard');
    setActiveTab('history');
    showNotice(`Service completed! Duration: ${durationMins}m · Earned: ₹${fee}. GPS tracking stopped.`);
  };

  // Toggle Safe Zone Breach
  const handleToggleBreach = () => {
    const nextBreached = !isSimulatedBreach;
    setIsSimulatedBreach(nextBreached);
    if (nextBreached) {
      setSafeZoneAlert('Safe Zone Alert: You have moved 640m from center (limit: 500m). Please return towards safe zone.');
    } else {
      setSafeZoneAlert(null);
    }
  };

  // Chat message send
  const handleSendMessage = () => {
    if (!chatInputText.trim()) return;
    const now = new Date();
    const timeStr = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    const newMsg: ChatMessage = {
      id: `msg-${Date.now()}`,
      senderId: 'provider',
      senderName: activeProvider?.name || 'Rahul',
      text: chatInputText.trim(),
      sentAt: timeStr,
    };
    setChatMessages((prev) => [...prev, newMsg]);
    setChatInputText('');
  };

  // Bookings list for current provider
  const myBookings: BookingItem[] = marketplaceBookings
    .filter((b) => !b.providerId || b.providerId === activeProvider?.id)
    .map((b) => ({
      id: b.id,
      petName: b.petName,
      species: b.species,
      breed: b.breed,
      serviceType: b.serviceType,
      scheduledAt: b.scheduledAt,
      addressText: b.addressText,
      lat: b.lat,
      lng: b.lng,
      priceInr: b.priceInr,
      status: b.status,
      notes: b.notes,
      ownerName: b.ownerName,
      ownerPhone: b.ownerPhone,
      safeZoneLat: b.safeZoneLat,
      safeZoneLng: b.safeZoneLng,
      safeZoneRadiusM: b.safeZoneRadiusM,
      rating: b.rating,
    }));

  const pendingRequests = myBookings.filter((b) => b.status === 'REQUESTED');
  const activeJobs = myBookings.filter((b) => b.status === 'ACCEPTED' || b.status === 'IN_PROGRESS');
  const completedJobs = myBookings.filter((b) => b.status === 'COMPLETED');
  const totalEarnings = completedJobs.reduce((sum, b) => sum + b.priceInr, 0);

  return (
    <div style={{ minHeight: '100vh', background: '#EFECE6', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
      
      {/* Top Testing Bar: Switch Provider Profile / Status */}
      <div
        style={{
          width: '100%',
          maxWidth: '460px',
          background: '#FFFFFF',
          borderBottom: `1px solid ${C.border}`,
          padding: '10px 14px',
          boxSizing: 'border-box',
          display: 'flex',
          flexDirection: 'column',
          gap: '6px',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ fontSize: '11.5px', fontWeight: 700, color: C.darkMuted, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
            Provider Profile Switcher:
          </div>
          <span
            style={{
              padding: '2px 8px',
              borderRadius: '6px',
              fontSize: '11px',
              fontWeight: 700,
              background:
                activeProvider?.verificationStatus === 'APPROVED'
                  ? C.successBg
                  : activeProvider?.verificationStatus === 'SUBMITTED' || activeProvider?.verificationStatus === 'UNDER_REVIEW'
                  ? C.amberLight
                  : activeProvider?.verificationStatus === 'REJECTED'
                  ? C.errorBg
                  : C.surfaceMuted,
              color:
                activeProvider?.verificationStatus === 'APPROVED'
                  ? C.success
                  : activeProvider?.verificationStatus === 'SUBMITTED' || activeProvider?.verificationStatus === 'UNDER_REVIEW'
                  ? C.amber
                  : activeProvider?.verificationStatus === 'REJECTED'
                  ? C.error
                  : C.darkMuted,
            }}
          >
            Status: {activeProvider?.verificationStatus || 'DRAFT'}
          </span>
        </div>

        {/* Quick buttons to test every requirement state */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
          <button
            onClick={() => {
              setSelectedProviderId('prov-1');
              setCurrentView('dashboard');
            }}
            style={{
              padding: '4px 8px',
              borderRadius: '6px',
              border: selectedProviderId === 'prov-1' && currentView === 'dashboard' ? `1.5px solid ${C.sage}` : `1px solid ${C.border}`,
              background: selectedProviderId === 'prov-1' && currentView === 'dashboard' ? C.sageLight : '#FFF',
              fontSize: '11px',
              fontWeight: 600,
              cursor: 'pointer',
              color: selectedProviderId === 'prov-1' && currentView === 'dashboard' ? C.sage : C.dark,
            }}
          >
            ✓ Rahul (Approved)
          </button>
          <button
            onClick={() => {
              setSelectedProviderId('prov-2');
              setCurrentView('status_screen');
            }}
            style={{
              padding: '4px 8px',
              borderRadius: '6px',
              border: selectedProviderId === 'prov-2' ? `1.5px solid ${C.amber}` : `1px solid ${C.border}`,
              background: selectedProviderId === 'prov-2' ? C.amberLight : '#FFF',
              fontSize: '11px',
              fontWeight: 600,
              cursor: 'pointer',
              color: selectedProviderId === 'prov-2' ? C.amber : C.dark,
            }}
          >
            ⏳ Meera (Under Review)
          </button>
          <button
            onClick={() => {
              setSelectedProviderId('prov-3');
              setCurrentView('status_screen');
            }}
            style={{
              padding: '4px 8px',
              borderRadius: '6px',
              border: selectedProviderId === 'prov-3' ? `1.5px solid ${C.coral}` : `1px solid ${C.border}`,
              background: selectedProviderId === 'prov-3' ? C.coralLight : '#FFF',
              fontSize: '11px',
              fontWeight: 600,
              cursor: 'pointer',
              color: selectedProviderId === 'prov-3' ? C.coral : C.dark,
            }}
          >
            ❌ Aman (Rejected)
          </button>
          <button
            onClick={() => {
              setSelectedProviderId('prov-4');
              setCurrentView('status_screen');
            }}
            style={{
              padding: '4px 8px',
              borderRadius: '6px',
              border: selectedProviderId === 'prov-4' ? `1.5px solid ${C.dark}` : `1px solid ${C.border}`,
              background: selectedProviderId === 'prov-4' ? C.surfaceMuted : '#FFF',
              fontSize: '11px',
              fontWeight: 600,
              cursor: 'pointer',
              color: selectedProviderId === 'prov-4' ? C.dark : C.darkMuted,
            }}
          >
            ⚠️ Kavita (Suspended)
          </button>
          <button
            onClick={() => {
              setCurrentView('welcome');
            }}
            style={{
              padding: '4px 8px',
              borderRadius: '6px',
              border: currentView === 'welcome' ? `1.5px solid ${C.sage}` : `1px solid ${C.border}`,
              background: currentView === 'welcome' ? C.sageLight : '#FFF',
              fontSize: '11px',
              fontWeight: 700,
              cursor: 'pointer',
              color: C.sage,
            }}
          >
            + New Onboarding
          </button>
        </div>
      </div>

      {/* Main Mobile App Frame */}
      <div
        style={{
          width: '100%',
          maxWidth: '430px',
          minHeight: '880px',
          background: C.surface,
          boxShadow: '0 8px 30px rgba(0,0,0,0.08)',
          display: 'flex',
          flexDirection: 'column',
          boxSizing: 'border-box',
          position: 'relative',
        }}
      >
        {/* Notice Toast */}
        {actionNotice && (
          <div
            style={{
              padding: '10px 16px',
              background: C.sage,
              color: '#FFF',
              fontSize: '12.5px',
              fontWeight: 600,
              textAlign: 'center',
              boxShadow: '0 2px 8px rgba(0,0,0,0.15)',
              zIndex: 99,
            }}
          >
            {actionNotice}
          </div>
        )}

        {/* ========================================================= */}
        {/* SCREEN 1: BECOME A PETCARE PROVIDER (FIRST SCREEN)       */}
        {/* ========================================================= */}
        {currentView === 'welcome' && (
          <div style={{ flex: 1, padding: '28px 24px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', background: C.surface }}>
            <div>
              <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: C.sageLight, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '28px', marginBottom: '20px' }}>
                🐾
              </div>
              <h1 style={{ fontSize: '24px', fontWeight: 800, color: C.dark, margin: '0 0 10px', letterSpacing: '-0.5px' }}>
                Become a PetCare Provider
              </h1>
              <p style={{ fontSize: '14.5px', color: C.darkMuted, lineHeight: 1.5, margin: '0 0 24px' }}>
                Join India's verified network of professional dog walkers, pet sitters, and animal caregivers.
              </p>

              {/* Four Value Props Required by Spec */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px', background: C.background, padding: '18px', borderRadius: '16px', border: `1px solid ${C.border}` }}>
                <div style={{ display: 'flex', gap: '14px', alignItems: 'flex-start' }}>
                  <span style={{ fontSize: '20px' }}>💰</span>
                  <div>
                    <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark }}>Earn by providing pet-care services</div>
                    <div style={{ fontSize: '12.5px', color: C.darkMuted, marginTop: '2px' }}>Set your own rates and get direct weekly payouts.</div>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '14px', alignItems: 'flex-start' }}>
                  <span style={{ fontSize: '20px' }}>🛡️</span>
                  <div>
                    <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark }}>Get verified before accepting bookings</div>
                    <div style={{ fontSize: '12.5px', color: C.darkMuted, marginTop: '2px' }}>Identity & certification review builds client trust.</div>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '14px', alignItems: 'flex-start' }}>
                  <span style={{ fontSize: '20px' }}>⚙️</span>
                  <div>
                    <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark }}>Choose the services you provide</div>
                    <div style={{ fontSize: '12.5px', color: C.darkMuted, marginTop: '2px' }}>Dog Walking, Pet Sitting, Grooming, Training, or Boarding.</div>
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '14px', alignItems: 'flex-start' }}>
                  <span style={{ fontSize: '20px' }}>📍</span>
                  <div>
                    <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark }}>Location shared ONLY while active</div>
                    <div style={{ fontSize: '12.5px', color: C.darkMuted, marginTop: '2px' }}>Your GPS is strictly private and streams only during an ongoing service.</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Bottom Actions */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', marginTop: '24px' }}>
              <button
                onClick={() => {
                  setCurrentView('auth');
                }}
                style={{
                  width: '100%',
                  padding: '14px',
                  background: C.sage,
                  color: '#FFFFFF',
                  border: 'none',
                  borderRadius: '12px',
                  fontSize: '15px',
                  fontWeight: 700,
                  cursor: 'pointer',
                }}
              >
                Create Provider Account
              </button>
              <button
                onClick={() => {
                  setSelectedProviderId('prov-1');
                  setCurrentView('dashboard');
                }}
                style={{
                  width: '100%',
                  padding: '12px',
                  background: 'none',
                  color: C.dark,
                  border: `1px solid ${C.border}`,
                  borderRadius: '12px',
                  fontSize: '14px',
                  fontWeight: 600,
                  cursor: 'pointer',
                }}
              >
                Log In (Existing Provider)
              </button>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SCREEN 2: AUTHENTICATION (FIREBASE PHONE OTP)             */}
        {/* ========================================================= */}
        {currentView === 'auth' && (
          <div style={{ flex: 1, padding: '24px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', background: C.surface }}>
            <div>
              <button
                onClick={() => setCurrentView('welcome')}
                style={{ background: 'none', border: 'none', fontSize: '16px', cursor: 'pointer', color: C.dark, padding: 0, marginBottom: '20px' }}
              >
                ← Back
              </button>

              <h2 style={{ fontSize: '22px', fontWeight: 800, color: C.dark, margin: '0 0 8px' }}>
                Verify Mobile Number
              </h2>
              <p style={{ fontSize: '13.5px', color: C.darkMuted, margin: '0 0 24px' }}>
                We'll verify your mobile number using secure Firebase Phone Auth.
              </p>

              <div style={{ marginBottom: '16px' }}>
                <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '6px' }}>
                  Mobile Number
                </label>
                <div style={{ display: 'flex', border: `1px solid ${C.border}`, borderRadius: '10px', overflow: 'hidden' }}>
                  <span style={{ padding: '12px 14px', background: C.background, color: C.darkMuted, fontSize: '14px', fontWeight: 600 }}>+91</span>
                  <input
                    type="tel"
                    value={phoneInput}
                    onChange={(e) => setPhoneInput(e.target.value)}
                    placeholder="9876543210"
                    maxLength={10}
                    style={{ flex: 1, padding: '12px', border: 'none', outline: 'none', fontSize: '15px' }}
                  />
                </div>
              </div>

              {otpSent && (
                <div style={{ marginBottom: '20px' }}>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '6px' }}>
                    Enter 4-Digit Verification Code
                  </label>
                  <input
                    type="text"
                    value={otpInput}
                    onChange={(e) => setOtpInput(e.target.value)}
                    placeholder="4829"
                    maxLength={6}
                    style={{
                      width: '100%',
                      padding: '12px 14px',
                      borderRadius: '10px',
                      border: `1.5px solid ${C.sage}`,
                      fontSize: '18px',
                      letterSpacing: '4px',
                      textAlign: 'center',
                      fontWeight: 700,
                      boxSizing: 'border-box',
                    }}
                  />
                  <div style={{ fontSize: '11.5px', color: C.sage, marginTop: '6px', textAlign: 'center' }}>
                    Firebase OTP sent · Pre-filled: 4829
                  </div>
                </div>
              )}
            </div>

            <div>
              {!otpSent ? (
                <button
                  onClick={handleSendOtp}
                  disabled={authLoading}
                  style={{
                    width: '100%',
                    padding: '14px',
                    background: C.sage,
                    color: '#FFF',
                    border: 'none',
                    borderRadius: '12px',
                    fontSize: '14.5px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  {authLoading ? 'Sending OTP...' : 'Send Verification Code'}
                </button>
              ) : (
                <button
                  onClick={handleVerifyOtp}
                  disabled={authLoading}
                  style={{
                    width: '100%',
                    padding: '14px',
                    background: C.sage,
                    color: '#FFF',
                    border: 'none',
                    borderRadius: '12px',
                    fontSize: '14.5px',
                    fontWeight: 700,
                    cursor: 'pointer',
                  }}
                >
                  {authLoading ? 'Verifying...' : 'Verify & Continue'}
                </button>
              )}
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SCREEN 3: ONBOARDING - PERSONAL DETAILS                   */}
        {/* ========================================================= */}
        {currentView === 'onboarding_personal' && (
          <div style={{ flex: 1, padding: '24px', display: 'flex', flexDirection: 'column', overflowY: 'auto', background: C.surface }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
              <span style={{ fontSize: '11px', fontWeight: 700, color: C.sage, background: C.sageLight, padding: '3px 8px', borderRadius: '6px' }}>Step 1 of 3</span>
              <span style={{ fontSize: '12px', color: C.darkMuted }}>Personal Details</span>
            </div>
            <h2 style={{ fontSize: '20px', fontWeight: 800, color: C.dark, margin: '0 0 16px' }}>Tell us about yourself</h2>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Full Name *</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, fontSize: '13.5px', boxSizing: 'border-box' }}
                />
              </div>

              <div style={{ display: 'flex', gap: '10px' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Phone Number *</label>
                  <input
                    type="text"
                    disabled
                    value={formData.phone}
                    style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, background: C.background, fontSize: '13px', boxSizing: 'border-box' }}
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Date of Birth *</label>
                  <input
                    type="date"
                    value={formData.dateOfBirth}
                    onChange={(e) => setFormData({ ...formData, dateOfBirth: e.target.value })}
                    style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, fontSize: '13px', boxSizing: 'border-box' }}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Email Address *</label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, fontSize: '13.5px', boxSizing: 'border-box' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Profile Photo URL / Upload *</label>
                <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                  <img src={formData.profilePhoto} alt="Profile" style={{ width: '48px', height: '48px', borderRadius: '12px', objectFit: 'cover' }} />
                  <input
                    type="text"
                    value={formData.profilePhoto}
                    onChange={(e) => setFormData({ ...formData, profilePhoto: e.target.value })}
                    style={{ flex: 1, padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, fontSize: '12px', boxSizing: 'border-box' }}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Address / City *</label>
                <input
                  type="text"
                  value={formData.addressCity}
                  onChange={(e) => setFormData({ ...formData, addressCity: e.target.value })}
                  style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, fontSize: '13.5px', boxSizing: 'border-box' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Emergency Contact Name & Phone *</label>
                <input
                  type="text"
                  value={formData.emergencyContact}
                  onChange={(e) => setFormData({ ...formData, emergencyContact: e.target.value })}
                  style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, fontSize: '13.5px', boxSizing: 'border-box' }}
                />
              </div>
            </div>

            <div style={{ marginTop: '24px' }}>
              <button
                onClick={() => {
                  if (!formData.name || !formData.email || !formData.addressCity) {
                    showNotice('Please fill all mandatory personal details');
                    return;
                  }
                  setCurrentView('onboarding_professional');
                }}
                style={{
                  width: '100%',
                  padding: '14px',
                  background: C.sage,
                  color: '#FFF',
                  border: 'none',
                  borderRadius: '12px',
                  fontSize: '14.5px',
                  fontWeight: 700,
                  cursor: 'pointer',
                }}
              >
                Continue to Professional Details →
              </button>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SCREEN 4: ONBOARDING - PROFESSIONAL DETAILS               */}
        {/* ========================================================= */}
        {currentView === 'onboarding_professional' && (
          <div style={{ flex: 1, padding: '24px', display: 'flex', flexDirection: 'column', overflowY: 'auto', background: C.surface }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
              <span style={{ fontSize: '11px', fontWeight: 700, color: C.sage, background: C.sageLight, padding: '3px 8px', borderRadius: '6px' }}>Step 2 of 3</span>
              <span style={{ fontSize: '12px', color: C.darkMuted }}>Services & Experience</span>
            </div>
            <h2 style={{ fontSize: '20px', fontWeight: 800, color: C.dark, margin: '0 0 16px' }}>Services & Pricing</h2>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '8px' }}>
                  Services Offered & Session Pricing (₹) *
                </label>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  {formData.services.map((s, idx) => (
                    <div
                      key={s.type}
                      style={{
                        padding: '10px 12px',
                        background: s.enabled ? C.sageLight : C.background,
                        borderRadius: '10px',
                        border: `1px solid ${s.enabled ? C.sageBorder : C.border}`,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                      }}
                    >
                      <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', flex: 1 }}>
                        <input
                          type="checkbox"
                          checked={s.enabled}
                          onChange={(e) => {
                            const updated = [...formData.services];
                            updated[idx].enabled = e.target.checked;
                            setFormData({ ...formData, services: updated });
                          }}
                        />
                        <span style={{ fontSize: '13.5px', fontWeight: s.enabled ? 700 : 500, color: C.dark }}>{s.label}</span>
                      </label>
                      {s.enabled && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                          <span style={{ fontSize: '12px', color: C.darkMuted }}>₹</span>
                          <input
                            type="number"
                            value={s.priceInr}
                            onChange={(e) => {
                              const updated = [...formData.services];
                              updated[idx].priceInr = Number(e.target.value) || 0;
                              setFormData({ ...formData, services: updated });
                            }}
                            style={{ width: '70px', padding: '4px 6px', borderRadius: '6px', border: `1px solid ${C.border}`, fontSize: '13px', textAlign: 'right' }}
                          />
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>

              <div style={{ display: 'flex', gap: '10px' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Years Experience *</label>
                  <input
                    type="number"
                    value={formData.yearsExperience}
                    onChange={(e) => setFormData({ ...formData, yearsExperience: Number(e.target.value) })}
                    style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, fontSize: '13px', boxSizing: 'border-box' }}
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Service Radius (km) *</label>
                  <input
                    type="number"
                    value={formData.serviceRadiusKm}
                    onChange={(e) => setFormData({ ...formData, serviceRadiusKm: Number(e.target.value) })}
                    style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, fontSize: '13px', boxSizing: 'border-box' }}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Short Professional Bio *</label>
                <textarea
                  rows={3}
                  value={formData.bio}
                  onChange={(e) => setFormData({ ...formData, bio: e.target.value })}
                  style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, fontSize: '13px', boxSizing: 'border-box', resize: 'none' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: C.dark, display: 'block', marginBottom: '4px' }}>Relevant Skills & Handling *</label>
                <input
                  type="text"
                  value={formData.skills}
                  onChange={(e) => setFormData({ ...formData, skills: e.target.value })}
                  style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: `1px solid ${C.border}`, fontSize: '13px', boxSizing: 'border-box' }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', gap: '10px', marginTop: '24px' }}>
              <button
                onClick={() => setCurrentView('onboarding_personal')}
                style={{ flex: 1, padding: '14px', background: C.surface, color: C.dark, border: `1px solid ${C.border}`, borderRadius: '12px', fontSize: '14px', fontWeight: 600, cursor: 'pointer' }}
              >
                ← Back
              </button>
              <button
                onClick={() => setCurrentView('onboarding_docs')}
                style={{ flex: 2, padding: '14px', background: C.sage, color: '#FFF', border: 'none', borderRadius: '12px', fontSize: '14.5px', fontWeight: 700, cursor: 'pointer' }}
              >
                Identity Verification →
              </button>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SCREEN 5: ONBOARDING - VERIFY YOUR IDENTITY & CERTS       */}
        {/* ========================================================= */}
        {currentView === 'onboarding_docs' && (
          <div style={{ flex: 1, padding: '24px', display: 'flex', flexDirection: 'column', overflowY: 'auto', background: C.surface }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
              <span style={{ fontSize: '11px', fontWeight: 700, color: C.sage, background: C.sageLight, padding: '3px 8px', borderRadius: '6px' }}>Step 3 of 3</span>
              <span style={{ fontSize: '12px', color: C.darkMuted }}>Identity & Certification</span>
            </div>
            <h2 style={{ fontSize: '20px', fontWeight: 800, color: C.dark, margin: '0 0 6px' }}>Verify Your Identity</h2>
            <p style={{ fontSize: '12.5px', color: C.darkMuted, margin: '0 0 16px' }}>
              PetCare verifies all providers manually. Documents are reviewed by the Admin team before your account can accept bookings.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {/* Document 1: Government ID */}
              <div style={{ padding: '14px', background: C.background, borderRadius: '12px', border: `1px solid ${C.border}` }}>
                <div style={{ fontSize: '13px', fontWeight: 700, color: C.dark, marginBottom: '6px' }}>1. Government ID / Aadhaar / Passport *</div>
                <div style={{ fontSize: '11.5px', color: C.darkMuted, marginBottom: '8px' }}>Must clearly display your full name, photo, and government ID number.</div>
                <input
                  type="text"
                  value={formData.govtIdTitle}
                  onChange={(e) => setFormData({ ...formData, govtIdTitle: e.target.value })}
                  placeholder="Document Name (e.g., Aadhaar Card)"
                  style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: `1px solid ${C.border}`, fontSize: '12px', marginBottom: '6px', boxSizing: 'border-box' }}
                />
                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                  <span style={{ fontSize: '11.5px', color: C.success, fontWeight: 600 }}>📎 Document Attached</span>
                  <span style={{ fontSize: '11px', color: C.darkMuted }}>(Aadhaar_Scan_Front_Back.pdf)</span>
                </div>
              </div>

              {/* Document 2: Address Proof */}
              <div style={{ padding: '14px', background: C.background, borderRadius: '12px', border: `1px solid ${C.border}` }}>
                <div style={{ fontSize: '13px', fontWeight: 700, color: C.dark, marginBottom: '6px' }}>2. Address Proof *</div>
                <div style={{ fontSize: '11.5px', color: C.darkMuted, marginBottom: '8px' }}>Utility bill, lease agreement, or bank statement matching your registered city.</div>
                <input
                  type="text"
                  value={formData.addressProofTitle}
                  onChange={(e) => setFormData({ ...formData, addressProofTitle: e.target.value })}
                  style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: `1px solid ${C.border}`, fontSize: '12px', boxSizing: 'border-box' }}
                />
              </div>

              {/* Document 3: Professional Training / Certification */}
              <div style={{ padding: '14px', background: C.sageLight, borderRadius: '12px', border: `1px solid ${C.sageBorder}` }}>
                <div style={{ fontSize: '13px', fontWeight: 700, color: C.sage, marginBottom: '4px' }}>3. Training / Professional Certification *</div>
                <div style={{ fontSize: '11.5px', color: C.darkMuted, marginBottom: '10px' }}>
                  E.g., Pet First-Aid, Canine CPR, Dog Training certification, Grooming diploma, or Vet-assistant credential.
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                  <div>
                    <label style={{ fontSize: '11px', fontWeight: 600, color: C.dark, display: 'block', marginBottom: '2px' }}>Certificate Title *</label>
                    <input
                      type="text"
                      value={formData.certName}
                      onChange={(e) => setFormData({ ...formData, certName: e.target.value })}
                      style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: `1px solid ${C.border}`, fontSize: '12px', boxSizing: 'border-box' }}
                    />
                  </div>
                  <div>
                    <label style={{ fontSize: '11px', fontWeight: 600, color: C.dark, display: 'block', marginBottom: '2px' }}>Issuing Organization *</label>
                    <input
                      type="text"
                      value={formData.certIssuingOrg}
                      onChange={(e) => setFormData({ ...formData, certIssuingOrg: e.target.value })}
                      style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: `1px solid ${C.border}`, fontSize: '12px', boxSizing: 'border-box' }}
                    />
                  </div>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <div style={{ flex: 1 }}>
                      <label style={{ fontSize: '11px', fontWeight: 600, color: C.dark, display: 'block', marginBottom: '2px' }}>Issue Date *</label>
                      <input
                        type="date"
                        value={formData.certIssueDate}
                        onChange={(e) => setFormData({ ...formData, certIssueDate: e.target.value })}
                        style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: `1px solid ${C.border}`, fontSize: '12px', boxSizing: 'border-box' }}
                      />
                    </div>
                    <div style={{ flex: 1 }}>
                      <label style={{ fontSize: '11px', fontWeight: 600, color: C.dark, display: 'block', marginBottom: '2px' }}>Expiry Date</label>
                      <input
                        type="date"
                        value={formData.certExpiryDate}
                        onChange={(e) => setFormData({ ...formData, certExpiryDate: e.target.value })}
                        style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: `1px solid ${C.border}`, fontSize: '12px', boxSizing: 'border-box' }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Disclaimer */}
            <div style={{ marginTop: '16px', padding: '10px 12px', background: C.background, borderRadius: '8px', fontSize: '11px', color: C.darkMuted, lineHeight: 1.4 }}>
              🔒 <strong>Verification Policy:</strong> Documents are never automatically verified. Our trust & safety team validates government credentials before assigning your provider badge.
            </div>

            {/* Action buttons */}
            <div style={{ display: 'flex', gap: '10px', marginTop: '20px' }}>
              <button
                onClick={() => setCurrentView('onboarding_professional')}
                style={{ flex: 1, padding: '14px', background: C.surface, color: C.dark, border: `1px solid ${C.border}`, borderRadius: '12px', fontSize: '14px', fontWeight: 600, cursor: 'pointer' }}
              >
                ← Back
              </button>
              <button
                onClick={handleFinalSubmitApplication}
                style={{ flex: 2, padding: '14px', background: C.sage, color: '#FFF', border: 'none', borderRadius: '12px', fontSize: '14.5px', fontWeight: 700, cursor: 'pointer' }}
              >
                Submit Application
              </button>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SCREEN 6: STATUS SCREEN (SUBMITTED / REJECTED / SUSPENDED) */}
        {/* ========================================================= */}
        {currentView === 'status_screen' && activeProvider && (
          <div style={{ flex: 1, padding: '28px 24px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', background: C.surface }}>
            <div>
              {/* Profile Card Summary */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px 14px', background: C.background, borderRadius: '12px', marginBottom: '24px' }}>
                <img
                  src={activeProvider.profilePhoto || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80'}
                  alt={activeProvider.name}
                  style={{ width: '44px', height: '44px', borderRadius: '10px', objectFit: 'cover' }}
                />
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '15px', fontWeight: 700, color: C.dark }}>{activeProvider.name}</div>
                  <div style={{ fontSize: '12px', color: C.darkMuted }}>{activeProvider.phone} · {activeProvider.addressCity}</div>
                </div>
              </div>

              {/* STATE 1: SUBMITTED OR UNDER_REVIEW */}
              {(activeProvider.verificationStatus === 'SUBMITTED' || activeProvider.verificationStatus === 'UNDER_REVIEW') && (
                <div>
                  <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: C.amberLight, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '26px', marginBottom: '16px' }}>
                    ⏳
                  </div>
                  <h2 style={{ fontSize: '22px', fontWeight: 800, color: C.dark, margin: '0 0 8px' }}>
                    Application submitted
                  </h2>
                  <p style={{ fontSize: '14px', color: C.darkMuted, lineHeight: 1.5, margin: '0 0 20px' }}>
                    Your profile is currently under review by PetCare.
                  </p>

                  <div style={{ padding: '16px', background: C.background, borderRadius: '14px', border: `1px solid ${C.border}`, display: 'flex', flexDirection: 'column', gap: '12px', marginBottom: '20px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <div style={{ width: '22px', height: '22px', borderRadius: '50%', background: C.success, color: '#FFF', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700 }}>✓</div>
                      <div style={{ fontSize: '13px', fontWeight: 600, color: C.dark }}>Application Received</div>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <div style={{ width: '22px', height: '22px', borderRadius: '50%', background: C.amber, color: '#FFF', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700 }}>•</div>
                      <div style={{ fontSize: '13px', fontWeight: 600, color: C.amber }}>Document Verification in Progress</div>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', opacity: 0.5 }}>
                      <div style={{ width: '22px', height: '22px', borderRadius: '50%', background: '#CBD5E1', color: '#FFF', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 700 }}>3</div>
                      <div style={{ fontSize: '13px', fontWeight: 600, color: C.dark }}>Admin Approval & Marketplace Listing</div>
                    </div>
                  </div>

                  <div style={{ padding: '14px', background: C.amberLight, borderRadius: '12px', border: `1px solid ${C.amberBorder}`, fontSize: '12px', color: C.dark, lineHeight: 1.4 }}>
                    ⚠️ <strong>Restricted Access:</strong> You cannot accept client bookings or go online until your application has been verified and approved by the admin team.
                  </div>
                </div>
              )}

              {/* STATE 2: REJECTED */}
              {activeProvider.verificationStatus === 'REJECTED' && (
                <div>
                  <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: C.coralLight, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '26px', marginBottom: '16px' }}>
                    ❌
                  </div>
                  <h2 style={{ fontSize: '22px', fontWeight: 800, color: C.coral, margin: '0 0 8px' }}>
                    Application Rejected
                  </h2>
                  <p style={{ fontSize: '13.5px', color: C.darkMuted, lineHeight: 1.4, margin: '0 0 16px' }}>
                    Your application could not be approved due to the following reason from the admin team:
                  </p>

                  {/* Rejection Reason Banner */}
                  <div style={{ padding: '16px', background: C.coralLight, borderRadius: '12px', border: `1.5px solid ${C.coralBorder}`, marginBottom: '20px' }}>
                    <div style={{ fontSize: '11px', fontWeight: 700, color: C.coral, textTransform: 'uppercase', marginBottom: '4px' }}>
                      Admin Reason
                    </div>
                    <div style={{ fontSize: '13.5px', fontWeight: 600, color: C.dark, lineHeight: 1.4 }}>
                      "{activeProvider.rejectionReason || 'Uploaded documents did not meet verification guidelines. Please upload valid color documents.'}"
                    </div>
                  </div>

                  {/* Document Correction & Re-upload */}
                  <div style={{ padding: '16px', background: C.background, borderRadius: '12px', border: `1px solid ${C.border}` }}>
                    <div style={{ fontSize: '13px', fontWeight: 700, color: C.dark, marginBottom: '6px' }}>
                      Correct Documents & Resubmit
                    </div>
                    <div style={{ fontSize: '12px', color: C.darkMuted, marginBottom: '10px' }}>
                      Upload a new, clear, high-resolution document:
                    </div>
                    <input
                      type="text"
                      value={resubmitGovtIdUrl}
                      onChange={(e) => setResubmitGovtIdUrl(e.target.value)}
                      placeholder="Updated Document URL / Scan"
                      style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: `1px solid ${C.border}`, fontSize: '12px', marginBottom: '8px', boxSizing: 'border-box' }}
                    />
                    <input
                      type="text"
                      value={resubmitNotes}
                      onChange={(e) => setResubmitNotes(e.target.value)}
                      placeholder="Notes for Admin"
                      style={{ width: '100%', padding: '8px 10px', borderRadius: '6px', border: `1px solid ${C.border}`, fontSize: '12px', boxSizing: 'border-box' }}
                    />
                    <button
                      onClick={handleResubmitRejected}
                      style={{
                        width: '100%',
                        padding: '12px',
                        background: C.sage,
                        color: '#FFF',
                        border: 'none',
                        borderRadius: '8px',
                        fontSize: '13px',
                        fontWeight: 700,
                        cursor: 'pointer',
                        marginTop: '6px',
                      }}
                    >
                      Resubmit Corrected Documents
                    </button>
                  </div>
                </div>
              )}

              {/* STATE 3: SUSPENDED */}
              {activeProvider.verificationStatus === 'SUSPENDED' && (
                <div>
                  <div style={{ width: '56px', height: '56px', borderRadius: '16px', background: C.surfaceMuted, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '26px', marginBottom: '16px' }}>
                    ⚠️
                  </div>
                  <h2 style={{ fontSize: '22px', fontWeight: 800, color: C.dark, margin: '0 0 8px' }}>
                    Account Suspended
                  </h2>
                  <p style={{ fontSize: '13.5px', color: C.darkMuted, lineHeight: 1.4, margin: '0 0 16px' }}>
                    This provider account is currently suspended from accepting jobs.
                  </p>

                  <div style={{ padding: '16px', background: C.surfaceMuted, borderRadius: '12px', border: `1px solid ${C.border}`, marginBottom: '20px' }}>
                    <div style={{ fontSize: '11px', fontWeight: 700, color: C.darkMuted, textTransform: 'uppercase', marginBottom: '4px' }}>
                      Suspension Reason
                    </div>
                    <div style={{ fontSize: '13.5px', fontWeight: 600, color: C.dark, lineHeight: 1.4 }}>
                      "{activeProvider.suspensionReason || 'Account suspended by PetCare Admin.'}"
                    </div>
                  </div>

                  <div style={{ padding: '14px', background: C.background, borderRadius: '12px', border: `1px solid ${C.border}`, fontSize: '12px', color: C.darkMuted, lineHeight: 1.4 }}>
                    If you believe this is in error, please contact partner-support@petcare.com with your Provider ID (<code>{activeProvider.id}</code>).
                  </div>
                </div>
              )}
            </div>

            {/* Bottom helper */}
            <div style={{ paddingTop: '20px' }}>
              <button
                onClick={() => {
                  setSelectedProviderId('prov-1');
                  setCurrentView('dashboard');
                }}
                style={{
                  width: '100%',
                  padding: '12px',
                  background: 'none',
                  color: C.dark,
                  border: `1px solid ${C.border}`,
                  borderRadius: '10px',
                  fontSize: '13px',
                  fontWeight: 600,
                  cursor: 'pointer',
                }}
              >
                Switch to Approved Provider (Rahul Sharma) →
              </button>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SCREEN 7: LIVE GPS TRACKING SCREEN (DURING IN_PROGRESS)   */}
        {/* ========================================================= */}
        {currentView === 'tracking' && activeTrackingBooking && (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', position: 'relative', background: C.surface }}>
            {/* Header */}
            <div style={{ padding: '14px 18px', borderBottom: `1px solid ${C.border}`, display: 'flex', alignItems: 'center', justifyContent: 'space-between', background: C.surface, zIndex: 10 }}>
              <div>
                <div style={{ fontSize: '15px', fontWeight: 700, color: C.dark }}>
                  {activeTrackingBooking.serviceType} · {activeTrackingBooking.petName}
                </div>
                <div style={{ fontSize: '12px', color: C.darkMuted }}>Owner: {activeTrackingBooking.ownerName}</div>
              </div>
              <button
                onClick={() => {
                  setChatBooking(activeTrackingBooking);
                  setCurrentView('chat');
                }}
                style={{ padding: '6px 12px', background: C.sageLight, color: C.sage, border: `1px solid ${C.sageBorder}`, borderRadius: '8px', fontSize: '12px', fontWeight: 600, cursor: 'pointer' }}
              >
                Chat
              </button>
            </div>

            {/* Safe Zone Alert Banner */}
            {safeZoneAlert && (
              <div style={{ padding: '12px 16px', background: C.coralLight, borderBottom: `1px solid ${C.coralBorder}`, display: 'flex', alignItems: 'center', gap: '8px', zIndex: 10 }}>
                <span style={{ fontSize: '16px' }}>⚠️</span>
                <div style={{ fontSize: '12px', color: C.coral, fontWeight: 600, lineHeight: 1.3 }}>
                  {safeZoneAlert}
                </div>
              </div>
            )}

            {/* Live Interactive Map View */}
            <div style={{ flex: 1, position: 'relative', background: '#EAF0ED', overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ position: 'absolute', inset: 0, opacity: 0.15, backgroundImage: 'radial-gradient(#2E6B56 1px, transparent 1px)', backgroundSize: '20px 20px' }} />

              {/* Safe Zone Radius Boundary */}
              <div
                style={{
                  position: 'absolute',
                  width: isSimulatedBreach ? '220px' : '260px',
                  height: isSimulatedBreach ? '220px' : '260px',
                  borderRadius: '50%',
                  border: `2px dashed ${isSimulatedBreach ? C.coral : C.sage}`,
                  background: isSimulatedBreach ? 'rgba(217, 83, 79, 0.12)' : 'rgba(46, 107, 86, 0.12)',
                  transition: 'all 0.4s ease',
                  pointerEvents: 'none',
                }}
              />

              {/* Center Service Address Marker */}
              <div style={{ position: 'relative', display: 'flex', flexDirection: 'column', alignItems: 'center', zIndex: 2 }}>
                <div style={{ width: '12px', height: '12px', borderRadius: '50%', background: C.dark, border: '2px solid #FFF', boxShadow: '0 2px 6px rgba(0,0,0,0.25)' }} />
                <span style={{ fontSize: '10px', fontWeight: 700, color: C.dark, background: '#FFF', padding: '2px 6px', borderRadius: '4px', marginTop: '3px', border: `1px solid ${C.border}` }}>
                  Service Address
                </span>
              </div>

              {/* Provider Live GPS Location Marker */}
              <div
                style={{
                  position: 'absolute',
                  top: isSimulatedBreach ? '18%' : '44%',
                  left: isSimulatedBreach ? '80%' : '60%',
                  transition: 'all 0.8s ease',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  zIndex: 3,
                }}
              >
                <div style={{ position: 'relative' }}>
                  <div style={{ width: '32px', height: '32px', borderRadius: '50%', background: C.sage, color: '#FFF', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '14px', border: '3px solid #FFF', boxShadow: '0 3px 10px rgba(0,0,0,0.25)' }}>
                    🐾
                  </div>
                  <div style={{ position: 'absolute', top: '-2px', right: '-2px', width: '9px', height: '9px', borderRadius: '50%', background: C.success, border: '1.5px solid #FFF' }} />
                </div>
                <span style={{ fontSize: '10px', fontWeight: 700, color: isSimulatedBreach ? C.coral : C.sage, background: '#FFF', padding: '2px 6px', borderRadius: '4px', marginTop: '3px', boxShadow: '0 1px 4px rgba(0,0,0,0.1)' }}>
                  You (Live GPS) {isSimulatedBreach ? '· Safe Zone Exceeded' : ''}
                </span>
              </div>

              {/* Safe zone simulation toggle for test */}
              <div style={{ position: 'absolute', top: '14px', right: '14px', zIndex: 5 }}>
                <button
                  onClick={handleToggleBreach}
                  style={{ padding: '6px 10px', background: '#FFF', border: `1px solid ${C.border}`, borderRadius: '8px', fontSize: '11px', fontWeight: 600, color: C.dark, cursor: 'pointer', boxShadow: '0 2px 6px rgba(0,0,0,0.1)' }}
                >
                  {isSimulatedBreach ? 'Reset inside safe zone' : 'Simulate boundary breach'}
                </button>
              </div>
            </div>

            {/* Bottom Control Bar */}
            <div style={{ padding: '16px 20px', background: C.surface, borderTop: `1px solid ${C.border}`, boxShadow: '0 -4px 16px rgba(0,0,0,0.05)' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: C.sage }} />
                  <span style={{ fontSize: '13px', fontWeight: 600, color: C.sage }}>
                    Location sharing active · {gpsUpdateSecondsAgo === 0 ? 'Just now' : `${gpsUpdateSecondsAgo}s ago`}
                  </span>
                </div>
                <div style={{ fontSize: '16px', fontWeight: 700, color: C.dark, fontVariantNumeric: 'tabular-nums' }}>
                  {formatTimer(sessionSeconds)}
                </div>
              </div>

              <div style={{ padding: '12px 14px', background: C.background, borderRadius: '12px', border: `1px solid ${C.border}`, marginBottom: '14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontSize: '13.5px', fontWeight: 700, color: C.dark }}>{activeTrackingBooking.petName} ({activeTrackingBooking.species})</div>
                  <div style={{ fontSize: '12px', color: C.darkMuted }}>{activeTrackingBooking.addressText}</div>
                </div>
                <div style={{ fontSize: '16px', fontWeight: 700, color: C.dark }}>₹{activeTrackingBooking.priceInr}</div>
              </div>

              <button
                onClick={handleCompleteService}
                style={{
                  width: '100%',
                  padding: '14px',
                  background: C.sage,
                  color: '#FFFFFF',
                  border: 'none',
                  borderRadius: '12px',
                  fontSize: '15px',
                  fontWeight: 700,
                  cursor: 'pointer',
                }}
              >
                Complete Service
              </button>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SCREEN 8: CHAT WITH PET OWNER                             */}
        {/* ========================================================= */}
        {currentView === 'chat' && chatBooking && (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', background: C.surface }}>
            <div style={{ padding: '14px 18px', borderBottom: `1px solid ${C.border}`, display: 'flex', alignItems: 'center', gap: '12px' }}>
              <button
                onClick={() => setCurrentView(activeTrackingBooking ? 'tracking' : 'dashboard')}
                style={{ background: 'none', border: 'none', fontSize: '18px', cursor: 'pointer', color: C.dark }}
              >
                ←
              </button>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: '15px', fontWeight: 700, color: C.dark }}>{chatBooking.ownerName}</div>
                <div style={{ fontSize: '12px', color: C.darkMuted }}>{chatBooking.serviceType} · {chatBooking.petName}</div>
              </div>
              <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: C.success }} />
            </div>

            <div style={{ flex: 1, overflowY: 'auto', padding: '16px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {chatMessages.map((m) => {
                const isMe = m.senderId === 'provider';
                return (
                  <div key={m.id} style={{ display: 'flex', flexDirection: 'column', alignItems: isMe ? 'flex-end' : 'flex-start' }}>
                    <div
                      style={{
                        maxWidth: '75%',
                        padding: '10px 14px',
                        borderRadius: '12px',
                        background: isMe ? C.sage : C.surface,
                        color: isMe ? '#FFFFFF' : C.dark,
                        border: isMe ? 'none' : `1px solid ${C.border}`,
                        fontSize: '13.5px',
                        lineHeight: 1.4,
                      }}
                    >
                      {m.text}
                    </div>
                    <span style={{ fontSize: '10.5px', color: C.darkLight, marginTop: '3px', padding: '0 4px' }}>
                      {m.sentAt}
                    </span>
                  </div>
                );
              })}
            </div>

            <div style={{ padding: '12px 16px', borderTop: `1px solid ${C.border}`, display: 'flex', gap: '8px', background: C.surface }}>
              <input
                type="text"
                placeholder="Type message to pet owner..."
                value={chatInputText}
                onChange={(e) => setChatInputText(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleSendMessage()}
                style={{ flex: 1, padding: '10px 14px', borderRadius: '10px', border: `1px solid ${C.border}`, fontSize: '13.5px', outline: 'none' }}
              />
              <button
                onClick={handleSendMessage}
                style={{ padding: '0 16px', background: C.sage, color: '#FFF', border: 'none', borderRadius: '10px', fontWeight: 600, fontSize: '13.5px', cursor: 'pointer' }}
              >
                Send
              </button>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SCREEN 9: APPROVED PROVIDER DASHBOARD (MAIN)              */}
        {/* ========================================================= */}
        {currentView === 'dashboard' && activeProvider && (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
            {/* Top Provider Bar */}
            <div style={{ padding: '16px 20px', borderBottom: `1px solid ${C.border}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: C.surface }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <img
                  src={activeProvider.profilePhoto || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80'}
                  alt={activeProvider.name}
                  style={{ width: '40px', height: '40px', borderRadius: '10px', objectFit: 'cover' }}
                />
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <span style={{ fontSize: '15px', fontWeight: 800, color: C.dark }}>{activeProvider.name}</span>
                    <span style={{ fontSize: '11px', color: C.sage, fontWeight: 700, background: C.sageLight, padding: '1px 6px', borderRadius: '4px' }}>✓ Verified</span>
                  </div>
                  <div style={{ fontSize: '12px', color: C.darkMuted }}>
                    ★ {activeProvider.ratingAvg} ({activeProvider.ratingCount} reviews) · {activeProvider.addressCity}
                  </div>
                </div>
              </div>

              {/* Online / Offline switch */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ fontSize: '12px', fontWeight: 600, color: activeProvider.isAvailable ? C.sage : C.darkMuted }}>
                  {activeProvider.isAvailable ? 'Online' : 'Offline'}
                </span>
                <button
                  onClick={() => {
                    const next = !activeProvider.isAvailable;
                    MarketplaceStore.setProviderAvailability(activeProvider.id, next);
                    showNotice(next ? 'You are now online and visible to pet owners.' : 'You are now offline.');
                  }}
                  style={{
                    width: '36px',
                    height: '20px',
                    borderRadius: '10px',
                    background: activeProvider.isAvailable ? C.sage : '#D1D5DB',
                    border: 'none',
                    position: 'relative',
                    cursor: 'pointer',
                    padding: '2px',
                  }}
                >
                  <div
                    style={{
                      width: '16px',
                      height: '16px',
                      borderRadius: '50%',
                      background: '#FFFFFF',
                      transform: activeProvider.isAvailable ? 'translateX(16px)' : 'translateX(0)',
                      transition: 'transform 0.2s ease',
                    }}
                  />
                </button>
              </div>
            </div>

            {/* Tab Body */}
            <div style={{ flex: 1, overflowY: 'auto' }}>
              
              {/* TAB 1: REQUESTS */}
              {activeTab === 'requests' && (
                <div style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span>Booking Requests ({pendingRequests.length})</span>
                    <span style={{ fontSize: '12px', fontWeight: 500, color: C.darkMuted }}>Respond promptly</span>
                  </div>

                  {pendingRequests.length === 0 ? (
                    <div style={{ padding: '48px 24px', textAlign: 'center', background: C.background, borderRadius: '16px', border: `1px solid ${C.border}` }}>
                      <div style={{ width: '54px', height: '54px', borderRadius: '14px', background: C.surface, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px', fontSize: '24px' }}>
                        📥
                      </div>
                      <div style={{ fontSize: '15px', fontWeight: 700, color: C.dark, marginBottom: '6px' }}>No Pending Requests</div>
                      <p style={{ margin: 0, fontSize: '13px', color: C.darkMuted, lineHeight: 1.4 }}>
                        {activeProvider.isAvailable
                          ? 'You are online and ready to receive bookings. New client requests near you will appear here.'
                          : 'You are currently offline. Turn on your online status at the top to receive client requests.'}
                      </p>
                    </div>
                  ) : (
                    pendingRequests.map((b) => (
                      <div
                        key={b.id}
                        style={{
                          padding: '16px',
                          background: C.surface,
                          borderRadius: '14px',
                          border: `1px solid ${C.border}`,
                          display: 'flex',
                          flexDirection: 'column',
                          gap: '12px',
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                          <div>
                            <div style={{ fontSize: '15px', fontWeight: 700, color: C.dark }}>{b.serviceType}</div>
                            <div style={{ fontSize: '12px', color: C.darkMuted, marginTop: '2px' }}>{b.scheduledAt}</div>
                          </div>
                          <div style={{ fontSize: '17px', fontWeight: 800, color: C.dark }}>₹{b.priceInr}</div>
                        </div>

                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '10px 12px', background: C.background, borderRadius: '10px' }}>
                          <div style={{ width: '36px', height: '36px', borderRadius: '8px', background: C.surface, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '16px' }}>
                            🐶
                          </div>
                          <div style={{ flex: 1 }}>
                            <div style={{ fontSize: '13.5px', fontWeight: 700, color: C.dark }}>{b.petName} ({b.species})</div>
                            <div style={{ fontSize: '12px', color: C.darkMuted }}>Owner: {b.ownerName} · {b.ownerPhone}</div>
                          </div>
                        </div>

                        <div style={{ fontSize: '12px', color: C.darkMuted, lineHeight: 1.3 }}>
                          📍 {b.addressText}
                        </div>

                        {b.notes && (
                          <div style={{ fontSize: '12px', color: C.dark, fontStyle: 'italic', background: C.surfaceMuted, padding: '6px 10px', borderRadius: '6px' }}>
                            "{b.notes}"
                          </div>
                        )}

                        <div style={{ display: 'flex', gap: '10px', marginTop: '4px' }}>
                          <button
                            onClick={() => handleRespondBooking(b.id, false)}
                            style={{
                              flex: 1,
                              padding: '10px',
                              background: 'none',
                              color: C.coral,
                              border: `1px solid ${C.coralBorder}`,
                              borderRadius: '8px',
                              fontSize: '13px',
                              fontWeight: 600,
                              cursor: 'pointer',
                            }}
                          >
                            Decline
                          </button>
                          <button
                            onClick={() => handleRespondBooking(b.id, true)}
                            style={{
                              flex: 1,
                              padding: '10px',
                              background: C.sage,
                              color: '#FFFFFF',
                              border: 'none',
                              borderRadius: '8px',
                              fontSize: '13px',
                              fontWeight: 700,
                              cursor: 'pointer',
                            }}
                          >
                            Accept
                          </button>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}

              {/* TAB 2: ACTIVE JOBS */}
              {activeTab === 'active' && (
                <div style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark }}>
                    Active & Upcoming Jobs ({activeJobs.length})
                  </div>

                  {activeJobs.length === 0 ? (
                    <div style={{ padding: '48px 24px', textAlign: 'center', background: C.background, borderRadius: '16px', border: `1px solid ${C.border}` }}>
                      <div style={{ width: '54px', height: '54px', borderRadius: '14px', background: C.surface, display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px', fontSize: '24px' }}>
                        📋
                      </div>
                      <div style={{ fontSize: '15px', fontWeight: 700, color: C.dark, marginBottom: '6px' }}>No Active Jobs</div>
                      <p style={{ margin: 0, fontSize: '13px', color: C.darkMuted, lineHeight: 1.4 }}>
                        Accepted appointments and ongoing walk sessions appear here.
                      </p>
                    </div>
                  ) : (
                    activeJobs.map((b) => {
                      const isInProgress = b.status === 'IN_PROGRESS';
                      return (
                        <div
                          key={b.id}
                          style={{
                            padding: '16px',
                            background: C.surface,
                            borderRadius: '14px',
                            border: `1.5px solid ${isInProgress ? C.sage : C.border}`,
                            display: 'flex',
                            flexDirection: 'column',
                            gap: '12px',
                          }}
                        >
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                            <div>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                                <span style={{ fontSize: '15.5px', fontWeight: 700, color: C.dark }}>{b.serviceType}</span>
                                <span
                                  style={{
                                    padding: '2px 8px',
                                    borderRadius: '6px',
                                    fontSize: '11px',
                                    fontWeight: 700,
                                    background: isInProgress ? C.sageLight : C.amberLight,
                                    color: isInProgress ? C.sage : C.amber,
                                  }}
                                >
                                  {isInProgress ? 'In Progress' : 'Accepted'}
                                </span>
                              </div>
                              <div style={{ fontSize: '12px', color: C.darkMuted, marginTop: '3px' }}>{b.scheduledAt}</div>
                            </div>
                            <div style={{ fontSize: '17px', fontWeight: 800, color: C.dark }}>₹{b.priceInr}</div>
                          </div>

                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 12px', background: C.background, borderRadius: '10px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                              <div style={{ width: '36px', height: '36px', borderRadius: '8px', background: C.surface, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '16px' }}>
                                🐾
                              </div>
                              <div>
                                <div style={{ fontSize: '13.5px', fontWeight: 700, color: C.dark }}>{b.petName} ({b.species})</div>
                                <div style={{ fontSize: '12px', color: C.darkMuted }}>Owner: {b.ownerName}</div>
                              </div>
                            </div>
                            <button
                              onClick={() => {
                                setChatBooking(b);
                                setCurrentView('chat');
                              }}
                              style={{ padding: '6px 12px', background: C.surface, border: `1px solid ${C.border}`, borderRadius: '8px', fontSize: '12px', fontWeight: 600, color: C.dark, cursor: 'pointer' }}
                            >
                              Chat
                            </button>
                          </div>

                          <div style={{ fontSize: '12px', color: C.darkMuted }}>
                            📍 {b.addressText}
                          </div>

                          {b.safeZoneRadiusM && (
                            <div style={{ fontSize: '12px', color: C.sage, fontWeight: 500 }}>
                              🛡️ Safe Zone configured by owner ({b.safeZoneRadiusM}m radius)
                            </div>
                          )}

                          {/* Action Button */}
                          {!isInProgress ? (
                            <button
                              onClick={() => handleStartService(b)}
                              style={{
                                width: '100%',
                                padding: '12px',
                                background: C.sage,
                                color: '#FFFFFF',
                                border: 'none',
                                borderRadius: '10px',
                                fontSize: '14px',
                                fontWeight: 700,
                                cursor: 'pointer',
                                marginTop: '4px',
                              }}
                            >
                              Start Service
                            </button>
                          ) : (
                            <button
                              onClick={() => {
                                setActiveTrackingBooking(b);
                                setCurrentView('tracking');
                              }}
                              style={{
                                width: '100%',
                                padding: '12px',
                                background: C.dark,
                                color: '#FFFFFF',
                                border: 'none',
                                borderRadius: '10px',
                                fontSize: '14px',
                                fontWeight: 700,
                                cursor: 'pointer',
                                marginTop: '4px',
                              }}
                            >
                              Open Live Tracking & Map
                            </button>
                          )}
                        </div>
                      );
                    })
                  )}
                </div>
              )}

              {/* TAB 3: HISTORY */}
              {activeTab === 'history' && (
                <div style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  <div style={{ padding: '16px', background: C.sageLight, borderRadius: '14px', border: `1px solid ${C.sageBorder}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                      <div style={{ fontSize: '12px', color: C.darkMuted }}>Total Earnings</div>
                      <div style={{ fontSize: '20px', fontWeight: 800, color: C.sage, marginTop: '2px' }}>₹{totalEarnings}</div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontSize: '12px', color: C.darkMuted }}>Completed Sessions</div>
                      <div style={{ fontSize: '16px', fontWeight: 700, color: C.dark, marginTop: '2px' }}>{completedJobs.length} services</div>
                    </div>
                  </div>

                  <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark }}>
                    Past Services ({completedJobs.length})
                  </div>

                  {completedJobs.length === 0 ? (
                    <div style={{ padding: '36px 20px', textAlign: 'center', background: C.background, borderRadius: '14px', border: `1px solid ${C.border}` }}>
                      <div style={{ fontSize: '14px', color: C.darkMuted }}>No completed jobs yet.</div>
                    </div>
                  ) : (
                    completedJobs.map((b) => (
                      <div
                        key={b.id}
                        style={{
                          padding: '14px 16px',
                          background: C.surface,
                          borderRadius: '12px',
                          border: `1px solid ${C.border}`,
                          display: 'flex',
                          flexDirection: 'column',
                          gap: '8px',
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span style={{ fontSize: '14.5px', fontWeight: 700, color: C.dark }}>{b.serviceType}</span>
                          <span style={{ fontSize: '15px', fontWeight: 800, color: C.dark }}>₹{b.priceInr}</span>
                        </div>
                        <div style={{ fontSize: '12px', color: C.darkMuted }}>{b.scheduledAt} · {b.petName} ({b.species})</div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '6px', borderTop: `1px solid ${C.border}` }}>
                          <span style={{ fontSize: '11.5px', color: C.darkMuted }}>Owner: {b.ownerName}</span>
                          <span style={{ fontSize: '11px', fontWeight: 700, color: C.success, background: C.successBg, padding: '2px 6px', borderRadius: '4px' }}>
                            Completed & Paid
                          </span>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              )}

              {/* TAB 4: PROFILE */}
              {activeTab === 'profile' && (
                <div style={{ padding: '16px 20px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  {/* Profile Card */}
                  <div style={{ padding: '18px', background: C.surface, borderRadius: '16px', border: `1px solid ${C.border}` }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '14px', marginBottom: '14px' }}>
                      <img
                        src={activeProvider.profilePhoto || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80'}
                        alt={activeProvider.name}
                        style={{ width: '56px', height: '56px', borderRadius: '16px', objectFit: 'cover' }}
                      />
                      <div>
                        <div style={{ fontSize: '17px', fontWeight: 800, color: C.dark }}>{activeProvider.name}</div>
                        <div style={{ fontSize: '12px', color: C.sage, fontWeight: 700, display: 'flex', alignItems: 'center', gap: '4px', marginTop: '2px' }}>
                          <span>✓</span> Verified PetCare Provider
                        </div>
                      </div>
                    </div>

                    <div style={{ display: 'flex', gap: '12px', padding: '10px 0', borderTop: `1px solid ${C.border}`, borderBottom: `1px solid ${C.border}` }}>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: '11.5px', color: C.darkMuted }}>Rating</div>
                        <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark, marginTop: '2px' }}>
                          ★ {activeProvider.ratingAvg} ({activeProvider.ratingCount})
                        </div>
                      </div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: '11.5px', color: C.darkMuted }}>Experience</div>
                        <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark, marginTop: '2px' }}>
                          {activeProvider.yearsExperience} Years
                        </div>
                      </div>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontSize: '11.5px', color: C.darkMuted }}>Radius</div>
                        <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark, marginTop: '2px' }}>
                          {activeProvider.serviceRadiusKm} km
                        </div>
                      </div>
                    </div>

                    <div style={{ marginTop: '12px' }}>
                      <div style={{ fontSize: '12px', fontWeight: 700, color: C.dark, marginBottom: '4px' }}>About Caretaker</div>
                      <div style={{ fontSize: '12.5px', color: C.darkMuted, lineHeight: 1.4 }}>{activeProvider.bio}</div>
                    </div>
                  </div>

                  {/* Services Offered Card */}
                  <div style={{ padding: '16px', background: C.surface, borderRadius: '14px', border: `1px solid ${C.border}` }}>
                    <div style={{ fontSize: '14px', fontWeight: 700, color: C.dark, marginBottom: '10px' }}>
                      Services Offered & Pricing
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                      {activeProvider.services.map((s) => (
                        <div key={s.type} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '13px' }}>
                          <span style={{ color: s.enabled ? C.dark : C.darkLight, fontWeight: s.enabled ? 600 : 400 }}>
                            {s.label}
                          </span>
                          <span style={{ fontWeight: 700, color: s.enabled ? C.dark : C.darkLight }}>
                            {s.enabled ? `₹${s.priceInr}/session` : 'Not offered'}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Location Permission Note */}
                  <div style={{ padding: '14px 16px', background: C.sageLight, borderRadius: '12px', border: `1px solid ${C.sageBorder}` }}>
                    <div style={{ fontSize: '13px', fontWeight: 700, color: C.sage, marginBottom: '4px' }}>
                      📍 Device GPS Privacy Guarantee
                    </div>
                    <div style={{ fontSize: '12px', color: C.darkMuted, lineHeight: 1.4 }}>
                      Your GPS coordinates are only shared during an active service session after you tap <strong>Start Service</strong>. Tracking terminates the moment you tap <strong>Complete Service</strong>.
                    </div>
                  </div>

                  {/* Logout button */}
                  <button
                    onClick={() => {
                      setCurrentView('welcome');
                      showNotice('Provider logged out.');
                    }}
                    style={{
                      padding: '12px',
                      background: 'none',
                      color: C.coral,
                      border: `1px solid ${C.coralBorder}`,
                      borderRadius: '10px',
                      fontSize: '13.5px',
                      fontWeight: 600,
                      cursor: 'pointer',
                      marginTop: '8px',
                    }}
                  >
                    Log Out
                  </button>
                </div>
              )}
            </div>

            {/* Bottom Tabs Bar */}
            <div
              style={{
                padding: '10px 14px',
                borderTop: `1px solid ${C.border}`,
                background: C.surface,
                display: 'flex',
                justifyContent: 'space-around',
              }}
            >
              <button
                onClick={() => setActiveTab('requests')}
                style={{
                  background: 'none',
                  border: 'none',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: '4px',
                  cursor: 'pointer',
                  color: activeTab === 'requests' ? C.sage : C.darkLight,
                }}
              >
                <span style={{ fontSize: '18px' }}>📥</span>
                <span style={{ fontSize: '11px', fontWeight: activeTab === 'requests' ? 700 : 500 }}>
                  Requests {pendingRequests.length > 0 ? `(${pendingRequests.length})` : ''}
                </span>
              </button>

              <button
                onClick={() => setActiveTab('active')}
                style={{
                  background: 'none',
                  border: 'none',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: '4px',
                  cursor: 'pointer',
                  color: activeTab === 'active' ? C.sage : C.darkLight,
                }}
              >
                <span style={{ fontSize: '18px' }}>📋</span>
                <span style={{ fontSize: '11px', fontWeight: activeTab === 'active' ? 700 : 500 }}>
                  Active {activeJobs.length > 0 ? `(${activeJobs.length})` : ''}
                </span>
              </button>

              <button
                onClick={() => setActiveTab('history')}
                style={{
                  background: 'none',
                  border: 'none',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: '4px',
                  cursor: 'pointer',
                  color: activeTab === 'history' ? C.sage : C.darkLight,
                }}
              >
                <span style={{ fontSize: '18px' }}>⏱️</span>
                <span style={{ fontSize: '11px', fontWeight: activeTab === 'history' ? 700 : 500 }}>
                  History
                </span>
              </button>

              <button
                onClick={() => setActiveTab('profile')}
                style={{
                  background: 'none',
                  border: 'none',
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  gap: '4px',
                  cursor: 'pointer',
                  color: activeTab === 'profile' ? C.sage : C.darkLight,
                }}
              >
                <span style={{ fontSize: '18px' }}>👤</span>
                <span style={{ fontSize: '11px', fontWeight: activeTab === 'profile' ? 700 : 500 }}>
                  Profile
                </span>
              </button>
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
