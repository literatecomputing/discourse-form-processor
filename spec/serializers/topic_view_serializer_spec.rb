# frozen_string_literal: true

require "rails_helper"

describe TopicViewSerializer do
  let(:user) { Fabricate(:user) }
  let(:template_group) { Fabricate(:group) }
  let(:pm_template_group) { Fabricate(:group) }
  let(:template_user) { Fabricate(:user, groups: [template_group]) }
  let(:pm_template_user) { Fabricate(:user, groups: [pm_template_group]) }
  let(:template_category) { Fabricate(:category) }
  let(:another_category) { Fabricate(:category) }
  let(:tag) { Fabricate(:tag) }
  let(:template_topic) { Fabricate(:topic, category: template_category) }
  let(:topic_view) { TopicView.new(template_topic, template_user) }
  let(:template_pm) { Fabricate(:private_message_topic, tags: [tag]) }

  private_message_topic
  let(:form_result_pm_view) { TopicView.new(form_result_pm, user) }
  let(:not_template_topic) { Fabricate(:topic) }
  let(:not_template_topic_view) { TopicView.new(not_template_topic, template_user) }
  let(:template_guardian) { Guardian.new(template_user) }
  let(:guardian) { Guardian.new(user) }
  fab!(:tag)
  raw_template = <<~RAW
    Name: <%= name %>
    Email: <%= email %>
    Textarea message: <%= message %>
    Fruit they love: <%= fruits %>
  RAW

  describe "form_fields" do
    it "returns nil when templates disabled" do
      SiteSetting.form_processor_allowed_groups = template_group.id
      SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
      SiteSetting.form_processor_enabled = false
      SiteSetting.form_processor_allowed_categories = template_category.id.to_s
      post = Fabricate(:post, topic: template_topic, user: template_user)
      post.update!(raw: raw_template)
      json = TopicViewSerializer.new(topic_view, scope: template_guardian, root: false).as_json
      puts "Here's the json! #{json}"
      expect(json[:form_fields]).to eq(nil)
      expect(json[:form_data]).to eq(nil)
    end

    it "returns form_fields when templates enabled and in an allowed category for logged in user" do
      SiteSetting.form_processor_allowed_groups = template_group.id
      SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
      SiteSetting.form_processor_enabled = true
      SiteSetting.form_processor_allowed_categories = template_category.id.to_s
      post = Fabricate(:post, topic: template_topic, user: template_user)
      post.update!(raw: raw_template)
      puts "made a reqest?"
      json = TopicViewSerializer.new(topic_view, scope: template_guardian, root: false).as_json
      puts "Here's the json! #{json}"
      expect(json[:form_fields]).to include(:name)
      expect(json[:form_fields]).to include(:email)
      expect(json[:form_fields]).to include(:message)
      expect(json[:form_fields]).to include(:fruits)
    end

    it "does not return form_fields when not in an allowed category" do
      SiteSetting.form_processor_allowed_groups = template_group.id
      SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
      SiteSetting.form_processor_enabled = true
      SiteSetting.form_processor_allowed_categories = template_category.id.to_s
      puts "did thesesesese settings"
      post = Fabricate(:post, topic: not_template_topic, user: template_user)
      puts "did the post -- #{raw_template}"
      post.update!(raw: raw_template)
      puts "did the not allowed update"
      json =
        TopicViewSerializer.new(
          not_template_topic_view,
          scope: template_guardian,
          root: false,
        ).as_json
      puts "Here's the json! #{json}"
      expect(json[:form_fields]).to eq(nil)
    end

    it "returns form_fields when pm has allowed tag" do
      SiteSetting.form_processor_allowed_groups = template_group.id
      SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
      SiteSetting.form_processor_enabled = true
      SiteSetting.form_processor_allowed_tags = tag.name
      post = Fabricate(:post, topic: template_pm, user: template_user)
      post.update!(raw: raw_template)
      puts "did the --------update"
      json = TopicViewSerializer.new(topic_view, scope: template_guardian, root: false).as_json
      puts "Here's the json! #{json}"
      expect(json[:form_fields]).to eq(nil)
    end

    it "does not return form_fields when not in an allowed category even with a tag" do
      SiteSetting.form_processor_allowed_groups = template_group.id
      SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
      SiteSetting.form_processor_allowed_tags = tag.name
      SiteSetting.form_processor_enabled = true
      puts "did the settings"
      post = Fabricate(:post, topic: not_template_topic, user: template_user)
      puts "did the post -- #{raw_template}"
      post.update!(raw: raw_template)
      puts "did the update"
      json =
        TopicViewSerializer.new(
          not_template_topic_view,
          scope: template_guardian,
          root: false,
        ).as_json
      puts "Here's the json! #{json}"
      expect(json[:form_fields]).to eq(nil)
    end

    it "returns custom field with form submission contents" do
      form_result_pm = Fabricate(:private_message_topic)
      form_result_pm.update(archetype: "private_message")
      form_result_pm.custom_fields["form_data"] = {
        pm_user: "user.username",
        name: "user.name",
        email: "jay@pfaffman.com",
        hostname: "sfdasdfasdf",
        message: "this is a message",
        controller: "discourse_forms/forms",
        action: "create",
        id: "#{template_topic.id}",
      },
      json =
        TopicViewSerializer.new(
          not_template_topic_view,
          scope: Guardian.new(template_user),
          root: false,
        ).as_json
      expect(json[:form_data]).to include("pm_user")
    end

    #   it "returns false when topic not in category" do
    #     SiteSetting.voting_enabled = true

    #     json = TopicViewSerializer.new(topic_view, scope: guardian, root: false).as_json

    #     expect(json[:can_vote]).to eq(false)
    #   end

    #   it "returns false when voting disabled and topic not in category" do
    #     json = TopicViewSerializer.new(topic_view, scope: guardian, root: false).as_json

    #     expect(json[:can_vote]).to eq(false)
    #   end

    #   it "returns true when voting enabled and topic in category" do
    #     SiteSetting.voting_enabled = true
    #     DiscourseTopicVoting::CategorySetting.create!(category: category)

    #     json = TopicViewSerializer.new(topic_view, scope: guardian, root: false).as_json

    #     expect(json[:can_vote]).to eq(true)
    #   end
    # end

    # describe "vote_count" do
    #   it "returns the topic vote counts" do
    #     Fabricate(:topic_voting_vote_count, topic: topic, votes_count: 3)
    #     json = TopicViewSerializer.new(topic_view, scope: guardian, root: false).as_json

    #     expect(json[:vote_count]).to eq(3)
    #   end
    # end

    # describe "user_voted" do
    #   it "returns true if the user has voted on the topic" do
    #     json = TopicViewSerializer.new(topic_view, scope: guardian, root: false).as_json

    #     expect(json[:user_voted]).to eq(false)

    #     Fabricate(:topic_voting_votes, topic: topic, user: user)
    #     json = TopicViewSerializer.new(topic_view, scope: guardian, root: false).as_json

    #     expect(json[:user_voted]).to eq(false)
    #   end
  end
end
