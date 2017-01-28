# tehpotatoking.com

Personal blog powered by Wintersmith static site generator

## Requirements

Be sure to have [Node Package Manager (npm)](http://nodejs.org/download/)
installed. Npm is bundled and installed automatically with Node.js.
[Ruby 2.0.0](https://www.ruby-lang.org/en/downloads/) is needed as well.

## Setup

Setting up a buildable project is very simple:

    git clone https://github.com/hackbytes/tehpotatoking.com.git
    cd tehpotatoking.com
    ./init.sh

Once all necessary dependencies have been installed by the init command,
you can open up the project in your preferred editor and run builds, perform
unit tests or anything else!

## Usage

You can use your favorite IDE to run all builds and unit tests. If you prefer
to use the command line, you can use grunt tasks to run builds and test the
application.

The following is a list of all available commands. Execute whichever command
you need.

To build the website:

    grunt build

To build and run both the website and all tests:

    grunt test

To build the tests without running them:

    grunt build-tests

To run the tests without building them (this assumes you have previously built
them):

    grunt run-tests

To clean all built files:

    grunt clean

To deploy the website to the server:

    grunt deploy

To bulk update the YAML front-matter of every post

    grunt yaml:key:value

To view posts that can be unpublished. Specify a skill or a notebook to narrow 
down the list.

    grunt publish[:skill][:notebook]

To publish a post

    grunt publish:skill:notebook:post

To view posts that can be unpublished. Specify a skill or a notebook to narrow 
down the list.

    grunt publish[:skill][:notebook]

To unpublish a post

    grunt unpublish:skill:notebook:post

## Comments

The comments database is created upon submission of the first comment. The
following is a list of all available commands for managing comments once the
database is created.

To pull the comments database from the server:

    grunt comments-pull

To display a list of all comments along with their ids:

    grunt comments-list

To view the contents of a comment:

    grunt comments-view:id

To publish a comment:

    grunt comments-publish:id

To unpublish a comment:

    grunt comments-unpublish:id

To delete a comment:

    grunt comments-delete:id

To push the modified database back to the server:

    grunt comments-push

## Copyright / License

tehpotatoking.com is Copyright (c) 2014 tehPotatoKing.com, licensed under the 
GNU GPL v2.0.

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, version 2 of the License.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.

tehpotatoking.com includes works under other copyright notices and distributed
according to the terms of the GNU General Public License or a compatible
license, including:

  TODO

