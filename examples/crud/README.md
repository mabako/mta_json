# CRUD Example
(Create, Read, Update, Delete)

Tests whether you can create, read, update and delete posts from MTA


## Building a simple CRUD-based controller

Creating the project:

    $ rails new CrudTest

**Manually** adding "gem 'mta_json'" to the Gemfile.

Running Bundler:

    $ bundle install

Generating a model Post along with a matching Controller:

    $ rails g scaffold post title:string text:text

Migrates the database to include the new posts table:

    $ rake db:migrate

## Running the example

Start the rails server:

    $ cd rails
    $ rails s

Start the MTA Server and type the following commands:

    $ aclrequest crud allow all
    $ start crud
