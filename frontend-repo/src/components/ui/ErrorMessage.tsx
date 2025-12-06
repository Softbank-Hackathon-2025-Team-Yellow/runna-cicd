interface ErrorMessageProps {
  message?: string
}

function ErrorMessage({ message = '오류가 발생했습니다.' }: ErrorMessageProps): JSX.Element {
  return (
    <div className="flex items-center justify-center min-h-screen">
      <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
        <p>{message}</p>
      </div>
    </div>
  )
}

export default ErrorMessage
