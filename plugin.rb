# frozen_string_literal: true

# name: discourse-form-processor
# about: Process arbitrary forms
# meta_topic_id: TODO
# version: 0.0.1
# authors: pfaffman
# url: https://github.com/literatecomputing/discourse-form-processor
# required_version: 2.7.0

enabled_site_setting :form_processor_enabled

module ::DiscourseForms
  PLUGIN_NAME = "discourse-form-processor"
end

require_relative "lib/form_module/engine"

# Discourse::Application.routes.append do
#   post "/forms/submit/:id" => "forms#create"
# end

after_initialize do
  # Code which should run after Rails has finished booting
end
