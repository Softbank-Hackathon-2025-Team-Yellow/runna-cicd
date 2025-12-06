import React from 'react'
import { FeatureCardProps } from '../types/landing.types'
import { RefreshCw, Zap } from 'lucide-react'

const iconMap: Record<string, React.ReactNode> = {
  sync: <RefreshCw className="w-8 h-8" />,
  scale: <Zap className="w-8 h-8" />,
}

export const FeatureCard: React.FC<FeatureCardProps> = ({ title, description, icon }) => {
  const iconElement = icon && typeof icon === 'string' ? iconMap[icon] : null

  return (
    <div className="flex flex-col gap-4 rounded-xl border border-white/10 bg-white/5 p-8 transition-all duration-300 hover:bg-white/10 hover:border-primary/50 hover:shadow-lg hover:shadow-primary/20 hover:scale-[1.01] cursor-pointer min-h-[140px] group min-w-[420px]">
      {iconElement && (
        <div className="text-primary transition-transform duration-300 group-hover:rotate-3 origin-center">
          {iconElement}
        </div>
      )}
      <div className="flex flex-col gap-3">
        <h2 className="text-white text-lg font-normal leading-tight whitespace-nowrap">{title}</h2>
        <div className="flex flex-col gap-2">
          <p className="text-white/70 text-base font-normal leading-relaxed">{description.ko}</p>
          <p className="text-white/60 text-sm font-normal leading-relaxed">{description.ja}</p>
        </div>
      </div>
    </div>
  )
}
