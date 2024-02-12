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
  # TODO: move allowed referrers to a user custom field
  # register_editable_user_custom_field(:allowed_referrers)
  # add_to_class(:user, :allowed_referrers) { self.custom_fields['allowed_referrers'] }
  add_to_class(:guardian, :allowed_referrer?) do |referrer|
    SiteSetting.form_processor_allowed_referrer.include?(referrer)
  end
  add_to_serializer(:topic_view, :form_data) do
    begin
      if object.topic.custom_fields["form_data"]
        form_data = JSON.parse(object.topic.custom_fields["form_data"])
        form_data
      end
    rescue => e
      "Unexpected form data. #{e}"
    end
  end
  add_to_serializer(:topic_view, :form_fields) do
    p = Post.find_by(topic_id: object.topic.id, post_number: 1)
    title_template = object.topic.title
    title_match = p.raw.match(/^FORM_TITLE:\s?(.*)/)
    title_template = title_match[1] if title_match
    template = title_template + " " + p.raw
    template.scan(/<%= (.*?) %>/).flatten.uniq.map(&:to_sym)
  end
  add_to_serializer(:topic_view, :is_form_template) do
    ok = false
    t = object.topic
    if t.category_id
      ok ||=
        (
          SiteSetting
            .form_processor_allowed_categories
            .split("|")
            .map(&:to_i)
            .include?(t.category_id)
        )
    end
    ok ||= (t.tags.pluck(:name) & SiteSetting.form_processor_allowed_tags.split("|")).length > 0
    ok
  end
  # add_to_serializer(:topic, :form_template) do
  #   object.custom_fields['']
  # end
  add_to_class(:guardian, :is_template_topic?) do |t|
    puts "Guarding the topic! #{t.title}"
    ok = false
    if t.category_id
      ok ||=
        (
          SiteSetting
            .form_processor_allowed_categories
            .split("|")
            .map(&:to_i)
            .include?(t.category_id)
        )
    end
    ok ||= (t.tags.pluck(:name) & SiteSetting.form_processor_allowed_tags.split("|")).length > 0
    ok
  end
  add_to_class(:guardian, :can_use_forms?) do |form_user|
    (
      form_user.groups.pluck(:id) & SiteSetting.form_processor_allowed_groups.split("|").map(&:to_i)
    ).length > 0
  end
end
