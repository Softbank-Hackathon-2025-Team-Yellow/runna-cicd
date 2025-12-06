import React, { useState } from 'react'
import { Play, Clock } from 'lucide-react'
import Editor from '@monaco-editor/react'
import { DEFAULT_TEST_REQUEST } from '../constants/editor.constants'

interface FunctionTesterProps {
  functionUrl: string | null
  onTestComplete?: (executionTime: number, success: boolean) => void
}

export const FunctionTester: React.FC<FunctionTesterProps> = ({ functionUrl, onTestComplete }) => {
  const [requestBody, setRequestBody] = useState(DEFAULT_TEST_REQUEST)
  const [response, setResponse] = useState('')
  const [loading, setLoading] = useState(false)
  const [responseTime, setResponseTime] = useState<number | null>(null)
  const [requestFocused, setRequestFocused] = useState(false)
  const [responseFocused, setResponseFocused] = useState(false)

  const handleTest = async () => {
    if (!functionUrl) return

    setLoading(true)
    const startTime = performance.now()
    
    try {
      // TODO: Implement actual API call
      await new Promise(resolve => setTimeout(resolve, Math.random() * 1000 + 500))
      
      const endTime = performance.now()
      const executionTime = Math.round(endTime - startTime)
      setResponseTime(executionTime)
      
      const mockResponse = {
        statusCode: 200,
        body: {
          message: 'Function executed successfully',
          input: JSON.parse(requestBody),
          timestamp: new Date().toISOString()
        }
      }
      
      setResponse(JSON.stringify(mockResponse, null, 2))
      onTestComplete?.(executionTime, true)
    } catch (error) {
      const endTime = performance.now()
      const executionTime = Math.round(endTime - startTime)
      setResponseTime(executionTime)
      
      setResponse(JSON.stringify({ error: 'Failed to execute function' }, null, 2))
      onTestComplete?.(executionTime, false)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-white/10">
        <h3 className="text-lg font-normal text-white">Test Function</h3>
        {responseTime !== null && (
          <div className="flex items-center gap-1.5 px-2 py-1 bg-primary/10 border border-primary/30 rounded text-xs text-primary">
            <Clock className="w-3 h-3" />
            <span>{responseTime}ms</span>
          </div>
        )}
      </div>

      {/* Function URL */}
      {functionUrl && (
        <div className="mx-4 mt-4 p-3 bg-green-400/10 border border-green-400/30 rounded-lg">
          <p className="text-xs font-normal text-white/60 mb-1">Endpoint</p>
          <p className="text-sm font-normal text-green-400 break-all">{functionUrl}</p>
        </div>
      )}

      {/* Request and Response Sections */}
      <div className="flex-1 flex flex-col gap-4 p-4 overflow-hidden">
        {/* Request Section */}
        <div className="flex-1 flex flex-col min-h-0">
          <div className="flex items-center justify-between mb-2">
            <label className="text-sm font-medium text-white/80">Request Body</label>
            <span className="text-xs text-white/50">JSON</span>
          </div>
          <div
            className={`flex-1 rounded-lg overflow-hidden bg-[#1e1e1e] transition-all duration-300 ${
              requestFocused
                ? 'border border-primary/50 shadow-lg shadow-primary/20'
                : 'border border-white/10'
            }`}
          >
            <Editor
              height="100%"
              language="json"
              value={requestBody}
              onChange={(value) => setRequestBody(value || '')}
              onMount={(editor) => {
                editor.onDidFocusEditorText(() => setRequestFocused(true))
                editor.onDidBlurEditorText(() => setRequestFocused(false))
              }}
              theme="vs-dark"
              options={{
                minimap: { enabled: false },
                fontSize: 13,
                lineNumbers: 'on',
                scrollBeyondLastLine: false,
                automaticLayout: true,
                padding: { top: 8, bottom: 8 },
              }}
            />
          </div>
        </div>

        {/* Test Button */}
        <div>
          <button
            onClick={handleTest}
            disabled={!functionUrl || loading}
            className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-lg bg-primary text-background-dark text-sm font-medium transition-all duration-300 hover:brightness-110 hover:shadow-lg hover:shadow-primary/20 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Play className="w-4 h-4" />
            {loading ? 'Testing...' : 'Run Test'}
          </button>
        </div>

        {/* Response Section */}
        <div className="flex-1 flex flex-col min-h-0">
          <div className="flex items-center justify-between mb-2">
            <label className="text-sm font-medium text-white/80">Response</label>
            <span className="text-xs text-white/50">JSON</span>
          </div>
          <div
            className={`flex-1 rounded-lg overflow-hidden bg-[#1e1e1e] transition-all duration-300 ${
              responseFocused
                ? 'border border-primary/50 shadow-lg shadow-primary/20'
                : 'border border-white/10'
            }`}
          >
            <Editor
              height="100%"
              language="json"
              value={response || '// Response will appear here after running the test'}
              onMount={(editor) => {
                editor.onDidFocusEditorText(() => setResponseFocused(true))
                editor.onDidBlurEditorText(() => setResponseFocused(false))
              }}
              theme="vs-dark"
              options={{
                readOnly: true,
                minimap: { enabled: false },
                fontSize: 13,
                lineNumbers: 'on',
                scrollBeyondLastLine: false,
                automaticLayout: true,
                padding: { top: 8, bottom: 8 },
              }}
            />
          </div>
        </div>
      </div>
    </div>
  )
}
