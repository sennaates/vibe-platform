"use client"

import React, { useEffect, useState } from "react"

interface ErrorBoundaryProps {
  children: React.ReactNode
}

interface ErrorBoundaryState {
  hasError: boolean
  error: Error | null
}

export class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    const errorData = {
      message: error.message || "Render hatası",
      stack: error.stack || errorInfo.componentStack || "",
      url: typeof window !== "undefined" ? window.location.href : ""
    }
    fetch("/api/debug-log", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(errorData)
    }).catch(() => {})
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="fixed inset-0 z-[9999] bg-[#0E0E0C] text-red-500 font-mono p-6 overflow-auto flex flex-col justify-center items-center">
          <div className="max-w-2xl w-full bg-red-950/20 border border-red-900 rounded-2xl p-6 space-y-4">
            <h1 className="text-xl font-bold text-red-400">🚨 Render Hatası (ErrorBoundary)</h1>
            <p className="text-sm font-semibold text-white">{this.state.error?.message}</p>
            {this.state.error?.stack && (
              <pre className="text-xs bg-black/40 p-4 rounded-xl border border-red-900/30 overflow-x-auto text-red-300 max-h-60">
                {this.state.error.stack}
              </pre>
            )}
            <button
              onClick={() => window.location.reload()}
              className="px-4 py-2 bg-red-800 text-white rounded-lg text-sm font-bold hover:bg-red-700 transition"
            >
              Yeniden Dene
            </button>
          </div>
        </div>
      )
    }

    return this.props.children
  }
}

export function ClientErrorCatcher({ children }: { children: React.ReactNode }) {
  const [error, setError] = useState<{ message: string; stack?: string } | null>(null)

  useEffect(() => {
    const handleError = (event: ErrorEvent) => {
      const errorData = {
        message: event.message || "Bilinmeyen hata",
        stack: event.error?.stack || "",
        url: window.location.href
      }
      setError(errorData)
      fetch("/api/debug-log", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(errorData)
      }).catch(() => {})
    }

    const handleRejection = (event: PromiseRejectionEvent) => {
      const errorData = {
        message: `Promise Hatası: ${event.reason?.message || event.reason || "Bilinmeyen rejection"}`,
        stack: event.reason?.stack || "",
        url: window.location.href
      }
      setError(errorData)
      fetch("/api/debug-log", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(errorData)
      }).catch(() => {})
    }

    window.addEventListener("error", handleError)
    window.addEventListener("unhandledrejection", handleRejection)

    return () => {
      window.removeEventListener("error", handleError)
      window.removeEventListener("unhandledrejection", handleRejection)
    }
  }, [])

  if (error) {
    return (
      <div className="fixed inset-0 z-[9999] bg-[#0E0E0C] text-red-500 font-mono p-6 overflow-auto flex flex-col justify-center items-center">
        <div className="max-w-2xl w-full bg-red-950/20 border border-red-900 rounded-2xl p-6 space-y-4">
          <h1 className="text-xl font-bold text-red-400">🚨 Uygulama Hatası (Client Crash)</h1>
          <p className="text-sm font-semibold text-white">{error.message}</p>
          {error.stack && (
            <pre className="text-xs bg-black/40 p-4 rounded-xl border border-red-900/30 overflow-x-auto text-red-300 max-h-60">
              {error.stack}
            </pre>
          )}
          <button
            onClick={() => window.location.reload()}
            className="px-4 py-2 bg-red-800 text-white rounded-lg text-sm font-bold hover:bg-red-700 transition"
          >
            Sayfayı Yenile
          </button>
        </div>
      </div>
    )
  }

  return <ErrorBoundary>{children}</ErrorBoundary>
}
