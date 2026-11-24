// Resolver de Jest: combina el de Reanimated/Worklets (usa las versiones web
// de algunos módulos) con el de React Native que trae jest-expo.
const reanimated = require('react-native-reanimated/jest/resolver');
const reactNative = require('@react-native/jest-preset/jest/resolver');

module.exports = (request, options) =>
  reanimated(request, {
    ...options,
    defaultResolver: (req, opts) =>
      reactNative(req, { ...opts, defaultResolver: options.defaultResolver }),
  });
