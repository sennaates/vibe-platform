"use client"

import { createContext, useContext, useEffect, useState } from "react"
import { onAuthStateChanged, User } from "firebase/auth"
import { doc, onSnapshot, updateDoc } from "firebase/firestore"
import { auth, db } from "@/lib/firebase"
import { SocialUser } from "@/types"

interface AuthContextType {
  user: User | null
  profile: SocialUser | null
  loading: boolean
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  profile: null,
  loading: true,
})

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [profile, setProfile] = useState<SocialUser | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let unsubProfile: (() => void) | null = null

    // Fallback timer: if auth/profile doesn't resolve in 4.0 seconds, set loading to false
    const fallbackTimer = setTimeout(() => {
      setLoading((currentLoading) => {
        if (currentLoading) {
          console.warn("Auth/Profile initialization timed out. Falling back to guest/cache mode.");
          return false;
        }
        return currentLoading;
      });
    }, 4000);

    const unsubAuth = onAuthStateChanged(auth, (firebaseUser) => {
      setUser(firebaseUser);

      if (unsubProfile) {
        unsubProfile();
        unsubProfile = null;
      }

      if (firebaseUser) {
        // Real-time listener for the user profile document in Firestore
        unsubProfile = onSnapshot(
          doc(db, "users", firebaseUser.uid),
          (snap) => {
            if (snap.exists()) {
              const data = snap.data();
              setProfile({ uid: snap.id, ...data } as SocialUser);
              
              // Auto-migrate: set displayNameLowercase if it is missing
              if (data && data.displayName && !data.displayNameLowercase) {
                updateDoc(snap.ref, {
                  displayNameLowercase: data.displayName.toLowerCase()
                }).catch((err) => console.error("Profile auto-migration error:", err));
              }
            } else {
              setProfile(null);
            }
            setLoading(false);
            clearTimeout(fallbackTimer);
          },
          (error) => {
            console.error("Profile listen error:", error);
            setProfile(null);
            setLoading(false);
            clearTimeout(fallbackTimer);
          }
        );
      } else {
        setProfile(null);
        setLoading(false);
        clearTimeout(fallbackTimer);
      }
    });

    return () => {
      clearTimeout(fallbackTimer);
      unsubAuth();
      if (unsubProfile) unsubProfile();
    };
  }, []);

  return (
    <AuthContext.Provider value={{ user, profile, loading }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
