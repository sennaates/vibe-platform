import type { Metadata } from "next"
import { Geist } from "next/font/google"
import "./globals.css"
import { Navbar } from "@/components/layout/Navbar"
import { ToastContainer } from "@/components/ui/Toast"
import { ThemeProvider } from "@/components/ui/ThemeProvider"
import { ServiceWorkerRegister } from "@/components/ui/ServiceWorkerRegister"

const geist = Geist({ subsets: ["latin"], variable: "--font-geist" })

export const metadata: Metadata = {
  title: "Vibe — Duyguyla Çiz",
  description: "Kalp atışınla şekillenen bir çizim deneyimi.",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Vibe",
  },
  openGraph: {
    title: "Vibe",
    description: "Duyguyla çiz, paylaş.",
    type: "website",
  },
  other: {
    "mobile-web-app-capable": "yes",
    "theme-color": "#D9723F",
  },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="tr" className={`${geist.variable} h-full antialiased`} suppressHydrationWarning>
      <body className="min-h-full flex flex-col bg-canvas font-[family-name:var(--font-geist)]">
        <ThemeProvider>
          <ServiceWorkerRegister />
          <Navbar />
          <div className="flex-1">{children}</div>
          <ToastContainer />
        </ThemeProvider>
      </body>
    </html>
  )
}
