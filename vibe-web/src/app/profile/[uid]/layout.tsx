import type { Metadata } from "next"
import { getDocument } from "@/lib/firestore-rest"

export async function generateMetadata(
  { params }: { params: Promise<{ uid: string }> }
): Promise<Metadata> {
  const { uid } = await params
  const user = await getDocument("users", uid)

  if (!user) {
    return { title: "Profil — Vibe" }
  }

  const displayName    = (user.displayName    as string) ?? "Kullanıcı"
  const bio            = (user.bio            as string) ?? ""
  const postsCount     = (user.postsCount     as number) ?? 0
  const followersCount = (user.followersCount as number) ?? 0

  const title       = `${displayName} — Vibe`
  const description = bio
    ? bio
    : `${postsCount} çizim · ${followersCount} takipçi`

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: "profile",
      siteName: "Vibe",
    },
    twitter: {
      card: "summary",
      title,
      description,
    },
  }
}

export default function ProfileLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>
}
