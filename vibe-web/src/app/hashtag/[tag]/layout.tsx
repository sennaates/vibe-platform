import type { Metadata } from "next"

interface Props {
  params: Promise<{ tag: string }>
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { tag } = await params
  return {
    title: `#${tag} — Vibe`,
    description: `Vibe'da #${tag} hashtag'iyle paylaşılan çizimler.`,
    openGraph: {
      title: `#${tag} — Vibe`,
      description: `Vibe'da #${tag} etiketiyle paylaşılan çizimler.`,
      type: "website",
    },
  }
}

export default function HashtagLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>
}
