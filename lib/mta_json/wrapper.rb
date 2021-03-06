module MtaJson
  # wraps calls to .mta-urls in a MTA-specific format.
  # The main difference is:
  # * the request body needs to have the surrounding [ ] removed (which technically represents a JSON-Array)
  # * the response body needs [ ] added (again, a JSON-Array) which consists of:
  #   * body of the response
  #   * headers
  # MTA technically allows multiple parameters, but that doesn't really suit rails' named parameters (param[:cake]).
  class Wrapper
    # env[...]
    CONTENT_TYPE = 'CONTENT_TYPE'.freeze
    BODY = 'rack.input'.freeze
    FORM_INPUT = 'rack.request.form_input'.freeze
    FORM_HASH = 'rack.request.form_hash'.freeze
    SESSION = 'rack.session'.freeze
    METHOD = 'REQUEST_METHOD'.freeze
    POST = 'POST'.freeze
    PATH_INFO = 'PATH_INFO'.freeze
    IP = 'REMOTE_ADDR'.freeze
    CSRF_TOKEN = 'X-CSRF-Token'.freeze

    # HTTP-Response-Headers
    CONTENT_LENGTH = 'Content-Length'.freeze

    # Allowed Methods to be set by MTA
    ALLOWED_METHODS = %w(GET)
    ALLOWED_METHODS_PRIVATE = %w(POST PUT DELETE)

    def initialize app
      @app = app
    end

    # callRemote on the MTA-side may have [0, 1 or 2] parameter(s):
    # * if no parameters, params[...] is empty within rails
    # * first parameter - as a table - fills the params[...] hash which is accessible in controllers (etc)
    #   i.e.
    #     callRemote("http://localhost/auth.mta", function, { name = 'a', password = 'b' })
    #   makes the following parameters available in the called controller
    #     params[:name] = 'a'
    #     params[:password] = 'b'
    # * second parameter - as a table - options on how the request is handled. See update_options for details,
    #   for example { 'method' = 'GET' } allows GET-Requests, while usually callRemote does only POST-Requests.
    #
    # This is unlike the PHP-SDK, which may have multiple parameters and allows access via numbers
    #   $input = mta::getInput();
    #   $name = $input[0];
    #   $password = $input[1];
    # Rails has named parameters, so there's no explicit support for them numbers.
    #
    # callRemote for MTA should always call files ending with .mta, for example:
    # * /auth => /auth.mta
    #
    # This will call the related JSON-Methods, i.e.
    #   respond_to do |format|
    #     format.html { ... } # certainly not this
    #     format.json { render :json => @object } # this gets called!
    #   end
    #
    # There is no support for elements and/or resources (yet?).
    def call env
      path = env[PATH_INFO]
      if path.end_with?('.mta') and (body = env[BODY].read).length != 0 and env[METHOD] == POST
        # replace ".mta" with ".json"
        env[PATH_INFO] = path[0..-5] + '.json'

        json = JSON.parse body
        raise Exception, "Number of JSON elements > 2: actual #{json.size}" if json.size > 2

        # optional options!
        update_options env, json[1].with_indifferent_access if json.size >= 2

        verify_request_method env

        # any parameters given? otherwise we don't really care for any params
        update_params env, json[0] if json.size >= 1 and json[0] != 0 # 0 is nil in terms of callRemote. JSON has 'null' though!

        # add some CSRF info... maybe.
        add_csrf_info env

        # call the other middlewares
        status, headers, response = @app.call(env)

        # alter only successful status codes to be more mta-ish
        if (200..299).include?(status)
          # mta /can/ handle multiple parameters as response.
          # We do not want and/or need this, but merely wrap the response body in square brackets as to return a single element
          # If render :json => @obj is used in the controller, this should make exactly @obj available in MTA.
          response = to_response(response, headers)

          # overwrite the length if already set
          if headers['Content-Length']
            headers['Content-Length'] = response.length
          end
        end

        return [status, headers, response]
      else
        # normal call, nevermind that whole mta business
        @app.call(env)
      end
    end

    private
      # update all of the parameter-related values in the current request's environment
      def update_params env, json
        env[FORM_HASH] = json
        env[BODY] = env[FORM_INPUT] = StringIO.new(Rack::Utils.build_query(json))
      end

      # make sure the request came from a whitelisted ip, or uses a publically accessible request method
      def verify_request_method env
        allowed = ALLOWED_METHODS
        allowed |= ALLOWED_METHODS_PRIVATE if whitelisted?(env)
        if !allowed.include?(env[METHOD])
          raise "Request method #{env[METHOD]} not allowed"
        end
      end

      # updates the options
      def update_options env, options
        if options[:method] and (ALLOWED_METHODS | ALLOWED_METHODS_PRIVATE).include?(options[:method])
          # (possibly) TODO - pass parameters for GET instead of POST in update_params then?
          # see https://github.com/rack/rack/blob/master/lib/rack/request.rb -> def GET
          env[METHOD] = options[:method]
        end
      end

      # adds csrf info to non-GET requests of whitelisted IPs
      def add_csrf_info env
        env[CSRF_TOKEN] = env[SESSION][:_csrf_token] = SecureRandom.base64(32).to_s if env[METHOD] != 'GET' and whitelisted?(env)
      end

      # TODO might need to revise this behing proxies
      def whitelisted? env
        Railtie.config.mta_json.whitelist.include?(env[IP])
      end

      # returns the response body: old response body + headers as a JSON array
      def to_response response, headers
        body = ""
        response.each do |s|
          body << s.to_s
        end
        ["[#{body},#{headers.to_json.to_s}]"]
      end
    end
end
