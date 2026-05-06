"use client"

import { useEffect, useState } from "react"
import { onAuthStateChanged, User } from "firebase/auth"
import { doc, getDoc } from "firebase/firestore"
import { auth, db } from "@/lib/firebase"
import { SocialUser } from "@/types"

export function useAuth() {
  const [user, setUser]           = useState<User | null>(null)
  const [profile, setProfile]     = useState<SocialUser | null>(null)
  const [loading, setLoading]     = useState(true)

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (firebaseUser) => {
      setUser(firebaseUser)
      if (firebaseUser) {
        const snap = await getDoc(doc(db, "users", firebaseUser.uid))
        if (snap.exists()) setProfile(snap.data() as SocialUser)
      } else {
        setProfile(null)
      }
      setLoading(false)
    })
    return unsub
  }, [])

  return { user, profile, loading }
}
