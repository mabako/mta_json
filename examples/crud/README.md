# CRUD Example
(Create, Read, Update, Delete)

Tests whether you can create, read, update and delete posts from MTA

## Running the example

Start the rails server:

    $ cd rails
    $ rails s

Start the MTA Server and type the following commands:

    $ aclrequest crud allow all
    $ start crud

After that, the following commands are available within MTA (console, in-game)

* **/posts** - lists all posts

## How this was built - in rails

Creating the project:

    $ rails new CrudTest

**Manually** adding "gem 'mta_json'" to the Gemfile.

Running Bundler:

    $ bundle install

Generating a model Post along with a matching Controller:

    $ rails g scaffold post title:string text:text

Migrates the database to include the new posts table:

    $ rake db:migrate
