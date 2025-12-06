import React from 'react'
import { useNavigate } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { FunctionMetrics } from './FunctionMetrics'

interface EditorHeaderProps {
  functionUrl: string | null
  metrics: {
    executionTime: number
    cpuUsage: number
    memoryUsage: number
    successCount: number
    failureCount: number
  }
  fullscreen: boolean
}

export const EditorHeader: React.FC<EditorHeaderProps> = ({ functionUrl, metrics, fullscreen }) => {
  const navigate = useNavigate()

  return (
    <div className="flex items-center justify-between px-6 py-4 border-b border-white/10 bg-white/[0.02]">
      <div className="flex items-center gap-4">
        {!fullscreen && (
          <button
            onClick={() => navigate('/gallery')}
            className="flex items-center gap-2 text-white/60 hover:text-white transition-colors group"
          >
            <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
            <span className="text-sm font-normal">Gallery</span>
          </button>
        )}
        <div className="h-6 w-px bg-white/10"></div>
        <h1 className="font-pixel text-xl text-[#fece6d]">Function Editor</h1>
        
        {functionUrl && (
          <>
            <div className="h-6 w-px bg-white/10"></div>
            <FunctionMetrics metrics={metrics} />
          </>
        )}
      </div>
    </div>
  )
}
