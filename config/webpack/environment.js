const { environment } = require('@rails/webpacker')
const webpack = require('webpack')

// エントリーポイントの設定を追加
environment.config.merge({
  entry: {
    application: './app/javascript/packs/application.js'
  }
})

environment.plugins.prepend('Provide', 
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    Popper: ['popper.js', 'default']
  })
)

module.exports = environment