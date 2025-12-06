import React from 'react'
import { useNavigate } from 'react-router-dom'
import { Clock, CheckCircle, AlertCircle, Loader, XCircle } from 'lucide-react'
import { FunctionItem, FunctionStatus } from '../types/gallery.types'

interface FunctionCardProps {
  function_item: FunctionItem
}

const getStatusConfig = (status: FunctionStatus) => {
  switch (status) {
    case 'succeeded':
      return {
        icon: CheckCircle,
        color: 'text-green-400',
        bgColor: 'bg-green-400/10',
        label: 'Succeeded',
      }
    case 'pending':
      return {
        icon: AlertCircle,
        color: 'text-yellow-400',
        bgColor: 'bg-yellow-400/10',
        label: 'Pending',
      }
    case 'running':
      return {
        icon: Loader,
        color: 'text-blue-400',
        bgColor: 'bg-blue-400/10',
        label: 'Running',
      }
    case 'failed':
      return {
        icon: XCircle,
        color: 'text-red-400',
        bgColor: 'bg-red-400/10',
        label: 'Failed',
      }
  }
}

const getLanguageConfig = (language: string) => {
  if (language === 'Node.js') {
    return {
      color: 'text-green-400',
      icon: (
        <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 1.5C11.5 1.5 11 1.7 10.7 2L2.2 7.5C1.5 7.9 1 8.7 1 9.5V14.5C1 15.3 1.5 16.1 2.2 16.5L10.7 22C11 22.3 11.5 22.5 12 22.5C12.5 22.5 13 22.3 13.3 22L21.8 16.5C22.5 16.1 23 15.3 23 14.5V9.5C23 8.7 22.5 7.9 21.8 7.5L13.3 2C13 1.7 12.5 1.5 12 1.5Z" fill="#68A063"/>
          <path d="M12 1.5V22.5" stroke="#68A063" strokeWidth="0.5"/>
        </svg>
      ),
    }
  } else if (language === 'Python') {
    return {
      color: 'text-blue-400',
      icon: (
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
      ),
    }
  }
  return {
    color: 'text-white/50',
    icon: null,
  }
}

export const FunctionCard: React.FC<FunctionCardProps> = ({ function_item }) => {
  const navigate = useNavigate()
  const statusConfig = getStatusConfig(function_item.status)
  const languageConfig = getLanguageConfig(function_item.language)
  const StatusIcon = statusConfig.icon

  const handleClick = () => {
    navigate(`/functions/${function_item.id}`)
  }

  return (
    <div
      onClick={handleClick}
      className="group flex cursor-pointer flex-col rounded-xl border border-white/10 bg-white/[.03] p-5 transition-all duration-300 hover:border-primary/50 hover:bg-white/5 hover:scale-[1.02] hover:shadow-lg hover:shadow-primary/10 h-[150px]"
    >
      {/* Header with Title and Status */}
      <div className="flex items-start justify-between gap-3 min-h-[48px] mb-4">
        <h3 className="text-base font-normal text-white group-hover:text-[#fece6d] transition-colors duration-300 flex-1 line-clamp-2 overflow-hidden" title={function_item.name}>
          {function_item.name}
        </h3>
        <div className={`flex items-center gap-1.5 ${statusConfig.bgColor} rounded-md px-2 py-1 text-xs flex-shrink-0 h-fit`}>
          <StatusIcon className={`w-3.5 h-3.5 ${statusConfig.color}`} />
          <span className={`${statusConfig.color} font-normal whitespace-nowrap`}>{statusConfig.label}</span>
        </div>
      </div>

      {/* Spacer */}
      <div className="flex-1"></div>

      {/* Language and Time Info */}
      <div className="flex flex-col gap-3 text-xs">
        <div className="flex items-center gap-2">
          {languageConfig.icon}
          <span className={`font-normal ${languageConfig.color}`}>{function_item.language}</span>
        </div>
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2 text-white/50">
            <Clock className="w-4 h-4" />
            <span className="font-normal">{function_item.lastUpdated}</span>
          </div>
          <span className={`px-2 py-1 rounded text-xs font-medium ${
            function_item.executionType === 'sync' 
              ? 'bg-purple-400/10 text-purple-400' 
              : 'bg-orange-400/10 text-orange-400'
          }`}>
            {function_item.executionType}
          </span>
        </div>
      </div>
    </div>
  )
}
