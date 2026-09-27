import { auth } from './firebase';

const BASE_URL = import.meta.env.VITE_API_BASE_URL || '';

// In-memory fallback store used when no backend database is connected
const mockStore = {
  activeProviders: 18,
  totalOwners: 64,
  revenueInr: 42850,
  pendingProviders: [
    {
      id: 'prv_901a',
      bio: 'Certified canine behaviorist and daily walker covering South Delhi & Gurgaon.',
      yearsExperience: 5,
      idDocumentUrl: 'https://example.com/docs/aadhaar-verified-901a.pdf',
      user: { name: 'Aarav Sharma', phone: '+91 98110 44210', email: 'aarav.sharma@example.com' },
      servicesOffered: [
        { serviceType: 'WALKING', priceInr: 350 },
        { serviceType: 'TRAINING', priceInr: 1200 },
      ],
    },
    {
      id: 'prv_902b',
      bio: 'Gentle home grooming and mobile spa care for dogs and cats.',
      yearsExperience: 3,
      idDocumentUrl: 'https://example.com/docs/pan-verified-902b.pdf',
      user: { name: 'Meera Nair', phone: '+91 98201 77319', email: 'meera.nair@example.com' },
      servicesOffered: [
        { serviceType: 'GROOMING', priceInr: 950 },
        { serviceType: 'BOARDING', priceInr: 1500 },
      ],
    },
    {
      id: 'prv_903c',
      bio: 'Veterinary assistant available for clinic accompaniment and post-op home visits.',
      yearsExperience: 4,
      idDocumentUrl: null,
      user: { name: 'Rohan Kulkarni', phone: '+91 97654 11890', email: null },
      servicesOffered: [{ serviceType: 'VET_VISIT', priceInr: 800 }],
    },
  ],
  bookings: [
    {
      id: 'bkg_7810',
      serviceType: 'WALKING',
      status: 'IN_PROGRESS',
      scheduledAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
      priceInr: 350,
      pet: { name: 'Bruno' },
      petOwner: { user: { name: 'Priya Menon' } },
      provider: { user: { name: 'Vikram Singh' } },
      payment: { status: 'PENDING' },
    },
    {
      id: 'bkg_7809',
      serviceType: 'GROOMING',
      status: 'COMPLETED',
      scheduledAt: new Date(Date.now() - 4 * 3600 * 1000).toISOString(),
      priceInr: 950,
      pet: { name: 'Mochi' },
      petOwner: { user: { name: 'Karan Malhotra' } },
      provider: { user: { name: 'Ananya Rao' } },
      payment: { status: 'PAID' },
    },
    {
      id: 'bkg_7808',
      serviceType: 'BOARDING',
      status: 'ACCEPTED',
      scheduledAt: new Date(Date.now() + 6 * 3600 * 1000).toISOString(),
      priceInr: 1500,
      pet: { name: 'Simba' },
      petOwner: { user: { name: 'Neha Kapoor' } },
      provider: { user: { name: 'Kabir Joshi' } },
      payment: { status: 'PENDING' },
    },
    {
      id: 'bkg_7807',
      serviceType: 'VET_VISIT',
      status: 'REQUESTED',
      scheduledAt: new Date(Date.now() + 24 * 3600 * 1000).toISOString(),
      priceInr: 800,
      pet: { name: 'Bella' },
      petOwner: { user: { name: 'Siddharth Verma' } },
      provider: null,
      payment: null,
    },
    {
      id: 'bkg_7806',
      serviceType: 'TRAINING',
      status: 'COMPLETED',
      scheduledAt: new Date(Date.now() - 28 * 3600 * 1000).toISOString(),
      priceInr: 1200,
      pet: { name: 'Coco' },
      petOwner: { user: { name: 'Divya Iyer' } },
      provider: { user: { name: 'Vikram Singh' } },
      payment: { status: 'PAID' },
    },
  ],
  complaints: [
    {
      id: 'cmp_301',
      category: 'SAFE_ZONE_BREACH',
      subject: 'Walker briefly exited the 500m safe zone radius',
      description:
        'Received a safe-zone alert during evening walk near Lodhi Garden. Would like confirmation that GPS route was logged.',
      status: 'OPEN' as 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED',
      adminNote: null as string | null,
      createdAt: new Date(Date.now() - 2 * 3600 * 1000).toISOString(),
      reportedBy: { name: 'Priya Menon', phone: '+91 98102 33412', role: 'PET_OWNER' },
      booking: {
        id: 'bkg_7810',
        serviceType: 'WALKING',
        pet: { name: 'Bruno' },
        provider: { user: { name: 'Vikram Singh' } },
      },
    },
    {
      id: 'cmp_300',
      category: 'PAYMENT_ISSUE',
      subject: 'UPI payment debited twice on Razorpay checkout',
      description:
        'First UPI collect attempt timed out so I paid via QR code, but both transactions were debited from HDFC account.',
      status: 'IN_PROGRESS' as 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED',
      adminNote: 'Checking Razorpay order settlement IDs with finance.',
      createdAt: new Date(Date.now() - 18 * 3600 * 1000).toISOString(),
      reportedBy: { name: 'Karan Malhotra', phone: '+91 98188 90123', role: 'PET_OWNER' },
      booking: {
        id: 'bkg_7809',
        serviceType: 'GROOMING',
        pet: { name: 'Mochi' },
        provider: { user: { name: 'Ananya Rao' } },
      },
    },
  ],
};

function handleMockRequest(path: string, options: RequestInit = {}): unknown {
  const method = (options.method || 'GET').toUpperCase();
  const body = options.body ? JSON.parse(String(options.body)) : {};

  if (method === 'GET' && path === '/admin/metrics') {
    const bookingsByStatus: Record<string, number> = {};
    for (const b of mockStore.bookings) {
      bookingsByStatus[b.status] = (bookingsByStatus[b.status] || 0) + 1;
    }
    const openComplaints = mockStore.complaints.filter(
      (c) => c.status === 'OPEN' || c.status === 'IN_PROGRESS'
    ).length;
    return {
      totalBookings: mockStore.bookings.length,
      pendingVerifications: mockStore.pendingProviders.length,
      activeProviders: mockStore.activeProviders,
      totalOwners: mockStore.totalOwners,
      revenueInr: mockStore.revenueInr,
      openComplaints,
      bookingsByStatus,
    };
  }

  if (method === 'GET' && path === '/admin/providers/pending') {
    return [...mockStore.pendingProviders];
  }

  const verifyMatch = path.match(/^\/admin\/providers\/([^/]+)\/verify$/);
  if (method === 'POST' && verifyMatch) {
    const id = verifyMatch[1];
    mockStore.pendingProviders = mockStore.pendingProviders.filter((p) => p.id !== id);
    if (body?.approve) {
      mockStore.activeProviders += 1;
    }
    return { id, verificationStatus: body?.approve ? 'VERIFIED' : 'REJECTED' };
  }

  if (method === 'GET' && path === '/admin/bookings') {
    return [...mockStore.bookings];
  }

  if (method === 'GET' && path.startsWith('/admin/complaints')) {
    const url = new URL(path, 'http://localhost');
    const statusFilter = url.searchParams.get('status');
    return mockStore.complaints.filter((c) => !statusFilter || c.status === statusFilter);
  }

  const complaintStatusMatch = path.match(/^\/admin\/complaints\/([^/]+)\/status$/);
  if (method === 'POST' && complaintStatusMatch) {
    const id = complaintStatusMatch[1];
    const target = mockStore.complaints.find((c) => c.id === id);
    if (target) {
      target.status = body.status;
      target.adminNote = body.adminNote ?? null;
    }
    return target ?? { id, status: body.status };
  }

  return null;
}

async function request(path: string, options: RequestInit = {}) {
  const token = await auth.currentUser?.getIdToken();
  try {
    const res = await fetch(`${BASE_URL}${path}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...options.headers,
      },
    });
    const contentType = res.headers.get('content-type') || '';
    if (res.ok && (res.status === 204 || contentType.includes('application/json'))) {
      return res.status === 204 ? null : res.json();
    }
  } catch {
    // Fall through to in-memory mock when backend is offline
  }
  return handleMockRequest(path, options);
}

export const api = {
  get: (path: string) => request(path),
  post: (path: string, data?: unknown) =>
    request(path, { method: 'POST', body: data ? JSON.stringify(data) : undefined }),
};
