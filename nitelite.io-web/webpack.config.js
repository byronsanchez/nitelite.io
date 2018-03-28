'use strict';

// NOTE: Getting webpack dev-server to run work with WebStorm debugging.
//
// THE LAST LINK CONTAINS THE ANSWER. The rest is just to get an idea of how the javascript debug configuration thing
// works in WebStorm.
//
// See: https://blog.jetbrains.com/webstorm/2015/09/debugging-webpack-applications-in-webstorm/
// See: https://youtrack.jetbrains.com/issue/WEB-19884
// See:
// http://stackoverflow.com/questions/34785314/how-to-debug-angular2-seed-project-in-phpstorm-webstorm/34789890#34789890

// Modules
var webpack = require('webpack');
var autoprefixer = require('autoprefixer');
var HtmlWebpackPlugin = require('html-webpack-plugin');
var ExtractTextPlugin = require('extract-text-webpack-plugin');
var CopyWebpackPlugin = require('copy-webpack-plugin');
var pkg = require('./package.json');
var path = require("path");
var coffee = require("coffee-loader");

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

console.log("Environment: " + environment);

var extractCSS = new ExtractTextPlugin({
	filename: "[name].css"
	//disable: environment === "development"
});

var allEnvironmentFeatures = require('./features.json');
var features = allEnvironmentFeatures[environment].config;

/**
 * Env
 * Get npm lifecycle event to identify the environment
 */

var ENV = process.env.npm_lifecycle_event;
var isTest = ENV === 'test' || ENV === 'test-watch';
var isProd = ENV === 'build';

console.log("ENV: " + ENV);

module.exports = function makeWebpackConfig() {
	/**
	 * Config
	 * Reference: http://webpack.github.io/docs/configuration.html
	 * This is the object where all configuration gets set
	 */
	var config = {};

	/**
	 * Entry
	 * Reference: http://webpack.github.io/docs/configuration.html#entry
	 * Should be an empty object if it's generating a test build
	 * Karma will set this when it's a test build
	 */

	// NOTE: Use arrays for your entries in the Webpack config, rather than strings. Webpack won’t let you require an
	// entry directly if it is defined as a string, but if your entry is an array with exactly one string in it, it won’t
	// complain.  Source:
	// https://medium.com/all-things-picardy/dr-webpack-or-how-i-learned-to-stop-worrying-and-love-the-loaders-2dbc3e9d9f6a#.7g0s5qrx7
	config.entry = isTest ? {} : {
		app: ['./coffee/app.coffee'],
		//lib: ['./coffee/lib.coffee'],
	};

	/**
	 * Output
	 * Reference: http://webpack.github.io/docs/configuration.html#output
	 * Should be an empty object if it's generating a test build
	 * Karma will handle setting it up for you when it's a test build
	 */
	config.output = isTest ? {} : {
		// Absolute output directory
		path: __dirname + '/dist',

		// Output path from the view of the page
		// Uses webpack-dev-server in development
		publicPath: isProd ? '/' : features.baseUrl,

		// Filename for entry points
		// Only adds hash in build mode
		filename: isProd ? '[name].[hash].js' : '[name].bundle.js',

		// Filename for non-entry points
		// Only adds hash in build mode
		chunkFilename: isProd ? '[name].[hash].js' : '[name].bundle.js'
	};

	/**
	 * Devtool
	 * Reference: http://webpack.github.io/docs/configuration.html#devtool
	 * Type of sourcemap to use per build type
	 */
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

	/**
	 * Loaders
	 * Reference: http://webpack.github.io/docs/configuration.html#module-loaders
	 * List: http://webpack.github.io/docs/list-of-loaders.html
	 * This handles most of the magic responsible for converting modules
	 */

	// Initialize module
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
						loader: "css-loader?sourceMap!"
					}, {
						loader: "postcss"
					}],
					// use style-loader in development
					fallback: "style-loader" // activate source maps via loader query
				})
			},
			{
				test: /\.scss$/,
				use: isTest? 'null' : extractCSS.extract({
					use: [{
						loader: "css-loader?sourceMap!"
					}, {
						loader: "sass-loader?sourceMap"
					}],
					// use style-loader in development
					fallback: "style-loader" // activate source maps via loader query
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

	// ISPARTA LOADER
	// Reference: https://github.com/ColCh/isparta-instrumenter-loader
	// Instrument JS files with Isparta for subsequent code coverage reporting
	// Skips node_modules and files that end with .test.js
	if (isTest) {
		config.module.preLoaders.push({
			test: /\.js$/,
			exclude: [
				/node_modules/,
				/\.spec\.js$/
			],
			loader: 'isparta-instrumenter'
		})
	}

	/**
	 * PostCSS
	 * Reference: https://github.com/postcss/autoprefixer-core
	 * Add vendor prefixes to your css
	 */
	// config.postcss = [
	//     autoprefixer({
	//         browsers: ['last 2 version']
	//     })
	// ];

	/**
	 * Plugins
	 * Reference: http://webpack.github.io/docs/configuration.html#plugins
	 * List: http://webpack.github.io/docs/list-of-plugins.html
	 */
	// This might be good for an attempt to split the entry points into app.js and
	// lib.js
	config.plugins = [
		new webpack.ProvidePlugin({
			//_s: 'underscore.string',
			//_: 'underscore',
			//Modernizr: 'modernizr-2.6.2.min.js',
			//'window.Modernizr': 'modernizr-2.6.2.min.js',
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
		// Reference: https://github.com/ampedandwired/html-webpack-plugin
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

	// Add build specific plugins
	if (isProd) {
		config.plugins.push(
			// Reference: https://github.com/webpack/webpack/issues/2145#issuecomment-251691937
			new webpack.SourceMapDevToolPlugin({
				columns: false,
			}),
			// Reference: http://webpack.github.io/docs/list-of-plugins.html#noerrorsplugin
			// Only emit files when there are no errors
			new webpack.NoErrorsPlugin(),

			// Reference: http://webpack.github.io/docs/list-of-plugins.html#dedupeplugin
			// Dedupe modules in the output
			new webpack.optimize.DedupePlugin(),

			// Reference: http://webpack.github.io/docs/list-of-plugins.html#uglifyjsplugin
			// Minify all javascript, switch loaders to minimizing mode
			//new webpack.optimize.UglifyJsPlugin(),

			// Copy assets from the public folder
			// Reference: https://github.com/kevlened/copy-webpack-plugin
			// TODO: Implement this
			new CopyWebpackPlugin([{
				from: __dirname + '/path/to/folder/with/assets'
			}, {
				from: __dirname + '/path/to/another/folder/with/assets'
			}])
		)
	}

	/**
	 * Dev server configuration
	 * Reference: http://webpack.github.io/docs/configuration.html#devserver
	 * Reference: http://webpack.github.io/docs/webpack-dev-server.html
	 */
	config.devServer = {
		contentBase: './path/to/serve/from/as/root',
		stats: 'minimal'
	};

	// Alias for module references. Needed in case a dependency incorrectly
	// declares their own dependencies.
	config.resolve = {
		extensions: ['*', '.js'],
		alias: {
			spin: 'spin.js'
		}
	};

	return config;
}();

