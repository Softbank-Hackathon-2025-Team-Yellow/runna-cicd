import React from 'react'
import { Runtime } from '../types/editor.types'

interface RuntimeSelectorProps {
  runtime: Runtime
  onChange: (runtime: Runtime) => void
}

export const RuntimeSelector: React.FC<RuntimeSelectorProps> = ({ runtime, onChange }) => {
  return (
    <div className="flex items-center gap-0.5 p-1 bg-white/5 border border-white/10 rounded-lg">
      <button
        onClick={() => onChange('Node.js')}
        className={`flex items-center gap-2 py-1.5 px-3 rounded text-xs font-medium transition-all duration-300 ${
          runtime === 'Node.js'
            ? 'bg-green-400/20 text-green-400 shadow-sm'
            : 'text-white/60 hover:text-white/80 hover:bg-white/5'
        }`}
      >
        <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 1.5C11.5 1.5 11 1.7 10.7 2L2.2 7.5C1.5 7.9 1 8.7 1 9.5V14.5C1 15.3 1.5 16.1 2.2 16.5L10.7 22C11 22.3 11.5 22.5 12 22.5C12.5 22.5 13 22.3 13.3 22L21.8 16.5C22.5 16.1 23 15.3 23 14.5V9.5C23 8.7 22.5 7.9 21.8 7.5L13.3 2C13 1.7 12.5 1.5 12 1.5Z" fill="currentColor"/>
        </svg>
        <span>Node.js</span>
      </button>
      <button
        onClick={() => onChange('Python')}
        className={`flex items-center gap-2 py-1.5 px-3 rounded text-xs font-medium transition-all duration-300 ${
          runtime === 'Python'
            ? 'bg-blue-400/20 text-blue-400 shadow-sm'
            : 'text-white/60 hover:text-white/80 hover:bg-white/5'
        }`}
      >
        <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M9.585 11.692h4.328s2.432.039 2.432-2.35V5.391S16.714 3 11.936 3C7.362 3 7.647 3 7.647 3l-.006 2.347h4.363v.617H5.92s-2.927-.332-2.927 4.282 0 4.09 0 4.09h1.735v-2.383s-.093-2.261 2.226-2.261z" fill="url(#python-gradient-1)"/>
          <path d="M14.415 12.308h-4.328s-2.432-.04-2.432 2.35v3.951S7.286 21 12.064 21c4.574 0 4.289 0 4.289 0l.006-2.347h-4.363v-.617h6.084s2.927.332 2.927-4.282 0-4.09 0-4.09h-1.735v2.383s.093 2.261-2.226 2.261z" fill="url(#python-gradient-2)"/>
          <circle cx="8.5" cy="5.5" r="0.9" fill="#fff"/>
          <circle cx="15.5" cy="18.5" r="0.9" fill="#fff"/>
          <defs>
            <linearGradient id="python-gradient-1" x1="7" y1="3" x2="7" y2="14" gradientUnits="userSpaceOnUse">
              <stop stopColor="#387EB8"/>
              <stop offset="1" stopColor="#366994"/>
            </linearGradient>
            <linearGradient id="python-gradient-2" x1="17" y1="10" x2="17" y2="21" gradientUnits="userSpaceOnUse">
              <stop stopColor="#FFE873"/>
              <stop offset="1" stopColor="#FFC331"/>
            </linearGradient>
          </defs>
        </svg>
        <span>Python</span>
      </button>
    </div>
  )
}
