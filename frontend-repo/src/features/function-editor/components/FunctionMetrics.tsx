import React, { useState } from 'react'
import { Activity, Clock, Cpu, HardDrive, CheckCircle, XCircle } from 'lucide-react'

interface Metrics {
  executionTime: number
  cpuUsage: number
  memoryUsage: number
  successCount: number
  failureCount: number
}

interface FunctionMetricsProps {
  metrics: Metrics
}

export const FunctionMetrics: React.FC<FunctionMetricsProps> = ({ metrics }) => {
  const [expanded, setExpanded] = useState(false)

  return (
    <div
      className="relative"
      onMouseEnter={() => setExpanded(true)}
      onMouseLeave={() => setExpanded(false)}
    >
      {/* Compact View */}
      <div className="flex items-center gap-3 px-3 py-1.5 bg-white/[.03] border border-white/10 rounded-lg cursor-pointer">
        <Activity className="w-3.5 h-3.5 text-primary" />
        <span className="text-xs text-white/60">Metrics</span>
      </div>

      {/* Expanded View */}
      {expanded && (
        <div className="absolute top-full left-0 mt-2 w-64 p-4 bg-background-dark border border-white/10 rounded-lg shadow-lg z-50 animate-fade-in">
          <h4 className="text-sm font-normal text-white mb-3">Function Metrics</h4>
          
          <div className="flex flex-col gap-2.5">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Clock className="w-3.5 h-3.5 text-blue-400" />
                <span className="text-xs text-white/70">Execution Time</span>
              </div>
              <span className="text-xs font-normal text-white">{metrics.executionTime}ms</span>
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Cpu className="w-3.5 h-3.5 text-green-400" />
                <span className="text-xs text-white/70">CPU Usage</span>
              </div>
              <span className="text-xs font-normal text-white">{metrics.cpuUsage}%</span>
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <HardDrive className="w-3.5 h-3.5 text-yellow-400" />
                <span className="text-xs text-white/70">Memory Usage</span>
              </div>
              <span className="text-xs font-normal text-white">{metrics.memoryUsage}MB</span>
            </div>

            <div className="h-px bg-white/10 my-1"></div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <CheckCircle className="w-3.5 h-3.5 text-green-400" />
                <span className="text-xs text-white/70">Success</span>
              </div>
              <span className="text-xs font-normal text-green-400">{metrics.successCount}</span>
            </div>

            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <XCircle className="w-3.5 h-3.5 text-red-400" />
                <span className="text-xs text-white/70">Failure</span>
              </div>
              <span className="text-xs font-normal text-red-400">{metrics.failureCount}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
