import { Settings, Code, LayoutDashboard } from 'lucide-react'
import { FOOTER_LINKS, COPYRIGHT_TEXT } from '../constants/landing.constants'

export const LandingFooter = () => {
  return (
    <footer className="flex flex-col gap-8 px-5 py-16 sm:py-20 text-center mt-16 sm:mt-20 border-t border-solid border-white/10 bg-background-dark">
      <div className="px-4 sm:px-8 md:px-20 lg:px-40">
        {/* Footer Navigation Links */}
        <nav className="flex flex-wrap items-center justify-center gap-6 mb-6" aria-label="Footer navigation">
          {FOOTER_LINKS.map((link) => (
            <a
              key={link.label}
              href={link.href}
              className="text-white/80 text-base font-normal leading-normal min-w-40 hover:text-primary transition-all duration-300 hover:scale-105 relative group"
            >
              {link.label}
              <span className="absolute bottom-0 left-1/2 -translate-x-1/2 w-0 h-0.5 bg-primary transition-all duration-300 group-hover:w-full"></span>
            </a>
          ))}
        </nav>

        {/* Social/Platform Icons */}
        <div className="flex flex-wrap justify-center gap-6 mb-6">
          <a
            href="#settings"
            aria-label="Settings"
            className="text-white/80 hover:text-primary transition-all duration-300 hover:scale-110 hover:rotate-12"
          >
            <Settings className="w-6 h-6" aria-hidden="true" />
          </a>
          <a
            href="#code"
            aria-label="Code"
            className="text-white/80 hover:text-primary transition-all duration-300 hover:scale-110 hover:-rotate-12"
          >
            <Code className="w-6 h-6" aria-hidden="true" />
          </a>
          <a
            href="#dashboard"
            aria-label="Dashboard"
            className="text-white/80 hover:text-primary transition-all duration-300 hover:scale-110 hover:rotate-12"
          >
            <LayoutDashboard className="w-6 h-6" aria-hidden="true" />
          </a>
        </div>

        {/* Copyright Text */}
        <p className="text-white/80 text-base font-normal leading-normal">{COPYRIGHT_TEXT}</p>
      </div>
    </footer>
  )
}
