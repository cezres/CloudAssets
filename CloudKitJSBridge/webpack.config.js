const path = require('path');

module.exports = {
    // target: 'node',
  entry: './index.js',
  output: {
    filename: 'main.js',
    path: path.resolve(__dirname, 'dist'),
    library: "[name]",
    libraryTarget: "var"
  },
  resolve: {
    extensions: [".js", ".jsx"],
    fallback: {
      "http": require.resolve("stream-http"),
      "https": require.resolve("https-browserify"),
      "path": require.resolve("path-browserify"),
    }
  },
  optimization: {
    minimize: false
  },
};