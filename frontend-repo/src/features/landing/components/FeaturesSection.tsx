import React from 'react'
import { FeatureCard } from './FeatureCard'
import { FEATURES_CONTENT, FEATURES } from '../constants/landing.constants'

export const FeaturesSection: React.FC = () => {
  return (
    <section id="features" className="flex flex-col gap-12 px-4 sm:px-8 md:px-20 lg:px-40 py-16 sm:py-20 md:py-24 relative">
      {/* Section Heading and Subheading */}
      <div className="flex flex-col gap-6 text-center animate-fade-in-up">
        <h1 className="font-pixel text-[#fece6d] text-3xl leading-tight sm:text-4xl sm:leading-tight max-w-[720px] mx-auto">
          {FEATURES_CONTENT.heading}
        </h1>
        <div className="flex flex-col gap-3 max-w-[720px] mx-auto">
          <p className="text-white/80 text-base font-normal leading-normal">
            {FEATURES_CONTENT.subheading.ko}
          </p>
          <p className="text-white/70 text-sm font-normal leading-normal">
            {FEATURES_CONTENT.subheading.ja}
          </p>
        </div>
      </div>

      {/* Feature Cards Grid */}
      <div className="flex flex-col gap-6 max-w-3xl mx-auto w-full mt-4">
        {FEATURES.map((feature, index) => (
          <div
            key={feature.id}
            className="animate-fade-in-up"
            style={{ animationDelay: `${index * 150}ms` }}
          >
            <FeatureCard
              title={feature.title}
              description={feature.description}
              icon={feature.icon}
            />
          </div>
        ))}
      </div>
    </section>
  )
}
