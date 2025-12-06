import { HERO_CONTENT, CTA_BUTTONS } from '../constants/landing.constants'
import { ChevronDown } from 'lucide-react'

export const HeroSection = () => {
  return (
    <section className="py-12 sm:py-16 md:py-20 relative overflow-hidden">
      {/* Animated background gradient */}
      <div className="absolute inset-0 bg-gradient-to-b from-primary/5 via-transparent to-transparent opacity-50"></div>
      
      {/* Animated grid pattern */}
      <div className="absolute inset-0 opacity-[0.02]" style={{
        backgroundImage: 'linear-gradient(rgba(245, 166, 35, 0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(245, 166, 35, 0.3) 1px, transparent 1px)',
        backgroundSize: '50px 50px'
      }}></div>
      
      <div className="px-4 sm:px-8 md:px-20 lg:px-40 relative z-10">
        <div className="flex min-h-[600px] flex-col gap-8 sm:gap-10 items-center justify-center p-4 text-center">
          {/* Headline */}
          <h1 className="font-pixel text-[#fece6d] text-4xl leading-tight sm:text-6xl sm:leading-tight animate-fade-in-up mb-2 sm:mb-3">
            {HERO_CONTENT.headline}
          </h1>

          {/* Description */}
          <div className="flex flex-col sm:flex-row gap-8 sm:gap-12 animate-fade-in-up max-w-5xl mx-auto w-full px-4" style={{ animationDelay: '200ms' }}>
            <div className="flex-1 flex flex-col gap-2">
              <span className="text-primary text-xs font-normal uppercase tracking-wider">한국어</span>
              <p className="text-white/80 text-sm font-normal leading-relaxed sm:text-base sm:font-normal sm:leading-relaxed whitespace-pre-line">
                <span className="text-[#fece6d] font-normal">Runna</span>는 당신을 위한 미니멀 서버리스 엔진입니다.{'\n'}
                필요할 때는 즉시 달리고, 필요 없을 때는 완전히 멈춥니다.{'\n'}
                제로 스케일링으로 최고의 비용 효율성을 실현하세요.
              </p>
            </div>
            <div className="hidden sm:block w-px bg-gradient-to-b from-transparent via-white/20 to-transparent"></div>
            <div className="flex-1 flex flex-col gap-2">
              <span className="text-primary text-xs font-normal uppercase tracking-wider">日本語</span>
              <p className="text-white/70 text-xs font-normal leading-relaxed sm:text-sm sm:font-normal sm:leading-relaxed whitespace-pre-line">
                <span className="text-[#fece6d] font-normal">Runna</span>は、あなたのためのミニマルなサーバーレスエンジンです。{'\n'}
                必要なときは即座に走り、不要なときは完全に停止します。{'\n'}
                ゼロスケールで最高のコスト効率を実現しましょう。
              </p>
            </div>
          </div>

          {/* CTA Buttons */}
          <div className="flex-wrap gap-4 flex justify-center animate-fade-in-up mt-2" style={{ animationDelay: '400ms' }}>
            {/* Primary CTA Button */}
            <a
              href={CTA_BUTTONS.primary.href}
              className="flex min-w-[84px] max-w-[480px] cursor-pointer items-center justify-center overflow-hidden rounded-lg h-10 px-4 sm:h-12 sm:px-5 bg-primary text-background-dark text-sm font-medium leading-normal tracking-[0.015em] sm:text-base sm:font-medium sm:leading-normal sm:tracking-[0.015em] hover:brightness-110 hover:scale-105 hover:shadow-lg hover:shadow-primary/50 transition-all duration-300"
            >
              <span className="truncate">{CTA_BUTTONS.primary.label}</span>
            </a>

            {/* Secondary CTA Button */}
            <a
              href={CTA_BUTTONS.secondary.href}
              className="flex min-w-[84px] max-w-[480px] cursor-pointer items-center justify-center overflow-hidden rounded-lg h-10 px-4 sm:h-12 sm:px-5 bg-white/10 text-white text-sm font-medium leading-normal tracking-[0.015em] sm:text-base sm:font-medium sm:leading-normal sm:tracking-[0.015em] hover:bg-white/20 hover:scale-105 hover:border hover:border-primary/50 transition-all duration-300"
            >
              <span className="truncate">{CTA_BUTTONS.secondary.label}</span>
            </a>
          </div>
        </div>
      </div>

      {/* Scroll Indicator */}
      <div className="absolute bottom-8 left-0 right-0 flex justify-center">
        <a 
          href="#features"
          className="flex flex-col items-center gap-2 text-white/60 hover:text-primary transition-colors duration-300 animate-fade-in-up group"
          style={{ animationDelay: '600ms' }}
          aria-label="Scroll to features"
        >
          <span className="text-xs font-medium">Scroll Down</span>
          <ChevronDown className="w-6 h-6 animate-bounce" />
        </a>
      </div>
    </section>
  )
}
