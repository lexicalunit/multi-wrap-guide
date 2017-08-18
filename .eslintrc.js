module.exports = {
  'extends': 'standard',
  'plugins': [
    'standard',
    'promise'
  ],
  'globals': {
    'atom': true,
    'MutationObserver': true
  },
  'rules': {
    'no-multi-spaces': ['error', { 'ignoreEOLComments': true }]
  }
}
