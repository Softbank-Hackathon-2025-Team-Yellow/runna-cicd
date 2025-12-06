export interface FunctionDetail {
  function_id: string
  name: string
  runtime: 'python' | 'nodejs'
  code: string
  execution_type: 'sync' | 'async'
  url?: string
}

export interface Metrics {
  invocations: {
    total: number
    successful: number
    failed: number
  }
  success_rate: number
  avg_execution_time: string
  cpu_usage: string
  memory_usage: string
}

export interface Job {
  job_id: string
  status: 'pending' | 'running' | 'succeeded' | 'failed'
  timestamp: string
  result: any
}

export const MOCK_FUNCTION_DETAIL: FunctionDetail = {
  function_id: '1',
  name: 'my-awesome-function',
  runtime: 'nodejs',
  code: 'function handler(event) { return event }',
  execution_type: 'sync',
  url: 'https://api.runna.dev/functions/my-awesome-function'
}

export const MOCK_METRICS: Metrics = {
  invocations: {
    total: 1000,
    successful: 950,
    failed: 50
  },
  success_rate: 95,
  avg_execution_time: '120ms',
  cpu_usage: '70%',
  memory_usage: '256MB'
}

export const MOCK_JOBS: Job[] = [
  {
    job_id: '12345',
    status: 'succeeded',
    timestamp: '2023-10-30T10:00:00Z',
    result: { data: 'function result' }
  },
  {
    job_id: '67890',
    status: 'failed',
    timestamp: '2023-10-30T11:00:00Z',
    result: null
  },
  {
    job_id: '11111',
    status: 'succeeded',
    timestamp: '2023-10-30T09:30:00Z',
    result: { data: 'another result', count: 42 }
  },
  {
    job_id: '22222',
    status: 'running',
    timestamp: '2023-10-30T12:00:00Z',
    result: null
  },
  {
    job_id: '33333',
    status: 'pending',
    timestamp: '2023-10-30T12:15:00Z',
    result: null
  }
]
