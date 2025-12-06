import React from 'react'
import { Save, Rocket, Maximize2, Minimize2, FileCode, Share2, Clock, ChevronDown } from 'lucide-react'

interface EditorToolbarProps {
  hasUnsavedChanges: boolean
  autoSaving: boolean
  recentlySaved: boolean
  deploying: boolean
  fullscreen: boolean
  onSave: () => void
  onDeploy: (mode: 'sync' | 'async') => void
  onShare: () => void
  onTemplates: () => void
  onFullscreenToggle: () => void
}

export const EditorToolbar: React.FC<EditorToolbarProps> = ({
  hasUnsavedChanges,
  autoSaving,
  recentlySaved,
  deploying,
  fullscreen,
  onSave,
  onDeploy,
  onShare,
  onTemplates,
  onFullscreenToggle
}) => {
  return (
    <div className="flex items-center gap-2">
      {/* Auto-save indicator */}
      {!autoSaving && (
        <div className="flex items-center gap-2 text-xs text-white/40 mr-2">
          <div className="w-1.5 h-1.5 rounded-full bg-green-400/60"></div>
          <span>Saved</span>
        </div>
      )}
      
      {/* Secondary Actions */}
      <button
        onClick={onTemplates}
        className="p-2 rounded-lg border border-white/10 bg-white/5 text-white/70 hover:text-white hover:bg-white/10 transition-all duration-300 group"
        title="Templates"
      >
        <FileCode className="w-4 h-4" />
      </button>
      
      <button
        onClick={onShare}
        className="p-2 rounded-lg border border-white/10 bg-white/5 text-white/70 hover:text-white hover:bg-white/10 transition-all duration-300"
        title="Share"
      >
        <Share2 className="w-4 h-4" />
      </button>
      
      <div className="h-6 w-px bg-white/10 mx-1"></div>
      
      {/* Primary Actions */}
      <button
        onClick={onSave}
        disabled={autoSaving}
        className={`flex items-center gap-2 py-2 px-3 rounded-lg border text-sm font-normal transition-colors duration-300 ${
          autoSaving
            ? 'border-primary/50 bg-primary/10 text-primary cursor-wait'
            : hasUnsavedChanges
            ? 'border-primary text-primary hover:bg-primary/30 hover:border-primary animate-gentle-glow'
            : 'border-white/10 bg-white/5 text-white hover:bg-white/10 hover:border-white/20'
        }`}
      >
        {autoSaving ? (
          <>
            <Clock className="w-4 h-4 animate-spin" />
            <span className="hidden sm:inline">Saving...</span>
          </>
        ) : (
          <>
            <Save className="w-4 h-4" />
            <span className="hidden sm:inline">Save</span>
          </>
        )}
      </button>
      
      {/* Deploy Button with Dropdown */}
      <div className="relative group">
        <button
          disabled={deploying}
          className={`flex items-center gap-2 py-2 px-4 rounded-lg text-sm font-medium transition-all duration-300 disabled:opacity-50 cursor-pointer ${
            recentlySaved
              ? 'bg-primary text-background-dark hover:brightness-110 shadow-lg shadow-primary/40 animate-gentle-glow'
              : 'bg-primary text-background-dark hover:brightness-110 hover:shadow-lg hover:shadow-primary/20'
          }`}
        >
          <Rocket className="w-4 h-4" />
          <span>{deploying ? 'Deploying...' : 'Deploy'}</span>
          <ChevronDown className="w-3 h-3" />
        </button>
        
        {/* Dropdown Menu */}
        {!deploying && (
          <div className="absolute right-0 top-full mt-2 w-52 bg-background-dark/95 backdrop-blur-sm border border-white/10 rounded-lg shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 overflow-hidden">
            <div className="py-1">
              <button
                onClick={() => onDeploy('sync')}
                className="w-full text-left px-4 py-3 text-sm transition-colors text-white/80 hover:bg-primary/10 hover:text-primary"
              >
                <div className="flex items-center gap-3">
                  <Rocket className="w-4 h-4" />
                  <div>
                    <div className="font-medium">Deploy Sync</div>
                    <div className="text-xs text-white/50 mt-0.5">Synchronous execution</div>
                  </div>
                </div>
              </button>
              <div className="border-t border-white/5"></div>
              <button
                onClick={() => onDeploy('async')}
                className="w-full text-left px-4 py-3 text-sm transition-colors text-white/80 hover:bg-primary/10 hover:text-primary"
              >
                <div className="flex items-center gap-3">
                  <Rocket className="w-4 h-4" />
                  <div>
                    <div className="font-medium">Deploy Async</div>
                    <div className="text-xs text-white/50 mt-0.5">Asynchronous execution</div>
                  </div>
                </div>
              </button>
            </div>
          </div>
        )}
      </div>
      
      <button
        onClick={onFullscreenToggle}
        className="p-2 rounded-lg border border-white/10 bg-white/5 text-white/70 hover:text-white hover:bg-white/10 transition-all duration-300"
        title={fullscreen ? 'Exit Fullscreen' : 'Fullscreen'}
      >
        {fullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
      </button>
    </div>
  )
}
