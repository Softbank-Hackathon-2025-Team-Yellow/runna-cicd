/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#f5a623',
        'background-dark': '#121212',
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        display: ['Inter', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
        pixel: ['DepartureMono', 'monospace'],
        sporty: ['Bebas Neue', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
