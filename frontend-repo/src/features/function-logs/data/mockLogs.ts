export interface LogJob {
  job_id: string
  status: 'pending' | 'running' | 'succeeded' | 'failed'
  timestamp: string
  execution_time: string
  result: any
  error?: string
}

export const generateMockLogs = (count: number = 50): LogJob[] => {
  return Array.from({ length: count }, (_, i) => {
    const isSuccess = Math.random() > 0.2
    return {
      job_id: `job-${String(count - i).padStart(5, '0')}`,
      status: isSuccess ? 'succeeded' : 'failed',
      timestamp: new Date(Date.now() - i * 3600000).toISOString(),
      execution_time: `${Math.floor(Math.random() * 500 + 50)}ms`,
      result: isSuccess ? { 
        data: `Result for job ${count - i}`,
        processed: Math.floor(Math.random() * 100),
        timestamp: new Date(Date.now() - i * 3600000).toISOString()
      } : null,
      error: isSuccess ? undefined : `Error: Function execution failed - ${['Timeout', 'Memory limit exceeded', 'Invalid input', 'Network error'][Math.floor(Math.random() * 4)]}`
    }
  })
}

export const MOCK_FUNCTION_NAME = 'my-awesome-function'
