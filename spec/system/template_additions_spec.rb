
RSpec.describe "Topic page form elements", type: :system, mobile: true do
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

  before do
    sign_in(user)
  end

  context "template form" do
    raw_template = <<~RAW
      Name: <%= name %>
      Email: <%= email %>
      Textarea message: <%= message %>
      Fruit they love: <%= fruits %>
    RAW
  let(:not_template_topic) { Fabricate(:topic) }
  let(:not_template_topic_view) { TopicView.new(not_template_topic, template_user) }
  let(:template_guardian) { Guardian.new(template_user) }
  let(:guardian) { Guardian.new(user) }
  fab!(:tag)


    it "shows form if there are form_fieds" do  
      SiteSetting.form_processor_allowed_groups = template_group.id
      SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
      SiteSetting.form_processor_enabled = true
      SiteSetting.form_processor_allowed_categories = template_category.id.to_s
      post = Fabricate(:post, topic: template_topic, user: template_user)
      post.update!(raw: raw_template)

      visit("/t/-/#{template_topic.id}")
      expect(page).to have_css(".html-example")
      expect(page).to have_no_css(".form-html")
      find('.html-example > details').click
      expect(page).to have_css(".form-html")
    end

    it "shows no form if not in form category" do  
      SiteSetting.form_processor_allowed_groups = template_group.id
      SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
      SiteSetting.form_processor_enabled = true
      SiteSetting.form_processor_allowed_categories = ""
      post = Fabricate(:post, topic: template_topic, user: template_user)
      post.update!(raw: raw_template)
      

      visit("/t/-/#{template_topic.id}")
      expect(page).to have_no_css(".html-example")
      expect(page).to have_no_css(".form-html")
    end

    it "shows no form if there are no form_fieds" do  
      SiteSetting.form_processor_allowed_groups = template_group.id
      SiteSetting.form_processor_pm_allowed_groups = pm_template_group.id.to_s
      SiteSetting.form_processor_enabled = true
      SiteSetting.form_processor_allowed_categories = template_category.id.to_s
      post = Fabricate(:post, topic: template_topic, user: template_user)
      
      visit("/t/-/#{template_topic.id}")
      expect(page).to have_no_css(".html-example")
      expect(page).to have_no_css(".form-html")
    end
  end

end
