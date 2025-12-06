import { LandingNavigation } from '../features/landing/components/LandingNavigation'
import { HeroSection } from '../features/landing/components/HeroSection'
import { FeaturesSection } from '../features/landing/components/FeaturesSection'
import { LandingFooter } from '../features/landing/components/LandingFooter'

function LandingPage(): JSX.Element {
  return (
    <div className="min-h-screen h-full bg-background-dark font-display">
      <LandingNavigation />
      <main id="main-content" className="bg-background-dark">
        <HeroSection />
        <FeaturesSection />
      </main>
      <LandingFooter />
    </div>
  )
}

export default LandingPage
