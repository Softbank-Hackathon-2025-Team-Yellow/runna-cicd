export type Runtime = 'Node.js' | 'Python'
export type ExecutionMode = 'sync' | 'async'

export interface FunctionConfig {
  name: string
  runtime: Runtime
  code: string
  executionMode: ExecutionMode
}

export interface DeploymentResult {
  success: boolean
  url?: string
  error?: string
}

export interface TestRequest {
  url: string
  body: string
}

export interface TestResponse {
  status: number
  body: string
  error?: string
}
