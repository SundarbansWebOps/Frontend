const { defineConfig } = require('@vue/cli-service')
module.exports = defineConfig({
  // transpileDependencies should be an array of dependency names to transpile.
  // It was accidentally set to `true` which causes Vue CLI to call `.map` on it.
  transpileDependencies: []
})
