interface EmptyStateProps {
  message?: string
}

function EmptyState({ message = '데이터가 없습니다.' }: EmptyStateProps): JSX.Element {
  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="text-gray-500 text-center">
        <p className="text-lg">{message}</p>
      </div>
    </div>
  )
}

export default EmptyState
