import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { Panel, PanelGroup, PanelResizeHandle } from 'react-resizable-panels'
import { ArrowLeft, Save, Rocket, Maximize2, Minimize2, FileCode, Share2, Clock, ChevronDown } from 'lucide-react'
import { LandingNavigation } from '../features/landing/components/LandingNavigation'
import { CodeEditor } from '../features/function-editor/components/CodeEditor'
import { FunctionTester } from '../features/function-editor/components/FunctionTester'
import { FunctionMetrics } from '../features/function-editor/components/FunctionMetrics'
import { TemplateSelector } from '../features/function-editor/components/TemplateSelector'
import { useAutoSave } from '../features/function-editor/hooks/useAutoSave'
import { Runtime, ExecutionMode } from '../features/function-editor/types/editor.types'
import { DEFAULT_NODEJS_CODE, DEFAULT_PYTHON_CODE } from '../features/function-editor/constants/editor.constants'

const CreateFunctionPage = () => {
  const navigate = useNavigate()
  const [name, setName] = useState('')
  const [runtime, setRuntime] = useState<Runtime>('Node.js')
  const [, setExecutionMode] = useState<ExecutionMode>('sync')
  const [code, setCode] = useState(DEFAULT_NODEJS_CODE)
  const [functionUrl, setFunctionUrl] = useState<string | null>(null)
  const [deploying, setDeploying] = useState(false)
  const [showTemplates, setShowTemplates] = useState(false)
  const [fullscreen, setFullscreen] = useState(false)
  
  // Change tracking
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false)
  const [lastSavedState, setLastSavedState] = useState({ name: '', code: DEFAULT_NODEJS_CODE, runtime: 'Node.js' as Runtime })
  const [recentlySaved, setRecentlySaved] = useState(false)
  
  // Metrics state
  const [metrics, setMetrics] = useState({
    executionTime: 0,
    cpuUsage: 0,
    memoryUsage: 0,
    successCount: 0,
    failureCount: 0
  })

  // Track changes
  useEffect(() => {
    const hasChanges = 
      name !== lastSavedState.name ||
      code !== lastSavedState.code ||
      runtime !== lastSavedState.runtime
    setHasUnsavedChanges(hasChanges)
  }, [name, code, runtime, lastSavedState])

  // Auto-save
  const handleAutoSave = useCallback(async () => {
    if (!name.trim()) return
    // TODO: Implement actual save API
    await new Promise(resolve => setTimeout(resolve, 500))
    
    // Update last saved state
    setLastSavedState({ name, code, runtime })
    setHasUnsavedChanges(false)
    setRecentlySaved(true)
    
    // Reset recently saved highlight after 3 seconds
    setTimeout(() => setRecentlySaved(false), 3000)
  }, [name, code, runtime])

  const { saving: autoSaving } = useAutoSave(
    { name, code, runtime },
    handleAutoSave,
    2000
  )

  // Update code when runtime changes
  useEffect(() => {
    setCode(runtime === 'Node.js' ? DEFAULT_NODEJS_CODE : DEFAULT_PYTHON_CODE)
  }, [runtime])

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 's') {
        e.preventDefault()
        handleManualSave()
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [])

  const handleManualSave = async () => {
    if (!name.trim()) {
      alert('Please enter a function name')
      return
    }

    try {
      await handleAutoSave()
      alert('Function saved successfully!')
    } catch (error) {
      alert('Failed to save function')
    }
  }

  const handleDeploy = async (mode: ExecutionMode) => {
    if (!name.trim()) {
      alert('Please enter a function name')
      return
    }

    setExecutionMode(mode)
    setDeploying(true)
    setRecentlySaved(false) // Reset recently saved highlight when deploying
    
    try {
      // TODO: Implement actual deploy API
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      const mockUrl = `https://api.runna.dev/functions/${name.toLowerCase().replace(/\s+/g, '-')}`
      setFunctionUrl(mockUrl)
      
      // Update metrics
      setMetrics(prev => ({
        ...prev,
        executionTime: Math.round(Math.random() * 500 + 100),
        cpuUsage: Math.round(Math.random() * 50 + 10),
        memoryUsage: Math.round(Math.random() * 100 + 50)
      }))
      
      alert(`Function deployed successfully in ${mode} mode!`)
    } catch (error) {
      alert('Failed to deploy function')
    } finally {
      setDeploying(false)
    }
  }

  const handleTestComplete = (executionTime: number, success: boolean) => {
    setMetrics(prev => ({
      ...prev,
      executionTime,
      successCount: success ? prev.successCount + 1 : prev.successCount,
      failureCount: !success ? prev.failureCount + 1 : prev.failureCount
    }))
  }

  const handleShare = () => {
    if (functionUrl) {
      navigator.clipboard.writeText(functionUrl)
      alert('Function URL copied to clipboard!')
    } else {
      alert('Please deploy the function first')
    }
  }

  return (
    <div className={`relative flex ${fullscreen ? 'fixed inset-0 z-50' : 'min-h-screen'} w-full flex-col bg-background-dark`}>
      {/* Navigation */}
      {!fullscreen && <LandingNavigation />}

      {/* Main Content */}
      <main className="flex-1 relative overflow-hidden">
        {/* Animated background gradient */}
        <div className="absolute inset-0 bg-gradient-to-b from-primary/5 via-transparent to-transparent opacity-50"></div>
        
        {/* Animated grid pattern */}
        <div className="absolute inset-0 opacity-[0.02]" style={{
          backgroundImage: 'linear-gradient(rgba(245, 166, 35, 0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(245, 166, 35, 0.3) 1px, transparent 1px)',
          backgroundSize: '50px 50px'
        }}></div>

        <div className="relative z-10 px-4 sm:px-8 md:px-20 lg:px-40 py-8 h-full">
          {/* Header */}
          <div className="flex items-center justify-between mb-6">
            <div className="flex items-center gap-4">
              {!fullscreen && (
                <button
                  onClick={() => navigate('/gallery')}
                  className="flex items-center gap-2 text-white/60 hover:text-primary transition-colors"
                >
                  <ArrowLeft className="w-5 h-5" />
                  <span className="text-sm font-normal">Back</span>
                </button>
              )}
              <h1 className="font-pixel text-2xl text-[#fece6d]">Function Editor</h1>
              
              {/* Metrics */}
              {functionUrl && <FunctionMetrics metrics={metrics} />}
            </div>
            
            <div className="flex items-center gap-2">
              {/* Secondary Actions */}
              <button
                onClick={() => setShowTemplates(true)}
                className="p-2 rounded-lg border border-white/10 bg-white/5 text-white/70 hover:text-white hover:bg-white/10 transition-all duration-300 group"
                title="Templates"
              >
                <FileCode className="w-4 h-4" />
              </button>
              
              <button
                onClick={handleShare}
                className="p-2 rounded-lg border border-white/10 bg-white/5 text-white/70 hover:text-white hover:bg-white/10 transition-all duration-300"
                title="Share"
              >
                <Share2 className="w-4 h-4" />
              </button>
              
              <div className="h-6 w-px bg-white/10 mx-1"></div>
              
              {/* Primary Actions */}
              <button
                onClick={handleManualSave}
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
                        onClick={() => handleDeploy('sync')}
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
                        onClick={() => handleDeploy('async')}
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
                onClick={() => setFullscreen(!fullscreen)}
                className="p-2 rounded-lg border border-white/10 bg-white/5 text-white/70 hover:text-white hover:bg-white/10 transition-all duration-300"
                title={fullscreen ? 'Exit Fullscreen' : 'Fullscreen'}
              >
                {fullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {/* Main Layout - Split View */}
          <div className="h-[calc(100vh-180px)]">
            <PanelGroup direction="horizontal">
              {/* Left: Code Editor */}
              <Panel defaultSize={60} minSize={40}>
                <div className="h-full flex flex-col gap-2">
                  {/* Function Name Input and Controls */}
                  <div className="flex items-center gap-3">
                    <input
                      type="text"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      placeholder="Enter function name..."
                      className="flex-1 px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-white placeholder-white/50 text-sm focus:border-primary/50 focus:shadow-lg focus:shadow-primary/20 focus:outline-none transition-all duration-300"
                    />
                    
                    {/* Runtime Toggle */}
                    <div className="flex items-center gap-1 p-0.5 bg-white/5 border border-white/10 rounded-lg">
                      <button
                        onClick={() => setRuntime('Node.js')}
                        className={`flex items-center gap-1.5 py-1 px-2.5 rounded text-xs font-normal transition-all duration-300 ${
                          runtime === 'Node.js'
                            ? 'bg-green-400/20 border border-green-400/50'
                            : 'hover:bg-white/5'
                        }`}
                      >
                        <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M12 1.5C11.5 1.5 11 1.7 10.7 2L2.2 7.5C1.5 7.9 1 8.7 1 9.5V14.5C1 15.3 1.5 16.1 2.2 16.5L10.7 22C11 22.3 11.5 22.5 12 22.5C12.5 22.5 13 22.3 13.3 22L21.8 16.5C22.5 16.1 23 15.3 23 14.5V9.5C23 8.7 22.5 7.9 21.8 7.5L13.3 2C13 1.7 12.5 1.5 12 1.5Z" fill="#68A063"/>
                        </svg>
                        <span className={runtime === 'Node.js' ? 'text-green-400' : 'text-white/60'}>Node.js</span>
                      </button>
                      <button
                        onClick={() => setRuntime('Python')}
                        className={`flex items-center gap-1.5 py-1 px-2.5 rounded text-xs font-normal transition-all duration-300 ${
                          runtime === 'Python'
                            ? 'bg-blue-400/20 border border-blue-400/50'
                            : 'hover:bg-white/5'
                        }`}
                      >
                        <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                          <path d="M9.585 11.692h4.328s2.432.039 2.432-2.35V5.391S16.714 3 11.936 3C7.362 3 7.647 3 7.647 3l-.006 2.347h4.363v.617H5.92s-2.927-.332-2.927 4.282 0 4.09 0 4.09h1.735v-2.383s-.093-2.261 2.226-2.261z" fill="url(#python-gradient-1)"/>
                          <path d="M14.415 12.308h-4.328s-2.432-.04-2.432 2.35v3.951S7.286 21 12.064 21c4.574 0 4.289 0 4.289 0l.006-2.347h-4.363v-.617h6.084s2.927.332 2.927-4.282 0-4.09 0-4.09h-1.735v2.383s.093 2.261-2.226 2.261z" fill="url(#python-gradient-2)"/>
                          <circle cx="8.5" cy="5.5" r="0.9" fill="#fff"/>
                          <circle cx="15.5" cy="18.5" r="0.9" fill="#fff"/>
                          <defs>
                            <linearGradient id="python-gradient-1" x1="7" y1="3" x2="7" y2="14" gradientUnits="userSpaceOnUse">
                              <stop stopColor="#387EB8"/>
                              <stop offset="1" stopColor="#366994"/>
                            </linearGradient>
                            <linearGradient id="python-gradient-2" x1="17" y1="10" x2="17" y2="21" gradientUnits="userSpaceOnUse">
                              <stop stopColor="#FFE873"/>
                              <stop offset="1" stopColor="#FFC331"/>
                            </linearGradient>
                          </defs>
                        </svg>
                        <span className={runtime === 'Python' ? 'text-blue-400' : 'text-white/60'}>Python</span>
                      </button>
                    </div>
                  </div>
                  
                  {/* Code Editor */}
                  <div className="flex-1">
                    <CodeEditor value={code} onChange={setCode} runtime={runtime} />
                  </div>
                </div>
              </Panel>

              <PanelResizeHandle className="w-1 bg-white/5 hover:bg-primary/50 transition-colors" />

              {/* Right: Test Panel */}
              <Panel defaultSize={40} minSize={30} maxSize={60}>
                <div className="h-full">
                  <FunctionTester functionUrl={functionUrl} onTestComplete={handleTestComplete} />
                </div>
              </Panel>
            </PanelGroup>
          </div>
        </div>
      </main>

      {/* Template Selector Modal */}
      {showTemplates && (
        <TemplateSelector
          onSelect={(template) => {
            setRuntime(template.runtime)
            setCode(template.code)
            if (!name) {
              setName(template.name.toLowerCase().replace(/\s+/g, '-'))
            }
          }}
          onClose={() => setShowTemplates(false)}
        />
      )}
    </div>
  )
}

export default CreateFunctionPage
