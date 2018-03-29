'use strict';

var webpack = require('webpack');
var autoprefixer = require('autoprefixer');
var HtmlWebpackPlugin = require('html-webpack-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var UglifyJsPlugin = require('uglifyjs-webpack-plugin');
var pkg = require('./package.json');
var path = require("path");

var environment;
var environmentConfig;

if (process.env.ENVIRONMENT) {
	environment = process.env.ENVIRONMENT;
}
else {
	environmentConfig = require('./environment.json');
	environment = environmentConfig['environment'];

	if (!environment) {
		environment = process.env.NODE_ENV;
	}
}

var extractCSS = new ExtractTextPlugin({
	filename: "[name].bundle.css"
	// Disabling style-loader as fallback for dev for now.
	// Reason being that hot module reloading is moot with wintersmith since the site has to be statically re-generated
	// anyways. That way, all new content gets a generated html page, and existing content might be updated, etc. So new
	// html pages have to be reconstructed each time regardless, meaning we can't save on the performance hit for static
	// sites.
	//disable: environment === "development"
});

var allEnvironmentFeatures = require('./features.json');
var features = allEnvironmentFeatures[environment].config;
var ENV = process.env.npm_lifecycle_event;
var isTest = ENV === 'test' || ENV === 'test-watch';
// Gets set when running npm run build command, so disabling for now
//var isProd = ENV === 'build';
// We're gonna say it's always prod, that way our wintersmith builds are ready to deploy
// There's not much logic to debug, since it's a simple static site, so we're good with this.
var isProd = true;

console.log("Environment: " + environment);
console.log("ENV: " + ENV);

module.exports = function makeWebpackConfig() {

	var config = {};

	// NOTE: Use arrays for your entries in the Webpack config, rather than strings. Webpack won’t let you require an
	// entry directly if it is defined as a string, but if your entry is an array with exactly one string in it, it won’t
	// complain.  Source:
	// https://medium.com/all-things-picardy/dr-webpack-or-how-i-learned-to-stop-worrying-and-love-the-loaders-2dbc3e9d9f6a#.7g0s5qrx7
	config.entry = isTest ? {} : {
		app: ['./coffee/app.coffee'],
		//lib: ['./coffee/lib.coffee'],
	};

	config.output = isTest ? {} : {
		path: __dirname + '/dist',
		// Output path from the view of the page
		// Uses webpack-dev-server in development
		//publicPath: isProd ? '/' : features.baseUrl,
		// since dev server's url is changing, have webpack generate internal urls that are relative to whatever domain
		// it might be
		publicPath: isProd ? '/scripts/' : '/scripts/',
		filename: isProd ? '[name].[hash].js' : '[name].bundle.js',
		chunkFilename: isProd ? '[name].[hash].js' : '[name].bundle.js'
	};

	if (isTest) {
		//config.devtool = 'inline-source-map';
	} else if (isProd) {
		//config.devtool = 'source-map';
	} else {
		//config.devtool = 'eval-source-map';
		// Get source maps to work for chrome stack traces. Otherwise, we get weird
		// eval stacktraces.
		//
		// See: https://github.com/webpack/webpack/issues/1646
		// See: https://github.co/webpack/webpack/issues/1360
		//config.devtool = 'cheap-module-inline-source-map';
		//config.devtool = 'cheap-module-eval-source-map';
	}
	//config.devtool = 'cheap-module-eval-source-map';

	config.module = {
		rules: [
			{
				test: /\.json$/,
				use: "json-loader"
			},
			{
				test: /\.css$/,
				loader: isTest ? 'null' : extractCSS.extract({
					use: [{
						loader: "css-loader",
						options: {
							autoprefixer: false,
							zindex: false,
							sourceMap: true,
							minimize: true
						}
					}, {
						loader: "postcss-loader",
						options: {
							sourceMap: true
						}
					}],
					// use style-loader in development
					fallback: "style-loader"
				})
			},
			{
				test: /\.scss$/,
				use: isTest ? 'null' : extractCSS.extract({
					use: [{
						loader: "css-loader",
						options: {
							autoprefixer: false,
							zindex: false,
							sourceMap: true,
							minimize: true
						}
					}, {
						loader: "postcss-loader",
						options: {
							sourceMap: true
						}
					}, {
						loader: "resolve-url-loader",
						options: {
							sourceMap: true
						}
					}, {
						loader: "sass-loader?sourceMap",
						options: {
							sourceMap: true,
							includePaths: [
								// When installed locally
								path.resolve(__dirname, 'node_modules/foundation-sites/scss/'),
								path.resolve(__dirname, 'node_modules/foundation-icons'),
								// When installed using Dockerfile
								path.resolve(__dirname, '../packages/node_modules/foundation-sites/scss/'),
								path.resolve(__dirname, '../packages/node_modules/foundation-icons/')
							]
						}
					}],
					// use style-loader in development
					fallback: "style-loader"
				})
			},
			{
				test: /\.(png|jpg|jpeg|gif|svg|woff|woff2|ttf|eot)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
				use: 'file-loader',
			}, {
				test: /\.html$/,
				use: 'raw-loader',
			}, {
				test: /\.coffee$/,
				use: 'coffee-loader',
			}],
	};

	config.plugins = [
		new webpack.ProvidePlugin({
			$: "jquery",
			jQuery: "jquery",
			"window.jQuery": "jquery",
			"moment": "moment"
		}),
		new webpack.IgnorePlugin(/^\.\/locale$/, [/moment$/])
		// Use this plugin to only require the necessary locale
		//new webpack.ContextReplacementPlugin(/moment[\\\/]locale$/, /^\.\/(en|ko|ja|zh-cn)$/)
	];

	// Skip rendering index.html in test mode
	if (!isTest) {
		// Render index.html
		config.plugins.push(
			//new HtmlWebpackPlugin({
			//template: './path/to/entry/point/index.html',
			//inject: 'body'
			//}),
			extractCSS
			// Reference: https://github.com/webpack/extract-text-webpack-plugin
			// Extract css files
			// Disabled when in test mode or not in build mode
			//new ExtractTextPlugin('[name].[hash].css', {disable: !isProd})
		)
	}

	// Get our bundle ready for prod deployment!
	if (isProd) {
		config.plugins.push(
			// Reference: https://webpack.js.org/plugins/no-emit-on-errors-plugin/
			// Only emit files when there are no errors
			new webpack.NoEmitOnErrorsPlugin(),

			// Copy assets from the public folder
			// Reference: https://github.com/kevlened/copy-webpack-plugin
			// new CopyWebpackPlugin([{
			// 	from: __dirname + '/path/to/folder/with/assets'
			// }, {
			// 	from: __dirname + '/path/to/another/folder/with/assets'
			// }])
		)
	}
	// Dev plugins
	else {
		config.plugins.push(
			// Reference: https://github.com/webpack/webpack/issues/2145#issuecomment-251691937
			//
			// This gives more fine-grained control over source-map generation and is an alternative to using the
			// devtool config option above.
			new webpack.SourceMapDevToolPlugin({
				columns: false,
			}),
		)
	}

	// config.devServer = {
	// 	contentBase: './path/to/serve/from/as/root',
	// 	stats: 'minimal'
	// };

	// Alias for module references. Needed in case a dependency incorrectly
	// declares their own dependencies.
	config.resolve = {
		extensions: ['*', '.js'],
		alias: {
			spin: 'spin.js'
		},
		modules: [
			path.resolve(__dirname, '../packages/node_modules')
		]
	};

	config.resolveLoader = {
		modules: [
			// 'node_modules',
			path.resolve(__dirname, '../packages/node_modules')
		]
	};

	return config;
}();

