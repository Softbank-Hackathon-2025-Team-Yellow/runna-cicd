import React from 'react'

interface FunctionConfigProps {
  name: string
  onNameChange: (name: string) => void
}

export const FunctionConfig: React.FC<FunctionConfigProps> = ({
  name,
  onNameChange,
}) => {
  return (
    <div className="flex flex-col gap-4 p-4 bg-white/[.03] border border-white/10 rounded-lg h-full">
      {/* Function Name */}
      <div className="flex flex-col gap-2">
        <label className="text-sm font-normal text-white/80">
          Function Name <span className="text-red-400">*</span>
        </label>
        <input
          type="text"
          value={name}
          onChange={(e) => onNameChange(e.target.value)}
          placeholder="my-function"
          className="w-full rounded-lg border border-white/10 bg-white/5 py-2 px-3 text-sm text-white placeholder-white/50 focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none transition-all duration-300"
        />
      </div>

      {/* Additional config can go here */}
      <div className="flex-1"></div>
    </div>
  )
}
