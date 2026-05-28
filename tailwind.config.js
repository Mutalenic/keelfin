/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          50:  '#e6edf3',
          100: '#cae8ff',
          200: '#7ee787',
          300: '#56d364',
          400: '#3fb950',
          500: '#2ea043',
          600: '#238636',
          700: '#30363d',
          800: '#21262d',
          900: '#161b22',
          950: '#0d1117',
        }
      }
    }
  },
  plugins: [],
}
