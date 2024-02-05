# frozen_string_literal: true

module DiscourseForms
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseForms
    config.autoload_paths << File.join(config.root, "lib")
  end
end
