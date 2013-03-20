# mta_json

Wraps MTA:SA's JSON format to support named parameters and different HTTP
methods with callRemote.

See [Multi Theft Auto: San Andreas](http://mtasa.com/).

## Installation

Add this line to your application's Gemfile:

    gem 'mta_json'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mta_json

## Configuration

### Whitelist for POST, PUT and DELETE

GET-requests are always processed.

POST-, PUT- and DELETE-requests are handled via an ip whitelist. The only
entry for this list is `127.0.0.1` per default.
It can be **overwritten** with the following code in your `application.rb`:

    config.mta_json.whitelist = %w(1.2.3.4 1.2.3.5)

Or, to still allow requests from your local machine:

    config.mta_json.whitelist = %w(1.2.3.4 1.2.3.5 127.0.0.1)

## Usage

### Rails

There are no changes required to any specific code, so long as your controller
actions respond to JSON and returns JSON.

The following would just work fine:

    # route:
    #   resources :posts, :only => [:show, :index]
    class PostsController < ApplicationController
      def index
        @posts = Post.all

        respond_to do |format|
          format.html
          format.json { render :json => @posts }
        end
      end

      def show
        @post = Post.find(params[:id])

        respond_to do |format|
          format.html
          format.json { render :json => @post }
        end
      end
    end

### MTA:SA

The basic parameters for callRemote are:

    callRemote(url, your_function, params, options)

where

* **params** will be present as `params` hash in your application.
  For example,

  <pre>callRemote(url, your_function, { name = 'mabako', password = '****' })</pre>

  will allow you to use `params[:name]` and `params[:password]`

* **options** contained options as hints to the JSON-Wrapper.
    * **method** overwrites the default POST HTTP verb, only 'GET' is a valid
       alternative currently.

The format is not `posts.json` for URLs but `posts.mta`. This gem will rewrite
the URL to be `posts.json` as well as handle MTA-specific code.

The following example code shows just how you'd retrieve the list of posts
returned by above Rails-specific example.

    callRemote('http://localhost/posts.mta',
      function(posts, err)
        if posts ~= 'ERROR' then
          outputDebugString('Retrieved ' .. #posts .. ' posts: ')
          for k, post in ipairs(posts) do
            -- assumes your @post in rails has a 'text' attribute
            outputDebugString(post.text)
          end
        else
          outputDebugString('Failed to retrieve blog posts, error: ' .. tostring(err), 2)
        end
      end,
      nil, # no parameters to pass
      {method = 'GET'} # MTA has POST as default, pick GET instead
    )

Likewise to retrieve a single post:

    callRemote('http://localhost/posts/1.mta',
      function(post, err)
        if post ~= 'ERROR' then
          -- assumes your @post in rails has a 'text' attribute
          outputDebugString(post.text)
        else
          outputDebugString('Failed to retrieve blog post, error: ' .. tostring(err), 2)
        end
      end,
      nil,
      {method = 'GET'}
    )

A more complete example can be found in `examples/crud`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODOs

* Special care should be taken with the default POST method, there currently is
  no way to set a CSRF-Token. This can be worked around by using:

  <pre>skip_before_filter :verify_authenticity_token, :only => :your_method</pre>

* running rails behind a proxy/load balancer and IP resolution?
