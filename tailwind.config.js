const { default: daisyui } = require('daisyui');

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    colors: {
      'black': '#434343',
      'blue': '#13b5ea',
      'gray': '#777777',
      'white': '#ffffff',
      'navy': '#4776e6',
      'dark': '#0c1322',
      'light-gray': '#3b4351',
      'whitesmoke': '#f5f5f5',
      'gray-100': '#DDDDDD',
      'beige': '#e8d3ca',
      'sidebar': '#66758c',
      'purple': '#807fe2',
      'soft-blue': '#5755d9',
      'soft-green': '#3eb370',
      'red': '#FF6969',
    },
    fontFamily: {
      mono: ['Geologica', 'sans-serif']
    },
    height: {
      '128': '32rem',
      '144': '37rem',
    },
    safelist: [
      // カスタムクラスをセーフリストに追加
      'vertical-textarea'
    ],
  },
  daisyui: {
    themes: [
    {
      mytheme: {
        "primary": '#13b5ea',
      },
    },
    ],
  },
  plugins: [
    require('daisyui')
  ]
}
