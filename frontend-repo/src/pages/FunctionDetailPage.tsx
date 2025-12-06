import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Eye, Activity, Clock, Cpu, HardDrive, TrendingUp, CheckCircle, XCircle, RefreshCw, Copy, Link } from 'lucide-react'
import { LandingNavigation } from '../features/landing/components/LandingNavigation'
import { 
  FunctionDetail, 
  Metrics, 
  Job, 
  MOCK_FUNCTION_DETAIL, 
  MOCK_METRICS, 
  MOCK_JOBS 
} from '../features/function-detail/data/mockFunctionDetail'

const USE_MOCK_DATA = import.meta.env.VITE_USE_MOCK_DATA === 'true'

const FunctionDetailPage = () => {
  const navigate = useNavigate()
  const { functionId } = useParams<{ functionId: string }>()
  const [functionDetail, setFunctionDetail] = useState<FunctionDetail | null>(null)
  const [metrics, setMetrics] = useState<Metrics | null>(null)
  const [jobs, setJobs] = useState<Job[]>([])
  const [loading, setLoading] = useState(true)
  const [copiedUrl, setCopiedUrl] = useState(false)

  const fetchData = async () => {
    setLoading(true)
    try {
      if (USE_MOCK_DATA) {
        // Use mock data
        await new Promise(resolve => setTimeout(resolve, 500)) // Simulate API delay
        setFunctionDetail({ ...MOCK_FUNCTION_DETAIL, function_id: functionId || '1' })
        setMetrics(MOCK_METRICS)
        setJobs(MOCK_JOBS)
      } else {
        // TODO: Fetch from real API
        // const response = await fetch(`/api/functions/${functionId}`)
        // const data = await response.json()
        // setFunctionDetail(data.function)
        // setMetrics(data.metrics)
        // setJobs(data.jobs)
        
        // For now, return empty data when not using mock
        setFunctionDetail(null)
        setMetrics(null)
        setJobs([])
      }
    } catch (error) {
      console.error('Failed to fetch function details:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchData()
  }, [functionId])

  const handleRefresh = () => {
    fetchData()
  }

  const handleCopyUrl = () => {
    if (functionDetail?.url) {
      navigator.clipboard.writeText(functionDetail.url)
      setCopiedUrl(true)
      setTimeout(() => setCopiedUrl(false), 2000)
    }
  }

  const getStatusColor = (status: Job['status']) => {
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

  if (loading) {
    return (
      <div className="min-h-screen w-full flex flex-col bg-background-dark">
        <LandingNavigation />
        <div className="flex-1 flex items-center justify-center">
          <div className="text-white/60">Loading...</div>
        </div>
      </div>
    )
  }

  if (!functionDetail) {
    return (
      <div className="min-h-screen w-full flex flex-col bg-background-dark">
        <LandingNavigation />
        <div className="flex-1 flex items-center justify-center">
          <div className="text-white/60">Function not found</div>
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

        <div className="relative z-10 px-4 sm:px-8 md:px-20 lg:px-40 py-8 max-w-[1600px] mx-auto">
          {/* Header */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-8 gap-4">
            <div className="flex flex-col gap-3">
              <button
                onClick={() => navigate('/gallery')}
                className="flex items-center gap-2 text-white/60 hover:text-primary transition-colors w-fit"
              >
                <ArrowLeft className="w-4 h-4" />
                <span className="text-sm font-normal">Back to Gallery</span>
              </button>
              <div className="flex items-center gap-3 flex-wrap mb-3">
                <h1 className="font-pixel text-3xl text-[#fece6d]">{functionDetail.name}</h1>
                <span className={`px-3 py-1.5 rounded-lg text-xs font-medium border ${
                  functionDetail.runtime === 'nodejs' 
                    ? 'bg-green-400/10 text-green-400 border-green-400/30' 
                    : 'bg-blue-400/10 text-blue-400 border-blue-400/30'
                }`}>
                  {functionDetail.runtime}
                </span>
                <span className={`px-3 py-1.5 rounded-lg text-xs font-medium border ${
                  functionDetail.execution_type === 'sync' 
                    ? 'bg-purple-400/10 text-purple-400 border-purple-400/30' 
                    : 'bg-orange-400/10 text-orange-400 border-orange-400/30'
                }`}>
                  {functionDetail.execution_type}
                </span>
              </div>
              
              {/* Function URL */}
              {functionDetail.url && (
                <div className="flex items-center gap-2 p-3 rounded-lg border border-white/10 bg-white/5 max-w-fit">
                  <Link className="w-4 h-4 text-primary flex-shrink-0" />
                  <code className="text-xs text-white/80 font-mono">{functionDetail.url}</code>
                  <button
                    onClick={handleCopyUrl}
                    className="p-1.5 rounded hover:bg-white/10 transition-colors"
                    title="Copy URL"
                  >
                    <Copy className={`w-3.5 h-3.5 ${copiedUrl ? 'text-green-400' : 'text-white/60'}`} />
                  </button>
                </div>
              )}
            </div>
            
            <div className="flex items-center gap-3">
              <button
                onClick={handleRefresh}
                disabled={loading}
                className="flex items-center gap-2 py-2.5 px-4 rounded-lg border border-white/10 bg-white/5 text-white text-sm font-normal hover:bg-white/10 hover:border-white/20 transition-all duration-300 disabled:opacity-50"
              >
                <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
                <span className="hidden sm:inline">Refresh</span>
              </button>
              <button
                onClick={() => navigate(`/edit/${functionId}`)}
                className="flex items-center gap-2 py-2.5 px-5 rounded-lg bg-primary text-background-dark text-sm font-medium hover:brightness-110 hover:shadow-lg hover:shadow-primary/20 transition-all duration-300"
              >
                <Eye className="w-4 h-4" />
                View Function
              </button>
            </div>
          </div>

          {/* Metrics Overview */}
          {metrics && (
            <div className="mb-8">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
                {/* Total Invocations */}
                <div className="group p-5 rounded-xl border border-white/10 bg-white/5 hover:bg-white/10 hover:border-primary/30 transition-all duration-300 cursor-pointer">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="p-2 rounded-lg bg-primary/10 group-hover:bg-primary/20 transition-colors">
                      <Activity className="w-4 h-4 text-primary" />
                    </div>
                    <span className="text-xs font-medium text-white/60">Total Invocations</span>
                  </div>
                  <div className="text-3xl font-bold text-white">{metrics.invocations.total.toLocaleString()}</div>
                  <div className="mt-2 text-xs text-white/40">All time</div>
                </div>

                {/* Success Rate */}
                <div className="group p-5 rounded-xl border border-white/10 bg-white/5 hover:bg-white/10 hover:border-green-400/30 transition-all duration-300 cursor-pointer">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="p-2 rounded-lg bg-green-400/10 group-hover:bg-green-400/20 transition-colors">
                      <TrendingUp className="w-4 h-4 text-green-400" />
                    </div>
                    <span className="text-xs font-medium text-white/60">Success Rate</span>
                  </div>
                  <div className="text-3xl font-bold text-green-400">{metrics.success_rate}%</div>
                  <div className="mt-2 text-xs text-green-400/60">{metrics.invocations.successful} succeeded</div>
                </div>

                {/* Avg Execution Time */}
                <div className="group p-5 rounded-xl border border-white/10 bg-white/5 hover:bg-white/10 hover:border-blue-400/30 transition-all duration-300 cursor-pointer">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="p-2 rounded-lg bg-blue-400/10 group-hover:bg-blue-400/20 transition-colors">
                      <Clock className="w-4 h-4 text-blue-400" />
                    </div>
                    <span className="text-xs font-medium text-white/60">Avg Time</span>
                  </div>
                  <div className="text-3xl font-bold text-white">{metrics.avg_execution_time}</div>
                  <div className="mt-2 text-xs text-white/40">Per execution</div>
                </div>

                {/* CPU Usage */}
                <div className="group p-5 rounded-xl border border-white/10 bg-white/5 hover:bg-white/10 hover:border-purple-400/30 transition-all duration-300 cursor-pointer">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="p-2 rounded-lg bg-purple-400/10 group-hover:bg-purple-400/20 transition-colors">
                      <Cpu className="w-4 h-4 text-purple-400" />
                    </div>
                    <span className="text-xs font-medium text-white/60">CPU Usage</span>
                  </div>
                  <div className="text-3xl font-bold text-white">{metrics.cpu_usage}</div>
                  <div className="mt-2 text-xs text-white/40">Average</div>
                </div>

                {/* Memory Usage */}
                <div className="group p-5 rounded-xl border border-white/10 bg-white/5 hover:bg-white/10 hover:border-orange-400/30 transition-all duration-300 cursor-pointer">
                  <div className="flex items-center gap-2 mb-3">
                    <div className="p-2 rounded-lg bg-orange-400/10 group-hover:bg-orange-400/20 transition-colors">
                      <HardDrive className="w-4 h-4 text-orange-400" />
                    </div>
                    <span className="text-xs font-medium text-white/60">Memory Usage</span>
                  </div>
                  <div className="text-3xl font-bold text-white">{metrics.memory_usage}</div>
                  <div className="mt-2 text-xs text-white/40">Average</div>
                </div>
              </div>
            </div>
          )}

          {/* Success/Failed Stats */}
          {metrics && (
            <div className="mb-8">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="p-6 rounded-xl border border-green-400/30 bg-green-400/5 hover:bg-green-400/10 transition-all duration-300">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-3 rounded-lg bg-green-400/20">
                        <CheckCircle className="w-6 h-6 text-green-400" />
                      </div>
                      <div>
                        <div className="text-sm font-medium text-white/80">Successful Executions</div>
                        <div className="text-xs text-green-400/60 mt-1">{((metrics.invocations.successful / metrics.invocations.total) * 100).toFixed(1)}% of total</div>
                      </div>
                    </div>
                    <span className="text-3xl font-bold text-green-400">{metrics.invocations.successful.toLocaleString()}</span>
                  </div>
                </div>

                <div className="p-6 rounded-xl border border-red-400/30 bg-red-400/5 hover:bg-red-400/10 transition-all duration-300">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-3 rounded-lg bg-red-400/20">
                        <XCircle className="w-6 h-6 text-red-400" />
                      </div>
                      <div>
                        <div className="text-sm font-medium text-white/80">Failed Executions</div>
                        <div className="text-xs text-red-400/60 mt-1">{((metrics.invocations.failed / metrics.invocations.total) * 100).toFixed(1)}% of total</div>
                      </div>
                    </div>
                    <span className="text-3xl font-bold text-red-400">{metrics.invocations.failed.toLocaleString()}</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Execution Logs */}
          <div>
            <div className="flex items-center justify-between mb-6">
              <div>
                <h2 className="text-xl font-normal text-white mb-1">Execution History</h2>
                <p className="text-sm text-white/50">{jobs.length} recent executions</p>
              </div>
              <button 
                onClick={() => navigate(`/functions/${functionId}/logs`)}
                className="px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-white/70 text-sm hover:bg-white/10 hover:text-white transition-all"
              >
                View All
              </button>
            </div>
            <div className="rounded-xl border border-white/10 bg-white/[0.02] overflow-hidden shadow-xl">
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-white/[0.02] border-b border-white/10">
                    <tr>
                      <th className="px-6 py-4 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Job ID</th>
                      <th className="px-6 py-4 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Status</th>
                      <th className="px-6 py-4 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Timestamp</th>
                      <th className="px-6 py-4 text-left text-xs font-medium text-white/60 uppercase tracking-wider">Result</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-white/5">
                    {jobs.length > 0 ? (
                      jobs.map((job) => (
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
                          <td className="px-6 py-4 text-sm text-white/60">
                            {job.result ? (
                              <code className="text-xs bg-white/10 px-3 py-1.5 rounded font-mono">{JSON.stringify(job.result).substring(0, 50)}...</code>
                            ) : (
                              <span className="text-white/40 italic">No result</span>
                            )}
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={4} className="px-6 py-12 text-center text-white/40">
                          No execution history available
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  )
}

export default FunctionDetailPage
