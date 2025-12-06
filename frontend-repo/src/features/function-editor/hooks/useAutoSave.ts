import { useEffect, useState, useRef } from 'react'

export const useAutoSave = (
  data: any,
  onSave: () => Promise<void>,
  delay: number = 2000
) => {
  const [saving, setSaving] = useState(false)
  const [lastSaved, setLastSaved] = useState<Date | null>(null)
  const timeoutRef = useRef<ReturnType<typeof setTimeout>>()
  const previousDataRef = useRef<any>(null)
  const isFirstRender = useRef(true)

  useEffect(() => {
    // Skip on first render
    if (isFirstRender.current) {
      isFirstRender.current = false
      previousDataRef.current = data
      return
    }

    // Check if data actually changed
    const dataString = JSON.stringify(data)
    const previousDataString = JSON.stringify(previousDataRef.current)
    
    if (dataString === previousDataString) {
      return
    }

    // Update previous data
    previousDataRef.current = data

    // Clear existing timeout
    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current)
    }

    // Set new timeout
    timeoutRef.current = setTimeout(async () => {
      setSaving(true)
      try {
        await onSave()
        setLastSaved(new Date())
      } catch (error) {
        console.error('Auto-save failed:', error)
      } finally {
        setSaving(false)
      }
    }, delay)

    return () => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current)
      }
    }
  }, [data, delay])

  return { saving, lastSaved }
}
