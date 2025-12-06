// API DTO 타입 정의
export interface ApiResponse<T> {
  data: T
  message: string
  status: number
}

export interface ApiError {
  message: string
  status: number
  errors?: Record<string, string[]>
}
