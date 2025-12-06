import React from 'react'
import { FunctionCard } from './FunctionCard'
import { useFunctions } from '../hooks/useFunctions'

interface FunctionGridProps {
  searchQuery: string
  onRefreshReady?: (refreshFn: () => void) => void
}

export const FunctionGrid: React.FC<FunctionGridProps> = ({ searchQuery, onRefreshReady }) => {
  const { functions, loading, error, refresh } = useFunctions()
  
  // Pass refresh function to parent
  React.useEffect(() => {
    if (onRefreshReady) {
      onRefreshReady(refresh)
    }
  }, [refresh, onRefreshReady])

  // Filter functions based on search query
  const filteredFunctions = React.useMemo(() => {
    if (!searchQuery.trim()) {
      return functions
    }
    
    const query = searchQuery.toLowerCase()
    return functions.filter((func) =>
      func.name.toLowerCase().includes(query)
    )
  }, [functions, searchQuery])

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="text-white/60 text-base">Loading functions...</div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="text-red-400 text-base">Error: {error}</div>
      </div>
    )
  }

  if (filteredFunctions.length === 0) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="text-white/60 text-base">
          {searchQuery ? `No functions found matching "${searchQuery}"` : 'No functions found.'}
        </div>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {filteredFunctions.map((func, index) => (
        <div
          key={func.id}
          className="animate-fade-in-up"
          style={{ animationDelay: `${index * 100}ms` }}
        >
          <FunctionCard function_item={func} />
        </div>
      ))}
    </div>
  )
}
