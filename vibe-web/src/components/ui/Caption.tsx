import Link from "next/link"

interface CaptionProps {
  text: string
  className?: string
}

/**
 * Renders post caption with clickable #hashtag links.
 * Splits on hashtag boundaries and wraps each #word in a Link.
 */
export function Caption({ text, className }: CaptionProps) {
  // Split caption into parts: plain text and hashtags
  const parts = text.split(/(#[\wÀ-ɏЀ-ӿ]+)/g)

  return (
    <span className={className}>
      {parts.map((part, i) => {
        if (part.startsWith("#") && part.length > 1) {
          const tag = part.slice(1).toLowerCase()
          return (
            <Link
              key={i}
              href={`/hashtag/${tag}`}
              className="text-accent font-medium hover:underline"
            >
              {part}
            </Link>
          )
        }
        return <span key={i}>{part}</span>
      })}
    </span>
  )
}
