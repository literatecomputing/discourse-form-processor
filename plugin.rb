# frozen_string_literal: true

# name: discourse-form-processor
# about: Process arbitrary forms
# meta_topic_id: TODO
# version: 2026.11.11.04
# authors: pfaffman
# url: https://github.com/literatecomputing/discourse-form-processor
# required_version: 2.7.0

enabled_site_setting :form_processor_enabled
require "current_user"

module ::DiscourseForms
  PLUGIN_NAME = "discourse-form-processor"
  FORM_TITLE_HEADER = "NOTIFICATION_MESSAGE_TITLE"
  ALLOWED_REFERRER_CUSTOM_FIELD = "allowed_referrers"
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
  add_to_class(:user, :allowed_referrers) { self.custom_fields["allowed_referrers"] }
  add_to_class(:user, :allowed_referrers=) do |referrers|
    self.custom_fields["allowed_referrers"] = referrers
    self.save
  end

  add_to_class(:user, :allowed_referrer?) do |referrer|
    referrer.nil? || self.allowed_referrers && self.allowed_referrers.include?(referrer)
  end
  # Submissions are counted from the PMs they create (each has a form_data topic custom
  # field), not stored per-submission on the user: users are capped at 100 custom fields.
  add_to_class(:user, :form_submission_topics) do
    Topic
      .private_messages
      .joins(:topic_allowed_users)
      .where(topic_allowed_users: { user_id: self.id })
      .where(id: TopicCustomField.where(name: "form_data").select(:topic_id))
  end
  add_to_class(:user, :forms_processed) { form_submission_topics.count }
  add_to_serializer(:current_user, :forms_processed) { object.forms_processed }
  add_to_class(:user, :forms_processed_this_month) do
    form_submission_topics.where(created_at: Date.today.all_month).count
  end
  add_to_class(:user, :forms_results) do
    tq = TopicQuery.new(self).list_private_messages(self)
    tcf = TopicCustomField.where("topic_id in (?)", tq.topics.pluck(:id))
    Hash[tcf.pluck(:topic_id, :value).map { |(k, v)| [k, JSON.parse(v)] }]
  end
  add_to_class(:user, :forms_results_fields) { self.forms_results.values.flat_map(&:keys).uniq }
  add_to_serializer(:current_user, :forms_processed_this_month) do
    object.forms_processed_this_month
  end
  add_to_class(:user, :github_username) do
    if uac = UserAssociatedAccount.find_by(user_id: self.id, provider_name: "github")
      uac.info["nickname"]
    end
  end
  add_to_serializer(:current_user, :github_username) { object.github_username }

  add_to_class(:guardian, :allowed_referrer?) do |referrer|
    current_user.allowed_referrer?(referrer)
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
    num_groups =
      (
        form_user.groups.pluck(:id) &
          SiteSetting.form_processor_allowed_groups.split("|").map(&:to_i)
      ).length
    num_groups > 0
  end
  add_to_class(:guardian, :can_use_pm_forms?) do |form_user|
    num_groups =
      (
        form_user.groups.pluck(:id) &
          SiteSetting.form_processor_pm_allowed_groups.split("|").map(&:to_i)
      ).length
    num_groups > 0
  end
  add_to_class(:topic, :form_data) { JSON.parse(self.custom_fields["form_data"]) }
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

  add_to_serializer(:current_user, :form_allowed_referrers) { object.allowed_referrers }
  add_to_serializer(:topic_view, :is_template_topic) do
    guardian = Guardian.new(scope.current_user)
    guardian.is_template_topic?(object.topic)
  end
  add_to_serializer(:topic_view, :form_pm_tag) do
    SiteSetting.form_processor_allowed_tags.split("|").first
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
end
