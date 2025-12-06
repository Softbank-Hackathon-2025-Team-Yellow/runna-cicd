import { useState, useEffect } from 'react'

interface UseChangeTrackingOptions<T> {
  currentState: T
  onSave?: () => void
}

export const useChangeTracking = <T extends Record<string, any>>({
  currentState,
  onSave
}: UseChangeTrackingOptions<T>) => {
  const [lastSavedState, setLastSavedState] = useState<T>(currentState)
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false)
  const [recentlySaved, setRecentlySaved] = useState(false)

  // Track changes
  useEffect(() => {
    const hasChanges = JSON.stringify(currentState) !== JSON.stringify(lastSavedState)
    setHasUnsavedChanges(hasChanges)
  }, [currentState, lastSavedState])

  const markAsSaved = () => {
    setLastSavedState(currentState)
    setHasUnsavedChanges(false)
    setRecentlySaved(true)
    
    // Reset recently saved highlight after 3 seconds
    setTimeout(() => setRecentlySaved(false), 3000)
    
    onSave?.()
  }

  const resetChanges = () => {
    setHasUnsavedChanges(false)
    setRecentlySaved(false)
  }

  return {
    hasUnsavedChanges,
    recentlySaved,
    markAsSaved,
    resetChanges
  }
}
