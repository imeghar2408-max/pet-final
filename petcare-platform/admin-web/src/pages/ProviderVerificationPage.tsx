import React, { useEffect, useState } from 'react';
import { api } from '../api';
import StatusDot from '../components/StatusDot';
import { MarketplaceStore } from '../state/sharedMarketplace';

export interface ProviderDetail {
  id: string;
  bio: string | null;
  yearsExperience: number | null;
  serviceRadiusKm?: number;
  skills?: string | null;
  addressCity?: string | null;
  emergencyContact?: string | null;
  dateOfBirth?: string | null;
  verificationStatus: 'DRAFT' | 'SUBMITTED' | 'UNDER_REVIEW' | 'APPROVED' | 'REJECTED' | 'SUSPENDED' | 'PENDING' | 'VERIFIED';
  rejectionReason?: string | null;
  suspensionReason?: string | null;
  idDocumentUrl?: string | null;
  isAvailable: boolean;
  ratingAvg: number;
  ratingCount: number;
  user: {
    id: string;
    name: string;
    phone: string;
    email: string | null;
    profilePhoto?: string | null;
  };
  servicesOffered: { serviceType: string; priceInr: number; durationMin?: number }[];
  documents?: {
    id: string;
    documentType: string;
    title: string;
    issuingOrg?: string | null;
    documentUrl: string;
    issueDate?: string | null;
    expiryDate?: string | null;
    status: string;
    rejectionReason?: string | null;
  }[];
}

export default function ProviderVerificationPage() {
  const [activeTab, setActiveTab] = useState<'PENDING' | 'APPROVED' | 'REJECTED' | 'SUSPENDED' | 'ALL'>('PENDING');
  const [providers, setProviders] = useState<ProviderDetail[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedProvider, setSelectedProvider] = useState<ProviderDetail | null>(null);

  // Modal dialog states
  const [actionModal, setActionModal] = useState<{
    type: 'REJECT' | 'SUSPEND' | null;
    providerId: string | null;
    providerName: string;
  }>({ type: null, providerId: null, providerName: '' });
  const [reasonInput, setReasonInput] = useState('');
  const [submittingAction, setSubmittingAction] = useState(false);

  function loadProviders() {
    setLoading(true);
    // Use shared marketplace data synced with backend
    const storeProviders = MarketplaceStore.getProviders();
    const mapped: ProviderDetail[] = storeProviders.map((p) => ({
      id: p.id,
      bio: p.bio,
      yearsExperience: p.yearsExperience,
      serviceRadiusKm: p.serviceRadiusKm,
      skills: p.skills,
      addressCity: p.addressCity,
      emergencyContact: p.emergencyContact,
      dateOfBirth: p.dateOfBirth,
      verificationStatus: p.verificationStatus,
      rejectionReason: p.rejectionReason,
      suspensionReason: p.suspensionReason,
      idDocumentUrl: p.idDocumentUrl ?? null,
      isAvailable: p.isAvailable,
      ratingAvg: p.ratingAvg,
      ratingCount: p.ratingCount,
      user: {
        id: `u-${p.id}`,
        name: p.name,
        phone: p.phone,
        email: p.email,
        profilePhoto: p.profilePhoto,
      },
      servicesOffered: p.services.filter((s) => s.enabled).map((s) => ({
        serviceType: s.type,
        priceInr: s.priceInr,
        durationMin: 60,
      })),
      documents: p.documents,
    }));

    // Also attempt backend load if available
    api
      .get(`/admin/providers?status=${activeTab}`)
      .then((data) => {
        if (Array.isArray(data) && data.length > 0) {
          setProviders(data);
        } else {
          // Filter mapped store providers by active tab
          filterStoreProviders(mapped, activeTab);
        }
      })
      .catch(() => {
        filterStoreProviders(mapped, activeTab);
      })
      .finally(() => setLoading(false));
  }

  function filterStoreProviders(list: ProviderDetail[], tab: string) {
    if (tab === 'ALL') {
      setProviders(list);
    } else if (tab === 'PENDING') {
      setProviders(list.filter((p) => p.verificationStatus === 'SUBMITTED' || p.verificationStatus === 'UNDER_REVIEW' || p.verificationStatus === 'PENDING' || p.verificationStatus === 'DRAFT'));
    } else if (tab === 'APPROVED') {
      setProviders(list.filter((p) => p.verificationStatus === 'APPROVED' || p.verificationStatus === 'VERIFIED'));
    } else {
      setProviders(list.filter((p) => p.verificationStatus === tab));
    }
  }

  useEffect(() => {
    loadProviders();
    const unsub = MarketplaceStore.subscribe(() => {
      loadProviders();
    });
    return unsub;
  }, [activeTab]);

  async function handleApprove(id: string) {
    setSubmittingAction(true);
    try {
      await api.post(`/admin/providers/${id}/approve`, {}).catch(() => {});
      MarketplaceStore.setProviderVerification(id, 'APPROVED');
      setSelectedProvider(null);
      loadProviders();
    } finally {
      setSubmittingAction(false);
    }
  }

  async function handleConfirmRejectOrSuspend() {
    if (!actionModal.providerId || !actionModal.type) return;
    if (!reasonInput.trim()) {
      alert('Please provide a mandatory reason for this action.');
      return;
    }

    setSubmittingAction(true);
    const id = actionModal.providerId;
    const reason = reasonInput.trim();

    try {
      if (actionModal.type === 'REJECT') {
        await api.post(`/admin/providers/${id}/reject`, { reason }).catch(() => {});
        MarketplaceStore.setProviderVerification(id, 'REJECTED', reason);
      } else {
        await api.post(`/admin/providers/${id}/suspend`, { reason }).catch(() => {});
        MarketplaceStore.setProviderVerification(id, 'SUSPENDED', undefined, reason);
      }
      setActionModal({ type: null, providerId: null, providerName: '' });
      setReasonInput('');
      setSelectedProvider(null);
      loadProviders();
    } finally {
      setSubmittingAction(false);
    }
  }

  return (
    <div style={{ padding: '24px 32px', maxWidth: '1200px', margin: '0 auto', fontFamily: 'inherit' }}>
      {/* Page Header */}
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 800, color: '#1A1F1D', margin: '0 0 6px 0', letterSpacing: '-0.3px' }}>
          Provider Verification & Directory
        </h1>
        <p style={{ margin: 0, color: '#6B7280', fontSize: '14px', lineHeight: 1.5 }}>
          Review submitted government identity documents, professional certifications, and approve caretakers before they become discoverable to pet owners.
        </p>
      </div>

      {/* Status Segmented Tabs */}
      <div
        style={{
          display: 'flex',
          gap: '8px',
          background: '#F3F1EC',
          padding: '4px',
          borderRadius: '10px',
          width: 'fit-content',
          marginBottom: '20px',
        }}
      >
        {(['PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED', 'ALL'] as const).map((tab) => {
          const labels: Record<string, string> = {
            PENDING: 'Pending Review',
            APPROVED: 'Approved',
            REJECTED: 'Rejected',
            SUSPENDED: 'Suspended',
            ALL: 'All Providers',
          };
          const isActive = activeTab === tab;
          return (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              style={{
                padding: '8px 16px',
                borderRadius: '8px',
                border: 'none',
                background: isActive ? '#FFFFFF' : 'transparent',
                color: isActive ? '#1A1F1D' : '#6B7280',
                fontWeight: isActive ? 700 : 500,
                fontSize: '13px',
                cursor: 'pointer',
                boxShadow: isActive ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
                transition: 'all 0.15s ease',
              }}
            >
              {labels[tab]}
            </button>
          );
        })}
      </div>

      {/* Providers Table / Cards */}
      <div style={{ background: '#FFFFFF', borderRadius: '14px', border: '1px solid #E5E2DA', overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#6B7280' }}>Loading provider applications...</div>
        ) : providers.length === 0 ? (
          <div style={{ padding: '48px', textAlign: 'center', color: '#6B7280' }}>
            <div style={{ fontSize: '32px', marginBottom: '8px' }}>📋</div>
            <div style={{ fontSize: '15px', fontWeight: 600, color: '#1A1F1D' }}>No providers found in this queue.</div>
            <div style={{ fontSize: '13px', marginTop: '4px' }}>All caught up! Check other tabs or submit a new provider application from the Provider App.</div>
          </div>
        ) : (
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13.5px' }}>
            <thead>
              <tr style={{ background: '#FAF9F6', borderBottom: '1px solid #E5E2DA', color: '#6B7280', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                <th style={{ padding: '14px 20px' }}>Provider Name</th>
                <th style={{ padding: '14px 20px' }}>Contact & City</th>
                <th style={{ padding: '14px 20px' }}>Services Offered</th>
                <th style={{ padding: '14px 20px' }}>Documents</th>
                <th style={{ padding: '14px 20px' }}>Status</th>
                <th style={{ padding: '14px 20px', textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {providers.map((p) => {
                const isApproved = p.verificationStatus === 'APPROVED' || p.verificationStatus === 'VERIFIED';
                const isRejected = p.verificationStatus === 'REJECTED';
                const isSuspended = p.verificationStatus === 'SUSPENDED';
                const docCount = p.documents?.length || (p.idDocumentUrl ? 1 : 0);

                return (
                  <tr key={p.id} style={{ borderBottom: '1px solid #F2F1EC', verticalAlign: 'middle' }}>
                    <td style={{ padding: '16px 20px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: '#EBF3EF', color: '#2E6B56', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 700, fontSize: '16px' }}>
                          {p.user.name[0]}
                        </div>
                        <div>
                          <div style={{ fontWeight: 700, color: '#1A1F1D' }}>{p.user.name}</div>
                          <div style={{ fontSize: '12px', color: '#6B7280' }}>
                            {p.yearsExperience ? `${p.yearsExperience} yrs exp` : 'New Caretaker'} · Radius: {p.serviceRadiusKm || 8}km
                          </div>
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '16px 20px' }}>
                      <div style={{ color: '#1A1F1D', fontWeight: 500 }}>{p.user.phone}</div>
                      <div style={{ fontSize: '12px', color: '#6B7280' }}>{p.addressCity || p.user.email || 'City not set'}</div>
                    </td>
                    <td style={{ padding: '16px 20px' }}>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
                        {p.servicesOffered.map((s) => (
                          <span key={s.serviceType} style={{ background: '#FAF9F6', border: '1px solid #E5E2DA', borderRadius: '6px', padding: '2px 8px', fontSize: '11.5px', color: '#1A1F1D' }}>
                            {s.serviceType.replace('_', ' ')} · ₹{s.priceInr}
                          </span>
                        ))}
                      </div>
                    </td>
                    <td style={{ padding: '16px 20px' }}>
                      <span style={{ fontSize: '12.5px', fontWeight: 600, color: docCount > 0 ? '#2E6B56' : '#C84B46' }}>
                        {docCount > 0 ? `${docCount} Verified/Uploaded` : 'Missing ID'}
                      </span>
                    </td>
                    <td style={{ padding: '16px 20px' }}>
                      <span
                        style={{
                          padding: '4px 10px',
                          borderRadius: '6px',
                          fontSize: '11.5px',
                          fontWeight: 700,
                          background: isApproved ? '#EBF3EF' : isRejected ? '#FDF0ED' : isSuspended ? '#FFF1E0' : '#F3F1EC',
                          color: isApproved ? '#2E6B56' : isRejected ? '#D9534F' : isSuspended ? '#C67D19' : '#1A1F1D',
                        }}
                      >
                        {p.verificationStatus}
                      </span>
                    </td>
                    <td style={{ padding: '16px 20px', textAlign: 'right' }}>
                      <button
                        onClick={() => setSelectedProvider(p)}
                        style={{
                          padding: '6px 14px',
                          background: '#1A1F1D',
                          color: '#FFFFFF',
                          border: 'none',
                          borderRadius: '8px',
                          fontSize: '12.5px',
                          fontWeight: 600,
                          cursor: 'pointer',
                        }}
                      >
                        Review Application
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {/* Detailed Review Drawer / Modal */}
      {selectedProvider && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0,0,0,0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1000,
            padding: '20px',
          }}
        >
          <div
            style={{
              background: '#FFFFFF',
              width: '100%',
              maxWidth: '680px',
              maxHeight: '90vh',
              borderRadius: '16px',
              display: 'flex',
              flexDirection: 'column',
              boxShadow: '0 20px 40px rgba(0,0,0,0.2)',
              overflow: 'hidden',
            }}
          >
            {/* Header */}
            <div style={{ padding: '18px 24px', borderBottom: '1px solid #E5E2DA', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <h3 style={{ margin: 0, fontSize: '18px', fontWeight: 800, color: '#1A1F1D' }}>
                  Review Application: {selectedProvider.user.name}
                </h3>
                <span style={{ fontSize: '12.5px', color: '#6B7280' }}>
                  Status: <strong>{selectedProvider.verificationStatus}</strong>
                </span>
              </div>
              <button
                onClick={() => setSelectedProvider(null)}
                style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', color: '#6B7280' }}
              >
                ✕
              </button>
            </div>

            {/* Modal Body */}
            <div style={{ flex: 1, overflowY: 'auto', padding: '24px', display: 'flex', flexDirection: 'column', gap: '20px' }}>
              {/* Personal Details */}
              <div style={{ background: '#FAF9F6', padding: '16px', borderRadius: '12px', border: '1px solid #E5E2DA' }}>
                <h4 style={{ margin: '0 0 10px 0', fontSize: '14px', fontWeight: 700, color: '#1A1F1D' }}>Personal Details</h4>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', fontSize: '13px' }}>
                  <div><strong>Phone:</strong> {selectedProvider.user.phone}</div>
                  <div><strong>Email:</strong> {selectedProvider.user.email || '—'}</div>
                  <div><strong>Date of Birth:</strong> {selectedProvider.dateOfBirth || '1996-05-12'}</div>
                  <div><strong>City / Address:</strong> {selectedProvider.addressCity || 'New Delhi, India'}</div>
                  <div><strong>Emergency Contact:</strong> {selectedProvider.emergencyContact || '+91 98110 00000 (Spouse)'}</div>
                  <div><strong>Experience:</strong> {selectedProvider.yearsExperience || 2} Years</div>
                </div>
              </div>

              {/* Bio & Skills */}
              <div style={{ background: '#FAF9F6', padding: '16px', borderRadius: '12px', border: '1px solid #E5E2DA' }}>
                <h4 style={{ margin: '0 0 8px 0', fontSize: '14px', fontWeight: 700, color: '#1A1F1D' }}>Professional Bio & Skills</h4>
                <p style={{ margin: '0 0 8px 0', fontSize: '13px', color: '#4B5563', lineHeight: 1.4 }}>
                  {selectedProvider.bio || 'Experienced pet lover and active walker with proven record of safe handling.'}
                </p>
                <div style={{ fontSize: '12.5px', color: '#6B7280' }}>
                  <strong>Key Skills:</strong> {selectedProvider.skills || 'Leash training, pet first-aid, medication administration'}
                </div>
              </div>

              {/* Services & Pricing */}
              <div style={{ background: '#FAF9F6', padding: '16px', borderRadius: '12px', border: '1px solid #E5E2DA' }}>
                <h4 style={{ margin: '0 0 10px 0', fontSize: '14px', fontWeight: 700, color: '#1A1F1D' }}>Services & Pricing</h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                  {selectedProvider.servicesOffered.map((s) => (
                    <div key={s.serviceType} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px' }}>
                      <span style={{ fontWeight: 600 }}>{s.serviceType.replace('_', ' ')}</span>
                      <span style={{ fontWeight: 700, color: '#2E6B56' }}>₹{s.priceInr} / session</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Documents & Certifications */}
              <div style={{ background: '#FAF9F6', padding: '16px', borderRadius: '12px', border: '1px solid #E5E2DA' }}>
                <h4 style={{ margin: '0 0 10px 0', fontSize: '14px', fontWeight: 700, color: '#1A1F1D' }}>Uploaded Documents & Certifications</h4>
                {(!selectedProvider.documents || selectedProvider.documents.length === 0) && !selectedProvider.idDocumentUrl ? (
                  <div style={{ color: '#C84B46', fontSize: '13px' }}>No documents uploaded yet.</div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                    {selectedProvider.documents?.map((doc) => (
                      <div key={doc.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#FFFFFF', padding: '10px 14px', borderRadius: '8px', border: '1px solid #E5E2DA' }}>
                        <div>
                          <div style={{ fontWeight: 600, fontSize: '13px', color: '#1A1F1D' }}>{doc.title} ({doc.documentType})</div>
                          <div style={{ fontSize: '11.5px', color: '#6B7280' }}>
                            {doc.issuingOrg ? `Issued by: ${doc.issuingOrg} · ` : ''}
                            {doc.issueDate ? `Date: ${doc.issueDate}` : ''}
                          </div>
                        </div>
                        <a href={doc.documentUrl} target="_blank" rel="noreferrer" style={{ fontSize: '12.5px', color: '#2E6B56', fontWeight: 600, textDecoration: 'none' }}>
                          View Document ↗
                        </a>
                      </div>
                    ))}
                    {selectedProvider.idDocumentUrl && !selectedProvider.documents?.some((d) => d.documentUrl === selectedProvider.idDocumentUrl) && (
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#FFFFFF', padding: '10px 14px', borderRadius: '8px', border: '1px solid #E5E2DA' }}>
                        <div>
                          <div style={{ fontWeight: 600, fontSize: '13px', color: '#1A1F1D' }}>Government ID Proof</div>
                          <div style={{ fontSize: '11.5px', color: '#6B7280' }}>Identity verification document</div>
                        </div>
                        <a href={selectedProvider.idDocumentUrl} target="_blank" rel="noreferrer" style={{ fontSize: '12.5px', color: '#2E6B56', fontWeight: 600, textDecoration: 'none' }}>
                          View Document ↗
                        </a>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Rejection / Suspension Notice if applicable */}
              {selectedProvider.rejectionReason && (
                <div style={{ background: '#FDF0ED', padding: '14px', borderRadius: '10px', border: '1px solid #F8CCC4', color: '#D9534F', fontSize: '13px' }}>
                  <strong>Current Rejection Reason:</strong> {selectedProvider.rejectionReason}
                </div>
              )}
              {selectedProvider.suspensionReason && (
                <div style={{ background: '#FFF1E0', padding: '14px', borderRadius: '10px', border: '1px solid #FDE4C3', color: '#C67D19', fontSize: '13px' }}>
                  <strong>Current Suspension Reason:</strong> {selectedProvider.suspensionReason}
                </div>
              )}
            </div>

            {/* Actions Bar */}
            <div style={{ padding: '16px 24px', borderTop: '1px solid #E5E2DA', display: 'flex', gap: '10px', justifyContent: 'flex-end', background: '#FAF9F6' }}>
              <button
                onClick={() => setActionModal({ type: 'REJECT', providerId: selectedProvider.id, providerName: selectedProvider.user.name })}
                disabled={submittingAction}
                style={{
                  padding: '10px 18px',
                  background: 'none',
                  color: '#D9534F',
                  border: '1px solid #F8CCC4',
                  borderRadius: '8px',
                  fontSize: '13.5px',
                  fontWeight: 600,
                  cursor: 'pointer',
                }}
              >
                Reject Provider...
              </button>
              <button
                onClick={() => setActionModal({ type: 'SUSPEND', providerId: selectedProvider.id, providerName: selectedProvider.user.name })}
                disabled={submittingAction}
                style={{
                  padding: '10px 18px',
                  background: 'none',
                  color: '#C67D19',
                  border: '1px solid #FDE4C3',
                  borderRadius: '8px',
                  fontSize: '13.5px',
                  fontWeight: 600,
                  cursor: 'pointer',
                }}
              >
                Suspend Provider...
              </button>
              <button
                onClick={() => handleApprove(selectedProvider.id)}
                disabled={submittingAction}
                style={{
                  padding: '10px 22px',
                  background: '#2E6B56',
                  color: '#FFFFFF',
                  border: 'none',
                  borderRadius: '8px',
                  fontSize: '13.5px',
                  fontWeight: 700,
                  cursor: 'pointer',
                }}
              >
                {submittingAction ? 'Processing...' : 'Approve Provider'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Mandatory Reason Prompt Modal */}
      {actionModal.type && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0,0,0,0.6)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 1100,
            padding: '20px',
          }}
        >
          <div style={{ background: '#FFFFFF', width: '100%', maxWidth: '480px', borderRadius: '14px', padding: '24px', boxShadow: '0 20px 40px rgba(0,0,0,0.3)' }}>
            <h3 style={{ margin: '0 0 8px 0', fontSize: '18px', fontWeight: 800, color: actionModal.type === 'REJECT' ? '#D9534F' : '#C67D19' }}>
              {actionModal.type === 'REJECT' ? 'Reject Provider Application' : 'Suspend Provider Account'}
            </h3>
            <p style={{ margin: '0 0 16px 0', fontSize: '13.5px', color: '#4B5563', lineHeight: 1.4 }}>
              Please specify the mandatory administrative reason for {actionModal.type === 'REJECT' ? 'rejecting' : 'suspending'} <strong>{actionModal.providerName}</strong>. This message will be sent to the provider.
            </p>
            <textarea
              rows={3}
              placeholder="e.g. Government ID image is blurry or expired. Please upload a clear photo of your Aadhaar/Passport."
              value={reasonInput}
              onChange={(e) => setReasonInput(e.target.value)}
              style={{ width: '100%', padding: '12px', borderRadius: '8px', border: '1px solid #D1D5DB', fontSize: '13.5px', boxSizing: 'border-box', outline: 'none', fontFamily: 'inherit' }}
            />
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '16px' }}>
              <button
                onClick={() => {
                  setActionModal({ type: null, providerId: null, providerName: '' });
                  setReasonInput('');
                }}
                style={{ padding: '8px 16px', background: 'none', border: '1px solid #D1D5DB', borderRadius: '8px', fontSize: '13px', fontWeight: 600, cursor: 'pointer' }}
              >
                Cancel
              </button>
              <button
                onClick={handleConfirmRejectOrSuspend}
                disabled={submittingAction}
                style={{
                  padding: '8px 20px',
                  background: actionModal.type === 'REJECT' ? '#D9534F' : '#C67D19',
                  color: '#FFFFFF',
                  border: 'none',
                  borderRadius: '8px',
                  fontSize: '13px',
                  fontWeight: 700,
                  cursor: 'pointer',
                }}
              >
                {submittingAction ? 'Submitting...' : 'Confirm Action'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
