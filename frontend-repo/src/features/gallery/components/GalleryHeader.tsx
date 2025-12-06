import React from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, Filter, Plus, RefreshCw } from 'lucide-react'
import { GALLERY_CONTENT } from '../constants/gallery.constants'

interface GalleryHeaderProps {
  searchQuery: string
  onSearchChange: (query: string) => void
  onRefresh?: () => void
}

export const GalleryHeader: React.FC<GalleryHeaderProps> = ({ searchQuery, onSearchChange, onRefresh }) => {
  const navigate = useNavigate()
  const [isRefreshing, setIsRefreshing] = React.useState(false)

  const handleRefresh = async () => {
    if (onRefresh && !isRefreshing) {
      setIsRefreshing(true)
      onRefresh()
      // Reset animation after a short delay
      setTimeout(() => setIsRefreshing(false), 1000)
    }
  }

  return (
    <div className="flex flex-col gap-8">
      {/* Title and Description */}
      <div className="flex flex-col gap-6 text-center animate-fade-in-up">
        <h1 className="font-pixel text-[#fece6d] text-3xl sm:text-4xl leading-tight">
          {GALLERY_CONTENT.title}
        </h1>
        <p className="text-white/70 text-base font-normal leading-normal max-w-2xl mx-auto">
          {GALLERY_CONTENT.description}
        </p>
      </div>

      {/* Search and Actions */}
      <div className="flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between animate-fade-in-up" style={{ animationDelay: '200ms' }}>
        {/* Search Bar */}
        <div className="relative w-full sm:max-w-xs">
          <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
            <Search className="w-5 h-5 text-white/50" />
          </div>
          <input
            className="w-full rounded-lg border border-white/10 bg-white/5 py-2.5 pl-10 pr-4 text-sm text-white placeholder-white/50 focus:border-primary/50 focus:shadow-lg focus:shadow-primary/20 focus:outline-none transition-all duration-300"
            placeholder={GALLERY_CONTENT.searchPlaceholder}
            type="search"
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
          />
        </div>

        {/* Filter and New Function Buttons */}
        <div className="flex items-center gap-3">
          <button 
            onClick={handleRefresh}
            disabled={isRefreshing}
            className="flex items-center gap-2 rounded-lg border border-white/10 bg-white/5 px-4 py-2.5 text-sm font-normal text-white/80 hover:bg-white/10 hover:border-primary/50 transition-all duration-300 disabled:opacity-50"
            title="Refresh functions"
          >
            <RefreshCw className={`w-4 h-4 ${isRefreshing ? 'animate-spin' : ''}`} />
            <span className="hidden sm:inline">Refresh</span>
          </button>
          <button className="flex items-center gap-2 rounded-lg border border-white/10 bg-white/5 px-4 py-2.5 text-sm font-normal text-white/80 hover:bg-white/10 hover:border-primary/50 transition-all duration-300">
            <Filter className="w-4 h-4" />
            <span className="hidden sm:inline">{GALLERY_CONTENT.filterLabel}</span>
          </button>
          <button 
            onClick={() => navigate('/create')}
            className="flex min-w-[84px] cursor-pointer items-center justify-center gap-2 overflow-hidden rounded-lg bg-primary px-4 py-2.5 text-sm font-medium text-background-dark transition-all duration-300 hover:brightness-110 hover:scale-105 hover:shadow-lg hover:shadow-primary/50"
          >
            <Plus className="w-4 h-4" />
            <span className="truncate">{GALLERY_CONTENT.newFunctionLabel}</span>
          </button>
        </div>
      </div>
    </div>
  )
}
