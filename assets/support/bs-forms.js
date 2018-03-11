require("coffee-script");

// The shell interface for bs-markdown.js
md = require('./bs-markdown');

markdown = "";

process.stdin.on('data', function(chunk){
  markdown += chunk;
});

process.stdin.on('end', function(){
    console.log(md.fromMarkdown(markdown));
});

