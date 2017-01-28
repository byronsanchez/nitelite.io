#!/usr/bin/env sh

# npm dependency validation
command -v npm >/dev/null 2>&1 || {
  printf >&2 "Please install Node.js\n";
  exit 1;
}

# ruby dependency validation
command -v gem >/dev/null 2>&1 || {
  printf >&2 "Please install Ruby\n";
  exit 2;
}

command -v grunt >/dev/null 2>&1 || {
  # NOTE: Make sure .npmrc has a prefix of ~/.npm or that the npm node_modules 
  # dir is writable by the user. Alternatively, you will have to sudo install 
  # grunt-cli
  printf >&2 "Installing grunt-cli...\n";
  npm install -g grunt-cli
  if [ $? -ne 0 ];
  then
    printf >&2 "grunt-cli installation failed. You may have to run:\n"
    printf >&2 "\n"
    printf >&2 "  sudo npm install -g grunt-cli\n"
  fi
}

command -v bundle >/dev/null 2>&1 || {
  printf >&2 "Installing bundler...\n";
  gem install bundler
  gem update rdoc
}

# Initialization to setup a buildable application
npm install
# set the linker to g++ so the rebuild works on NFS shares
LINK=g++ npm rebuild
./node_modules/.bin/bower install
bundle install

