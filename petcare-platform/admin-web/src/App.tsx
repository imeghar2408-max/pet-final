import React, { useState } from 'react';
import ProviderAppInteractivePreview from './components/ProviderAppInteractivePreview';
import UserAppInteractivePreview from './components/UserAppInteractivePreview';
import ProviderVerificationPage from './pages/ProviderVerificationPage';

export default function App() {
  const [activeApp, setActiveApp] = useState<'provider' | 'owner' | 'admin'>('provider');

  return (
    <div style={{ minHeight: '100vh', background: '#F4F3EE', display: 'flex', flexDirection: 'column' }}>
      {/* Top Marketplace Switcher Bar */}
      <header
        style={{
          background: '#FFFFFF',
          borderBottom: '1px solid #E5E2DA',
          padding: '8px 16px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          position: 'sticky',
          top: 0,
          zIndex: 100,
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <div
            style={{
              width: '28px',
              height: '28px',
              borderRadius: '8px',
              background: activeApp === 'provider' ? '#EBF3EF' : activeApp === 'owner' ? '#FAF9F6' : '#EEF2F6',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '15px',
            }}
          >
            🐾
          </div>
          <span style={{ fontSize: '14px', fontWeight: 700, color: '#1A1F1D' }}>
            PetCare Platform
          </span>
          <span style={{ fontSize: '12px', color: '#6B7280' }}>· Two-Sided Marketplace</span>
        </div>

        {/* Segmented Control */}
        <div
          style={{
            display: 'flex',
            background: '#F3F1EC',
            padding: '3px',
            borderRadius: '9px',
            gap: '2px',
          }}
        >
          <button
            onClick={() => setActiveApp('provider')}
            style={{
              padding: '6px 14px',
              borderRadius: '7px',
              border: 'none',
              background: activeApp === 'provider' ? '#FFFFFF' : 'transparent',
              color: activeApp === 'provider' ? '#2E6B56' : '#6B7280',
              fontWeight: activeApp === 'provider' ? 700 : 500,
              fontSize: '12.5px',
              cursor: 'pointer',
              boxShadow: activeApp === 'provider' ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            Provider App
          </button>
          <button
            onClick={() => setActiveApp('owner')}
            style={{
              padding: '6px 14px',
              borderRadius: '7px',
              border: 'none',
              background: activeApp === 'owner' ? '#FFFFFF' : 'transparent',
              color: activeApp === 'owner' ? '#1A1F1D' : '#6B7280',
              fontWeight: activeApp === 'owner' ? 700 : 500,
              fontSize: '12.5px',
              cursor: 'pointer',
              boxShadow: activeApp === 'owner' ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            Pet Owner App
          </button>
          <button
            onClick={() => setActiveApp('admin')}
            style={{
              padding: '6px 14px',
              borderRadius: '7px',
              border: 'none',
              background: activeApp === 'admin' ? '#FFFFFF' : 'transparent',
              color: activeApp === 'admin' ? '#1E3A8A' : '#6B7280',
              fontWeight: activeApp === 'admin' ? 700 : 500,
              fontSize: '12.5px',
              cursor: 'pointer',
              boxShadow: activeApp === 'admin' ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            🛡️ Admin Ops Portal
          </button>
        </div>
      </header>

      {/* Main App Container */}
      <main style={{ flex: 1 }}>
        {activeApp === 'provider' ? (
          <ProviderAppInteractivePreview />
        ) : activeApp === 'owner' ? (
          <UserAppInteractivePreview />
        ) : (
          <div style={{ maxWidth: '1200px', margin: '0 auto', padding: '24px 20px' }}>
            <ProviderVerificationPage />
          </div>
        )}
      </main>
    </div>
  );
}
