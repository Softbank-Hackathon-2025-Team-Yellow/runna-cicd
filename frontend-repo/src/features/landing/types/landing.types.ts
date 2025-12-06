export interface NavigationLink {
  label: string
  href: string
  isExternal?: boolean
}

export interface CTAButton {
  label: string
  href: string
}

export interface Feature {
  id: string
  title: string
  description: {
    ko: string
    ja: string
  }
  icon?: string
}

export interface FooterLink {
  label: string
  href: string
}

export interface SocialIcon {
  id: string
  ariaLabel: string
  href: string
}

export interface HeroContent {
  headline: string
  description: {
    ko: string
    ja: string
  }
}

export interface FeaturesContent {
  heading: string
  subheading: {
    ko: string
    ja: string
  }
}

export interface FeatureCardProps {
  title: string
  description: {
    ko: string
    ja: string
  }
  icon?: string
}
