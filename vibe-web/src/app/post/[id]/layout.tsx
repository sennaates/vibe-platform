import type { Metadata } from "next"
import { getDocument } from "@/lib/firestore-rest"

export async function generateMetadata(
  { params }: { params: Promise<{ id: string }> }
): Promise<Metadata> {
  const { id } = await params
  const post = await getDocument("posts", id)

  if (!post) {
    return { title: "Gönderi — Vibe" }
  }

  const emotion   = (post.emotion   as string) ?? "Çizim"
  const caption   = (post.caption   as string) ?? ""
  const imageUrl  = (post.imageUrl  as string) ?? ""
  const userName  = (post.userName  as string) ?? "Anonim"

  const title       = `${emotion} — Vibe`
  const description = caption
    ? `${caption} · ${userName} tarafından`
    : `${userName} tarafından paylaşılan ${emotion} çizimi`

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: "article",
      images: imageUrl ? [{ url: imageUrl, width: 800, height: 800, alt: emotion }] : [],
      siteName: "Vibe",
    },
    twitter: {
      card: imageUrl ? "summary_large_image" : "summary",
      title,
      description,
      images: imageUrl ? [imageUrl] : [],
    },
  }
}

export default function PostLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>
}
