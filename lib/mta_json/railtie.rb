module MtaJson
  class Railtie < Rails::Railtie
    config.mta_json = ActiveSupport::OrderedOptions.new

    # default whitelist includes only the local ip.
    config.mta_json.whitelist = %w(127.0.0.1)

    initializer "mta_json.configure" do |app|
      app.middleware.use MtaJson::Wrapper
    end
  end
end
