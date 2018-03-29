// wintersmith-webpack-babel
// Copyright (c) 2016 Chris Peters
// Licensed under the MIT License
// Original source repo: https://github.com/bildepunkt/wintersmith-webpack-babel
// I modified it to fit my own use case, but you can get the original sources at the above link.

var webpack = require("webpack");
var webpackMerge = require('webpack-merge');
var webpackConfig = require("../webpack.config");
var fs = require("fs-extra");
var path = require("path");

/**
 * transpile and bundle es6 modules
 * @method xpile
 * @param  {String} entry The code's entry point
 * @param  {String} outFileName The filename to output
 * @param  {Function} callback Executes on compile complete, passing the bundle contents
 */
module.exports = function xpile(entry, outFileName, callback) {
	var xpiled;

	outFileName = outFileName || "bundle.js";
	callback = callback || function () {
	}

	var configs = [];

	var wintersmithWebpackConfig = {
		// wintersmith plugin assumes we're in contents, webpack does not
		//
		// aka the flow:
		//
		// - wintersmith gathers contents/ into a json ball
		// - wintersmith matches contenttypes (filetypes) to plugins as handlers
		// - wintersmith executes the plugin handlers on the filetypes
		// - as a result, the contents/coffee/main.coffee entrypoint gets associated with this plugin
		// - we then call out to webpack /during/ this whole compilation process
		// - we generate webpack files
		//
		// We could almost certainly run webpack outside of this whole process (using manual embeds of generated webpack
		// bundles); but I'm sticking with this because I'll probably want to play around with this in the future, maybe
		// see if I can register a ContentTree, have wintersmith preview rebuild maybe, etc.
		entry: path.resolve("contents", entry.relative),
		// output the file to a folder in the build path
		// NOTE: If I want to use a bundled hash, use HTMLWebpackPlugin and
		// programatically build the config object for each html page in the
		// snowball of wintersmith json content
		output: {
			path: __dirname + '/../build/scripts',
			filename: outFileName
		}
		// module: {
		//     loaders: [{
		//         test: /\.js$/,
		//         exclude: /node_modules/,
		//         loader: 'babel-loader',
		//         query: {
		//             presets: ['es2015']
		//         }
		//     }]
		// }
	};

	// TODO: Update this with a better merge method
	//
	// Literally just override certain webpackConfig's object values for some more specific ones we need with
	// Wintersmith (it'd actually make more sense if we didn't assign them in the first place to webpack.config.js, but
	// I use a boilerplate webpack, so I don't want to overthink it).
	// Create a new object
	var mergedWebpackConfig;

	// // Loop through obj1
	// for (var prop1 in webpackConfig) {
	//     if (webpackConfig.hasOwnProperty(prop1)) {
	//         // Push each value from `obj1` into `extended`
	//         mergedWebpackConfig[prop1] = webpackConfig[prop1];
	//     }
	// }
	//
	// // Loop through obj2
	// for (var prop2 in wintersmithWebpackConfig) {
	//     if (wintersmithWebpackConfig.hasOwnProperty(prop2)) {
	//         // Push each value from `obj2` into `extended`
	//         mergedWebpackConfig[prop2] = wintersmithWebpackConfig[prop2];
	//     }
	// }

	mergedWebpackConfig = webpackMerge({}, webpackConfig, wintersmithWebpackConfig);
	//configs.push(mergedWebpackConfig);

	console.log("WEBPACK CONFIG:");

	console.log(mergedWebpackConfig);

	webpack(mergedWebpackConfig, function (err, stats) {
		if (err) {
			throw err;
		}

		if (stats.compilation.errors && stats.compilation.errors.length) {
			stats.compilation.errors.forEach(function (name, e) {
				console.error("\n +-+-+ webpack compile error:", name, e, "\n");
			});

			return;
		}

		var result;

		// TODO: still need the try/catch?
		try {
			result = fs.readFileSync(path.resolve("build", "scripts", outFileName), "utf8");

			// copy to contents for `wintersmith preview` purposes
			fs.copySync(
				path.resolve("build", "scripts"),
				path.resolve("contents", "scripts")
			);
		} catch (err) {
			console.error(err);
		}

		callback(result);
	});
};
