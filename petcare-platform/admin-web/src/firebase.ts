import { initializeApp, FirebaseApp } from 'firebase/app';
import {
  getAuth,
  Auth,
  User,
  onAuthStateChanged as fbOnAuthStateChanged,
  signInWithEmailAndPassword as fbSignInWithEmailAndPassword,
  signOut as fbSignOut,
} from 'firebase/auth';

const hasFirebaseConfig = Boolean(
  import.meta.env.VITE_FIREBASE_API_KEY &&
    import.meta.env.VITE_FIREBASE_API_KEY !== 'your-api-key'
);

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || 'mock-api-key',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || 'localhost',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'petcare-mock',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || '1:000000000000:web:mock',
};

let firebaseAppInstance: FirebaseApp | null = null;
let realAuth: Auth | null = null;

if (hasFirebaseConfig) {
  try {
    firebaseAppInstance = initializeApp(firebaseConfig);
    realAuth = getAuth(firebaseAppInstance);
  } catch (e) {
    console.warn('[AI Studio] Firebase initialization failed — using in-memory auth mock:', e);
  }
}

type AuthListener = (user: User | null) => void;
const listeners = new Set<AuthListener>();

function createMockUser(email: string): User {
  return {
    uid: 'mock-admin-uid',
    email,
    displayName: 'PetCare Staff Admin',
    emailVerified: true,
    isAnonymous: false,
    metadata: {},
    providerData: [],
    refreshToken: 'mock-refresh-token',
    tenantId: null,
    delete: async () => {},
    getIdToken: async () => 'mock-id-token',
    getIdTokenResult: async () => ({
      token: 'mock-id-token',
      authTime: new Date().toISOString(),
      issuedAtTime: new Date().toISOString(),
      expirationTime: new Date(Date.now() + 3600_000).toISOString(),
      signInProvider: 'password',
      signInSecondFactor: null,
      claims: { role: 'ADMIN' },
    }),
    reload: async () => {},
    toJSON: () => ({ uid: 'mock-admin-uid', email }),
    phoneNumber: null,
    photoURL: null,
    providerId: 'firebase',
  };
}

let mockCurrentUser: User | null = createMockUser('ops@petcare.in');

function notifyListeners() {
  for (const listener of listeners) {
    listener(mockCurrentUser);
  }
}

export const firebaseApp = firebaseAppInstance;

export const auth = (realAuth ?? {
  get currentUser() {
    return mockCurrentUser;
  },
}) as Auth;

export function onAuthStateChanged(
  authInstance: Auth,
  callback: (user: User | null) => void
): () => void {
  if (realAuth) {
    return fbOnAuthStateChanged(authInstance, callback);
  }
  listeners.add(callback);
  queueMicrotask(() => callback(mockCurrentUser));
  return () => {
    listeners.delete(callback);
  };
}

export async function signInWithEmailAndPassword(
  authInstance: Auth,
  email: string,
  password: string
) {
  if (realAuth) {
    return fbSignInWithEmailAndPassword(authInstance, email, password);
  }
  if (!email || !password) {
    throw new Error('Missing email or password');
  }
  mockCurrentUser = createMockUser(email);
  notifyListeners();
  return { user: mockCurrentUser };
}

export async function signOut(authInstance: Auth): Promise<void> {
  if (realAuth) {
    return fbSignOut(authInstance);
  }
  mockCurrentUser = null;
  notifyListeners();
}

export type { User };
