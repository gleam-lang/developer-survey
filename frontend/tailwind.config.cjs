/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{html,js,gleam}"],
  theme: {
    extend: {
      colors: {
        "pink": "#ffaff3",
        "charcoal": "#282828"
      }
    },
  },
  plugins: [
    require('@tailwindcss/typography')
  ],
}
