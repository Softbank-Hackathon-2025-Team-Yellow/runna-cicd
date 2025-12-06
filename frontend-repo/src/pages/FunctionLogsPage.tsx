import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, CheckCircle, XCircle, Download, RefreshCw } from 'lucide-react'
import { LandingNavigation } from '../features/landing/components/LandingNavigation'
import { LogJob, generateMockLogs, MOCK_FUNCTION_NAME } from '../features/function-logs/data/mockLogs'

const USE_MOCK_DATA = import.meta.env.VITE_USE_MOCK_DATA === 'true'

const FunctionLogsPage = () => {
  const navigate = useNavigate()
  const { functionId } = useParams<{ functionId: string }>()
  const [functionName, setFunctionName] = useState('')
  const [jobs, setJobs] = useState<LogJob[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState<'all' | 'succeeded' | 'failed'>('all')

  useEffect(() => {
    const fetchLogs = async () => {
      setLoading(true)
      try {
        if (USE_MOCK_DATA) {
          // Use mock data
          await new Promise(resolve => setTimeout(resolve, 500)) // Simulate API delay
          setFunctionName(MOCK_FUNCTION_NAME)
          setJobs(generateMockLogs(50))
        } else {
          // TODO: Fetch from real API
          // const response = await fetch(`/api/functions/${functionId}/logs`)
          // const data = await response.json()
          // setFunctionName(data.functionName)
          // setJobs(data.logs)
          
          // For now, return empty data when not using mock
          setFunctionName('')
          setJobs([])
        }
      } catch (error) {
        console.error('Failed to fetch logs:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchLogs()
  }, [functionId])

  const getStatusColor = (status: LogJob['status']) => {
    switch (status) {
      case 'succeeded':
        return 'text-green-400 bg-green-400/10 border-green-400/30'
      case 'failed':
        return 'text-red-400 bg-red-400/10 border-red-400/30'
      case 'running':
        return 'text-blue-400 bg-blue-400/10 border-blue-400/30'
      case 'pending':
        return 'text-yellow-400 bg-yellow-400/10 border-yellow-400/30'
      default:
        return 'text-white/60 bg-white/5 border-white/10'
    }
  }

  const formatTimestamp = (timestamp: string) => {
    return new Date(timestamp).toLocaleString()
  }

  const filteredJobs = jobs.filter(job => {
    if (filter === 'all') return true
    return job.status === filter
  })

  const handleRefresh = () => {
    setLoading(true)
    setTimeout(() => setLoading(false), 1000)
  }

  const handleExport = () => {
    const dataStr = JSON.stringify(filteredJobs, null, 2)
    const dataBlob = new Blob([dataStr], { type: 'application/json' })
    const url = URL.createObjectURL(dataBlob)
    const link = document.createElement('a')
    link.href = url
    link.download = `${functionName}-logs.json`
    link.click()
  }

  if (loading) {
    return (
      <div className="min-h-screen w-full flex flex-col bg-background-dark">
        <LandingNavigation />
        <div className="flex-1 flex items-center justify-center">
          <div className="text-white/60">Loading logs...</div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen w-full flex flex-col bg-background-dark">
      <LandingNavigation />

      <main className="flex-1 relative overflow-hidden">
        {/* Animated background gradient */}
        <div className="absolute inset-0 bg-gradient-to-b from-primary/5 via-transparent to-transparent opacity-50"></div>
        
        {/* Animated grid pattern */}
        <div className="absolute inset-0 opacity-[0.02]" style={{
          backgroundImage: 'linear-gradient(rgba(245, 166, 35, 0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(245, 166, 35, 0.3) 1px, transparent 1px)',
          backgroundSize: '50px 50px'
        }}></div>

        <div className="relative z-10 px-4 sm:px-8 md:px-20 lg:px-40 py-8 max-w-[1800px] mx-auto">
          {/* Header */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
            <div className="flex flex-col gap-3">
              <button
                onClick={() => navigate(`/function/${functionId}`)}
                className="flex items-center gap-2 text-white/60 hover:text-primary transition-colors w-fit"
              >
                <ArrowLeft className="w-4 h-4" />
                <span className="text-sm font-normal">Back to Function</span>
              </button>
              <div className="flex items-center gap-3 flex-wrap">
                <h1 className="font-pixel text-3xl text-[#fece6d]">Execution Logs</h1>
                <span className="text-white/60 text-lg">/ {functionName}</span>
              </div>
            </div>
            
            <div className="flex items-center gap-3">
              <button
                onClick={handleRefresh}
                className="flex items-center gap-2 py-2.5 px-4 rounded-lg border border-white/10 bg-white/5 text-white text-sm font-normal hover:bg-white/10 hover:border-white/20 transition-all duration-300"
              >
                <RefreshCw className="w-4 h-4" />
                Refresh
              </button>
              <button
                onClick={handleExport}
                className="flex items-center gap-2 py-2.5 px-4 rounded-lg border border-white/10 bg-white/5 text-white text-sm font-normal hover:bg-white/10 hover:border-white/20 transition-all duration-300"
              >
                <Download className="w-4 h-4" />
                Export
              </button>
            </div>
          </div>

          {/* Filter Tabs */}
          <div className="mb-6">
            <div className="flex items-center gap-2 p-1 bg-white/5 border border-white/10 rounded-lg w-fit">
              <button
                onClick={() => setFilter('all')}
                className={`px-4 py-2 rounded text-sm font-medium transition-all duration-300 ${
                  filter === 'all'
                    ? 'bg-primary text-background-dark'
                    : 'text-white/60 hover:text-white hover:bg-white/5'
                }`}
              >
                All ({jobs.length})
              </button>
              <button
                onClick={() => setFilter('succeeded')}
                className={`px-4 py-2 rounded text-sm font-medium transition-all duration-300 ${
                  filter === 'succeeded'
                    ? 'bg-green-400/20 text-green-400'
                    : 'text-white/60 hover:text-white hover:bg-white/5'
                }`}
              >
                Succeeded ({jobs.filter(j => j.status === 'succeeded').length})
              </button>
              <button
                onClick={() => setFilter('failed')}
                className={`px-4 py-2 rounded text-sm font-medium transition-all duration-300 ${
                  filter === 'failed'
                    ? 'bg-red-400/20 text-red-400'
                    : 'text-white/60 hover:text-white hover:bg-white/5'
                }`}
              >
                Failed ({jobs.filter(j => j.status === 'failed').length})
              </button>
            </div>
          </div>

          {/* Logs Table */}
          <div className="rounded-xl border border-white/10 bg-white/[0.02] overflow-hidden shadow-xl">
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-white/[0.02] border-b border-white/10">
                  <tr>
                    <th className="px-6 py-4 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Job ID</th>
                    <th className="px-6 py-4 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-4 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Timestamp</th>
                    <th className="px-6 py-4 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Execution Time</th>
                    <th className="px-6 py-4 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Result</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-white/5">
                  {filteredJobs.length > 0 ? (
                    filteredJobs.map((job) => (
                      <tr key={job.job_id} className="hover:bg-white/[0.03] transition-colors group">
                        <td className="px-6 py-4 text-sm font-mono text-primary group-hover:text-primary/80">{job.job_id}</td>
                        <td className="px-6 py-4">
                          <span className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium border ${getStatusColor(job.status)}`}>
                            {job.status === 'succeeded' && <CheckCircle className="w-3.5 h-3.5" />}
                            {job.status === 'failed' && <XCircle className="w-3.5 h-3.5" />}
                            {job.status}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-sm text-white/60">{formatTimestamp(job.timestamp)}</td>
                        <td className="px-6 py-4 text-sm text-white/60">{job.execution_time}</td>
                        <td className="px-6 py-4 text-sm text-white/60">
                          {job.result ? (
                            <code className="text-xs bg-white/10 px-3 py-1.5 rounded font-mono">{JSON.stringify(job.result).substring(0, 50)}...</code>
                          ) : job.error ? (
                            <span className="text-red-400 text-xs">{job.error}</span>
                          ) : (
                            <span className="text-white/40 italic">No result</span>
                          )}
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={5} className="px-6 py-12 text-center text-white/40">
                        No logs found for the selected filter
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {/* Pagination Info */}
          <div className="mt-6 flex items-center justify-between">
            <p className="text-sm text-white/50">
              Showing {filteredJobs.length} of {jobs.length} total executions
            </p>
          </div>
        </div>
      </main>
    </div>
  )
}

export default FunctionLogsPage
