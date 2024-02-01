# frozen_string_literal: true

module ::FormsModule
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace FormsModule
    config.autoload_paths << File.join(config.root, "lib")
  end
end
