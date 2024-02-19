# frozen_string_literal: true

# name: discourse-form-processor
# about: Process arbitrary forms
# meta_topic_id: TODO
# version: 0.0.1
# authors: pfaffman
# url: https://github.com/literatecomputing/discourse-form-processor
# required_version: 2.7.0

enabled_site_setting :form_processor_enabled
require "current_user"

module ::DiscourseForms
  PLUGIN_NAME = "discourse-form-processor"
  FORM_TITLE_HEADER = "NOTIFICATION_MESSAGE_TITLE"
  ALLOWED_REFERRER_CUSTOM_FIELD = "allowed_referrers"
  SUBMITTED_FORM_CUSTOM_FIELD = "submitted_form"
end

require_relative "lib/form_module/engine"
# register_svg_icon "fa-solid fa-message" if respond_to?(:register_svg_icon)

# Discourse::Application.routes.append do
#   post "/forms/submit/:id" => "forms#create"
# end
DiscoursePluginRegistry.serialized_current_user_fields << DiscourseForms::ALLOWED_REFERRER_CUSTOM_FIELD

after_initialize do
  # Code which should run after Rails has finished booting
  # TODO: move allowed referrers to a user custom field
  register_editable_user_custom_field(DiscourseForms::ALLOWED_REFERRER_CUSTOM_FIELD)
  register_user_custom_field_type(DiscourseForms::ALLOWED_REFERRER_CUSTOM_FIELD, :text)
  register_user_custom_field_type(DiscourseForms::SUBMITTED_FORM_CUSTOM_FIELD, :json)
  add_to_class(:user, :allowed_referrers) { self.custom_fields["allowed_referrers"] }
  add_to_class(:user, :allowed_referrers=) do |referrers|
    self.custom_fields["allowed_referrers"] = referrers
    self.save
  end

  add_to_class(:user, :allowed_referrer?) do |referrer|
    SiteSetting.form_processor_allowed_referrer.include?(referrer) ||
      self.allowed_referrers.include?(referrer)
  end
  add_to_class(:user, :forms_processed) do
    UserCustomField.where(user_id: self.id).where("name like 'submitted_form%'").count
  end
  add_to_class(:user, :forms_processed_this_month) do
    UserCustomField
      .where(user_id: self.id)
      .where("name like 'submitted_form%'")
      .where(created_at: Date.today.all_month)
      .count
  end
  add_to_class(:user, :forms_array) do
    UserCustomField
      .where(user_id: self.id)
      .where("name like 'submitted_form%'")
      .pluck(:value)
      .map { |item| JSON.parse(item) }
  end
  add_to_class(:user, :forms_this_month_array) do
    UserCustomField
      .where(user_id: self.id)
      .where("name like 'submitted_form%'")
      .where(created_at: Date.today.all_month)
      .pluck(:value)
      .map { |item| JSON.parse(item) }
  end
  add_to_class(:guardian, :allowed_referrer?) do |referrer|
    SiteSetting.form_processor_allowed_referrer.include?(referrer) ||
      (current_user.allowed_referrer?(referrer))
  end
  add_to_class(:guardian, :is_template_topic?) do |t|
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

  add_to_serializer(:current_user, :form_allowed_referrers) do
    puts "Getting stuff"
    puts "#{object.username}"
    puts "#{object.allowed_referrers}"

    object.allowed_referrers
  end
  add_to_serializer(:topic_view, :is_template_topic) do
    guardian = Guardian.new(scope.current_user)
    guardian.is_template_topic?(object.topic)
  end
  add_to_serializer(:topic_view, :form_fields) do
    guardian = Guardian.new(scope.current_user)
    if guardian.is_template_topic?(object.topic)
      p = Post.find_by(topic_id: object.topic.id, post_number: 1)
      title_template = object.topic.title
      title_match = p.raw.match(/^FORM_TITLE:\s?(.*)/)
      title_template = title_match[1] if title_match
      template = title_template + " " + p.raw
      template.scan(/<%= (.*?) %>/).flatten.uniq.map(&:to_sym)
    end
  end
  add_model_callback(Topic, :after_create) do
    # if it's a PM and has a form attached, create a user_custom_field
    puts "creating a topic. adding a thing"
    t = self
    if t.archetype == "private_message"
      if t.custom_fields["form_data"]
        puts "GOT ata"
        form_data = JSON.parse(t.custom_fields["form_data"])
        username = form_data["pm_user"] if form_data
        u = User.find_by_username(username) if username
        if u
          puts "------>>>>>got user!!!! with #{form_data}"
          template_id = form_data["id"]
          puts "-------------------------->>> template #{template_id}"
          begin
            json_load = {
              user_id: u.id,
              topic_id: t.id,
              template_id: template_id,
              created_at: Time.now,
            }.to_json
            puts "going to save #{json_load}"
            u.custom_fields["#{DiscourseForms::SUBMITTED_FORM_CUSTOM_FIELD}_#{t.id}"] = json_load
            puts "---------------------------> going to save #{u.custom_fields}"
            u.save
          rescue => e
            puts "can't save usercustom fields because #{e}"
          end
        end
      end
    end
  end
  # add_to_serializer(:topic, :form_template) do
  #   object.custom_fields['']
  # end
end
