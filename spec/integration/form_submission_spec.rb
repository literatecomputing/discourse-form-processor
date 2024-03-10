# frozen_string_literal: true

RSpec.describe "Form submission" do
  fab!(:pm_template_group) { Fabricate(:group) }
  fab!(:template_category) { Fabricate(:category) }
  fab!(:user) { Fabricate(:user) }
  fab!(:template_group) { Fabricate(:group) }
  fab!(:template_user) { Fabricate(:user, groups: [template_group]) }
  fab!(:pm_template_user) { Fabricate(:user, trust_level: 3) }
  let(:admin) { Fabricate(:admin) }
  let(:category) { Fabricate(:category) }
  let(:bad_category) { Fabricate(:category) }
  fab!(:tag) { Fabricate(:tag) }
  fab!(:template_topic) { Fabricate(:topic, category: template_category) }
  let(:topic_view) { TopicView.new(template_topic, template_user) }
  fab!(:pm_template_user) do
    Fabricate(:user, username: "pm_template_dude", groups: [template_group, pm_template_group])
  end
  fab!(:template_pm) { Fabricate(:private_message_topic, tags: [tag], user: pm_template_user) }
  fab!(:bogus_template_topic) { Fabricate(:topic, category: template_category) }
  raw_template = <<~RAW
    Name: <%= name %>
    Email: <%= email %>
    Textarea message: <%= message %>
  RAW

  def expect_response_to_be_successful
    expect(response.status).to eq(200)
    expect(response.body).to include("OK")
  end

  def expect_response_to_be_successful_redirect
    expect(response.status).to eq(302)
    expect(response.body).to include("You are being")
  end
  def expect_response_not_to_be_successful
    expect(response.status).to eq(403)
    expect(response.body).to include("FAILED")
  end
  def expect_response_to_be_successful_debug
    expect(response.status).to eq(200)
    expect(response.body).to include("DEBUG MODE!")
    expect(response.body).to include("We are debugging this form.")
  end

  def expect_topic_to_be_created(pm_user)
    t = Topic.last
    expect(t.tags.pluck(:name)).to include(tag.name)
    expect(t.form_data["pm_user"]).to eq(pm_user)
    p = Post.find_by(topic_id: t.id, post_number: 1)
    expect(p.raw).to include("mailto:")
  end

  fab!(:template_post) do
    Fabricate(:post, topic: template_topic, user: template_user, raw: raw_template)
  end
  fab!(:pm_template_post) do
    Fabricate(:post, topic: template_pm, user: pm_template_user, raw: raw_template)
  end
  fab!(:bogus_template_post) do
    Fabricate(:post, topic: bogus_template_topic, user: user, raw: raw_template)
  end
  before do
    SiteSetting.form_processor_allowed_groups = template_group.id
    SiteSetting.form_processor_allowed_tags = tag.name
    SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
    SiteSetting.form_processor_enabled = true
    SiteSetting.form_processor_allowed_groups = template_group.id.to_s
    SiteSetting.form_processor_allowed_categories = template_category.id.to_s
    SiteSetting.form_processor_allowed_referrer = ""
    SiteSetting.form_processor_submission_tag = tag.name
    pm_template_group.add(pm_template_user)
  end

  describe "form post" do
    it "allows a member of the template group to submit a form" do
      puts "---------------------> doing g s a f"
      referer_url = "https://mysite.com/contact-form"
      template_user.allowed_referrers = referer_url
      post "/forms/submit/#{template_topic.id}",
           headers: {
             "HTTP_REFERER" => referer_url,
           },
           params: {
             success_url: "https://somewhere.com/success",
             pm_user: template_user.username,
             hostname: "discourse.person.com",
             name: "Pat Person",
             email: "pat@person.com",
             message:
               "We need help with an important thing.\r\n\r\nWe either have $50 or $50, 000; Not sure now.",
             controller: "discourse_forms/forms",
             action: "create",
           }
      expect_response_to_be_successful_redirect
      expect_topic_to_be_created(template_user.username)
      #expect_web_hook_event_name_to_be("chat_message_edited")
      # expect_web_hook_event_category_to_be(category)
    end


  describe "form post" do
    it "allows a member of the template group to submit a form with missing data" do
      puts "---------------------> doing missing"
      referer_url = "https://mysite.com/contact-form"
      template_user.allowed_referrers = referer_url
      post "/forms/submit/#{template_topic.id}",
           headers: {
             "HTTP_REFERER" => referer_url,
           },
           params: {
             success_url: "https://somewhere.com/success",
             pm_user: template_user.username,
             hostname: "discourse.person.com",
             name: "Pat Person",
             email: "pat@person.com",
             message:"",
             controller: "discourse_forms/forms",
             action: "create",
           }
      expect_response_to_be_successful_redirect
      expect_topic_to_be_created(template_user.username)
      #expect_web_hook_event_name_to_be("chat_message_edited")
      # expect_web_hook_event_category_to_be(category)
    end    
  end

  describe "form post" do
    it "allows a member of the template group to submit a form with an empty field" do
      puts "---------------------> doing empty"
      referer_url = "https://mysite.com/contact-form"
      template_user.allowed_referrers = referer_url
      post "/forms/submit/#{template_topic.id}",
           headers: {
             "HTTP_REFERER" => referer_url,
           },
           params: {
             success_url: "https://somewhere.com/success",
             pm_user: template_user.username,
             hostname: "discourse.person.com",
             name: "",
             email: "pat@person.com",
             message: "",
             controller: "discourse_forms/forms",
             action: "create",
           }
      expect_response_to_be_successful_redirect
      expect_topic_to_be_created(template_user.username)
      #expect_web_hook_event_name_to_be("chat_message_edited")
      # expect_web_hook_event_category_to_be(category)
    end 
  end
    
  it "allows a member of the template group to submit a form in debug mode" do
      referer_url = "https://mysite.com/contact-form"
      template_user.allowed_referrers = referer_url
      post "/forms/submit/#{template_topic.id}",
           headers: {
             "HTTP_REFERER" => referer_url,
           },
           params: {
             success_url: "https://somewhere.com/success",
             pm_user: template_user.username,
             hostname: "discourse.person.com",
             name: "Pat Person",
             email: "pat@person.com",
             debug_mode: "True",
             message: "We are debugging this form.",
             controller: "discourse_forms/forms",
             action: "create",
           }
      expect_response_to_be_successful_debug
    end

    it "allows a member of the template group submit a form in a PM" do
      referer_url = "https://mysite.com/contact-form"
      pm_template_user.allowed_referrers = referer_url
      post "/forms/submit/#{template_pm.id}",
           headers: {
             "HTTP_REFERER" => referer_url,
           },
           params: {
             success_url: "https://somewhere.com/success",
             pm_user: pm_template_user.username,
             hostname: "discourse.person.com",
             name: "Pat Person",
             email: "pat@person.com",
             message:
               "We need help with an important thing.\r\n\r\nWe either have $50 or $50, 000; Not sure now.",
             controller: "discourse_forms/forms",
             action: "create",
           }
      expect_response_to_be_successful_redirect
      expect_topic_to_be_created(pm_template_user.username)
      #expect_web_hook_event_name_to_be("chat_message_edited")
      # expect_web_hook_event_category_to_be(category)
    end

    it "denies a form submission in a PM when not a member of the template group" do
      referer_url = "https://mysite.com/contact-form"
      pm_template_user.allowed_referrers = referer_url
      pm_template_group.remove(pm_template_user)
      post "/forms/submit/#{template_pm.id}",
           headers: {
             "HTTP_REFERER" => referer_url,
           },
           params: {
             success_url: "https://somewhere.com/success",
             pm_user: pm_template_user.username,
             hostname: "discourse.person.com",
             name: "Pat Person",
             email: "pat@person.com",
             message:
               "We need help with an important thing.\r\n\r\nWe either have $50 or $50, 000; Not sure now.",
             controller: "discourse_forms/forms",
             action: "create",
           }
      expect_response_not_to_be_successful
    end

    it "denies a form submission in a PM when pm is missing tag" do
      referer_url = "https://mysite.com/contact-form"
      pm_template_user.allowed_referrers = referer_url
      pm_template_group.remove(pm_template_user)
      TopicTag.where(topic_id: template_pm.id).delete_all

      post "/forms/submit/#{template_pm.id}",
           headers: {
             "HTTP_REFERER" => referer_url,
           },
           params: {
             success_url: "https://somewhere.com/success",
             pm_user: pm_template_user.username,
             hostname: "discourse.person.com",
             name: "Pat Person",
             email: "pat@person.com",
             message:
               "We need help with an important thing.\r\n\r\nWe either have $50 or $50, 000; Not sure now.",
             controller: "discourse_forms/forms",
             action: "create",
           }
      expect_response_not_to_be_successful
    end

    it "denies a member of the template group submit form from wrong category" do
      referer_url = "https://mysite.com/contact-form"
      template_topic.update(category: bad_category)
      template_user.allowed_referrers = referer_url
      post "/forms/submit/#{template_topic.id}",
           headers: {
             "HTTP_REFERER" => referer_url,
           },
           params: {
             success_url: "https://somewhere.com/success",
             pm_user: template_user.username,
             hostname: "discourse.person.com",
             name: "Pat Person",
             email: "pat@person.com",
             message:
               "We need help with an important thing.\r\n\r\nWe either have $50 or $50, 000; Not sure now.",
             controller: "discourse_forms/forms",
             action: "create",
           }
      expect_response_not_to_be_successful
      #expect_web_hook_event_name_to_be("chat_message_edited")
      # expect_web_hook_event_category_to_be(category)
    end

    it "denies a form submission if not in group" do
      referer_url = "https://mysite.com/contact-form"
      template_user.allowed_referrers = referer_url
      post "/forms/submit/#{template_topic.id}",
           headers: {
             "HTTP_REFERER" => referer_url,
           },
           params: {
             success_url: "https://somewhere.com/success",
             pm_user: user.username,
             hostname: "discourse.person.com",
             name: "Pat Person",
             email: "pat@person.com",
             message:
               "We need help with an important thing.\r\n\r\nWe either have $50 or $50, 000; Not sure now.",
             controller: "discourse_forms/forms",
             action: "create",
             id: template_topic.id,
           }
      expect_response_not_to_be_successful
      #expect_web_hook_event_name_to_be("chat_message_edited")
      # expect_web_hook_event_category_to_be(category)
    end
  end
end
