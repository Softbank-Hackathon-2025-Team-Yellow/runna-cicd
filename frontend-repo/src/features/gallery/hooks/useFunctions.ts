import { useState, useEffect, useCallback } from 'react'
import { FunctionItem } from '../types/gallery.types'
import { MOCK_FUNCTIONS } from '../data/mockFunctions'

const USE_MOCK_DATA = import.meta.env.VITE_USE_MOCK_DATA === 'true'

export const useFunctions = () => {
  const [functions, setFunctions] = useState<FunctionItem[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchFunctions = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      
      if (USE_MOCK_DATA) {
        // Use mock data
        await new Promise(resolve => setTimeout(resolve, 500)) // Simulate API delay
        setFunctions(MOCK_FUNCTIONS)
      } else {
        // TODO: Fetch from real API
        // const response = await fetch('/api/functions')
        // const data = await response.json()
        // setFunctions(data)
        
        // For now, return empty array when not using mock data
        setFunctions([])
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch functions')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchFunctions()
  }, [fetchFunctions])

  const refresh = useCallback(() => {
    fetchFunctions()
  }, [fetchFunctions])

  return { functions, loading, error, refresh }
}
