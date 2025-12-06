import { useState } from 'react'
import { LandingNavigation } from '../features/landing/components/LandingNavigation'
import { GalleryHeader } from '../features/gallery/components/GalleryHeader'
import { FunctionGrid } from '../features/gallery/components/FunctionGrid'

const FunctionGalleryPage = () => {
  const [searchQuery, setSearchQuery] = useState('')
  const [refreshFn, setRefreshFn] = useState<(() => void) | null>(null)

  const handleRefresh = () => {
    if (refreshFn) {
      refreshFn()
    }
  }

  return (
    <div className="relative flex min-h-screen w-full flex-col bg-background-dark">
      {/* Navigation */}
      <LandingNavigation />

      {/* Main Content with Background Effects */}
      <main className="flex-1 relative overflow-hidden">
        {/* Animated background gradient */}
        <div className="absolute inset-0 bg-gradient-to-b from-primary/5 via-transparent to-transparent opacity-50"></div>
        
        {/* Animated grid pattern */}
        <div className="absolute inset-0 opacity-[0.02]" style={{
          backgroundImage: 'linear-gradient(rgba(245, 166, 35, 0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(245, 166, 35, 0.3) 1px, transparent 1px)',
          backgroundSize: '50px 50px'
        }}></div>

        <div className="relative z-10 px-4 sm:px-8 md:px-20 lg:px-40 py-12 sm:py-16 md:py-20">
          <div className="flex flex-col gap-12 max-w-[1200px] mx-auto">
            <GalleryHeader 
              searchQuery={searchQuery} 
              onSearchChange={setSearchQuery}
              onRefresh={handleRefresh}
            />
            <FunctionGrid 
              searchQuery={searchQuery}
              onRefreshReady={(fn) => setRefreshFn(() => fn)}
            />
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="flex flex-col gap-8 px-5 py-10 text-center mt-10 border-t border-solid border-white/10 relative z-10">
        <div className="flex flex-wrap items-center justify-center gap-6">
          <a
            className="text-white/80 text-base font-normal leading-normal min-w-40 hover:text-primary transition-colors duration-300"
            href="/"
          >
            Home
          </a>
          <a
            className="text-white/80 text-base font-normal leading-normal min-w-40 hover:text-primary transition-colors duration-300"
            href="/#features"
          >
            Features
          </a>
          <a
            className="text-white/80 text-base font-normal leading-normal min-w-40 hover:text-primary transition-colors duration-300"
            href="https://www.notion.so/ajy720/SoftBank-Hackathon-2025-Team-Yellow-2b9a0048876b80359945da260b4bc659"
            target="_blank"
            rel="noopener noreferrer"
          >
            Docs
          </a>
          <a
            className="text-white/80 text-base font-normal leading-normal min-w-40 hover:text-primary transition-colors duration-300"
            href="https://github.com/Softbank-Hackathon-2025-Team-Yellow"
            target="_blank"
            rel="noopener noreferrer"
          >
            GitHub
          </a>
        </div>
        <p className="text-white/80 text-sm font-normal leading-normal">
          © 2025 Runna — SoftBank Hackathon 2025, Yellow Team
        </p>
      </footer>
    </div>
  )
}

export default FunctionGalleryPage
