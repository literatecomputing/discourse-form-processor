# frozen_string_literal: true

describe TopicViewSerializer do
  let(:user) { Fabricate(:user) }
  let(:admin) { Fabricate(:admin) }
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
  let(:form_result_pm) do
    Fabricate(
      :private_message_topic,
      topic_allowed_users: [
        Fabricate.build(:topic_allowed_user, user: admin),
        Fabricate.build(:topic_allowed_user, user: user),
      ],
      custom_fields: {
        "form_data" => {
          pm_user: "#{user.username}",
          name: "#{user.name}",
          email: "#{user.email}",
          hostname: "forum.sfdasdfasdf.com",
          message: "this is a message",
          controller: "discourse_forms/forms",
          action: "create",
          id: "#{template_topic.id}",
        }.to_json,
      },
    )
  end

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
      json = TopicViewSerializer.new(topic_view, scope: template_guardian, root: false).as_json
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
      post = Fabricate(:post, topic: not_template_topic, user: template_user)
      post.update!(raw: raw_template)
      json =
        TopicViewSerializer.new(
          not_template_topic_view,
          scope: template_guardian,
          root: false,
        ).as_json
      expect(json[:form_fields]).to eq(nil)
    end

    it "returns form_fields when pm has allowed tag" do
      SiteSetting.form_processor_allowed_groups = template_group.id
      SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
      SiteSetting.form_processor_enabled = true
      SiteSetting.form_processor_allowed_tags = tag.name
      post = Fabricate(:post, topic: template_pm, user: template_user)
      post.update!(raw: raw_template)
      json = TopicViewSerializer.new(topic_view, scope: template_guardian, root: false).as_json
      expect(json[:form_fields]).to eq(nil)
    end

    it "does not return form_fields when not in an allowed category even with a tag" do
      SiteSetting.form_processor_allowed_groups = template_group.id
      SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
      SiteSetting.form_processor_allowed_tags = tag.name
      SiteSetting.form_processor_enabled = true
      post = Fabricate(:post, topic: not_template_topic, user: template_user)
      post.update!(raw: raw_template)
      json =
        TopicViewSerializer.new(
          not_template_topic_view,
          scope: template_guardian,
          root: false,
        ).as_json
      expect(json[:form_fields]).to eq(nil)
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
  end
end
