import { useState } from 'react'
import { Menu, X, Github } from 'lucide-react'
import { NAVIGATION_LINKS } from '../constants/landing.constants'

export const LandingNavigation = () => {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

  return (
    <nav 
      className="bg-background-dark border-b border-solid border-white/10 sticky top-0 z-50 backdrop-blur-sm bg-background-dark/95" 
      aria-label="Main navigation"
    >
      {/* Skip to main content link for keyboard users */}
      <a 
        href="#main-content" 
        className="sr-only focus:not-sr-only focus:absolute focus:top-2 focus:left-2 focus:z-50 focus:px-4 focus:py-2 focus:bg-primary focus:text-background-dark focus:font-medium focus:rounded-lg transition-all"
      >
        Skip to main content
      </a>
      <div className="px-4 sm:px-8 md:px-20 lg:px-40 py-3 sm:py-4">
        <div className="flex items-center justify-between whitespace-nowrap">
          {/* Logo */}
          <a 
            href="/" 
            className="flex items-center gap-4 focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-background-dark rounded-lg transition-all duration-300 hover:scale-105"
            aria-label="Runna home"
          >
            <img 
              src="/logo.png" 
              alt="Runna Logo" 
              className="size-8 sm:size-10 object-contain transition-transform duration-300 hover:rotate-12"
            />
            <h2 className="font-sporty text-xl sm:text-2xl leading-tight text-[#fece6d] tracking-wider italic">
              RUNNA
            </h2>
          </a>

          {/* Desktop Navigation Links */}
          <div className="hidden sm:flex flex-1 justify-end gap-8">
            <div className="flex items-center gap-9">
              {NAVIGATION_LINKS.map((link, index) => (
                <a
                  key={link.label}
                  href={link.href}
                  target={link.label === 'GitHub' ? '_blank' : undefined}
                  rel={link.label === 'GitHub' ? 'noopener noreferrer' : undefined}
                  className="text-base font-normal leading-normal bg-gradient-to-r from-white to-white hover:from-primary hover:to-primary bg-clip-text text-transparent transition-all duration-300 relative group flex items-center gap-2"
                  style={{ animationDelay: `${index * 100}ms` }}
                >
                  {link.label === 'GitHub' && <Github className="w-5 h-5 text-white group-hover:text-primary transition-colors" />}
                  {link.label}
                  <span className="absolute bottom-0 left-0 w-0 h-0.5 bg-gradient-to-r from-primary to-white transition-all duration-300 group-hover:w-full"></span>
                </a>
              ))}
            </div>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className="sm:hidden text-white hover:text-primary transition-colors p-2"
            aria-label="Toggle mobile menu"
            aria-expanded={isMobileMenuOpen}
          >
            {isMobileMenuOpen ? <X className="w-7 h-7" /> : <Menu className="w-7 h-7" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {isMobileMenuOpen && (
          <div className="sm:hidden mt-6 pb-4 animate-fade-in">
            <div className="flex flex-col gap-4">
              {NAVIGATION_LINKS.map((link) => (
                <a
                  key={link.label}
                  href={link.href}
                  target={link.label === 'GitHub' ? '_blank' : undefined}
                  rel={link.label === 'GitHub' ? 'noopener noreferrer' : undefined}
                  onClick={() => setIsMobileMenuOpen(false)}
                  className="text-lg font-normal leading-normal bg-gradient-to-r from-white to-primary bg-clip-text text-transparent hover:from-primary hover:to-white transition-all py-3 border-b border-white/10 last:border-0 flex items-center gap-2"
                >
                  {link.label === 'GitHub' && <Github className="w-5 h-5 text-white" />}
                  {link.label}
                </a>
              ))}
            </div>
          </div>
        )}
      </div>
    </nav>
  )
}
