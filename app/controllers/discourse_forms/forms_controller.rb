# frozen_string_literal: true

module DiscourseForms
  class FormsController < ::ApplicationController
    skip_before_action :check_xhr, :preload_json, :verify_authenticity_token

    requires_plugin PLUGIN_NAME

    def index
      puts "doing a controller index"
      render json: { hello: "world" }
    end

    def show
      puts "--------------------->>>> doing a controller show"
      render json: { hello: "this is a show" }
    end

    def create
      deny_reason = ""
      puts "THIS IS CURRENT USER: #{current_user}"
      puts "Current user is nil" if current_user.nil?
      referrer = request.env["HTTP_REFERER"]
      puts "Referrer is #{referrer}"
      form_user = User.find_by_username(params[:pm_user])
      raise Discourse::InvalidAccess unless form_user
      tid = params["id"]
      t = Topic.find(tid)
      p = Post.find_by(post_number: 1, topic_id: tid)
      sender = User.find_by_username(SiteSetting.form_processor_pm_sender) || User.find(-1)
      user_guardian = Guardian.new(form_user)
      can_send = !form_user.nil?
      can_send &&= user_guardian.can_see?(t)
      can_send &&= user_guardian.can_send_private_message?(form_user)

      if !user_guardian.allowed_referrer?(referrer)
        puts "Cannot do it!!!"
        deny_reason += "#{referrer} not in #{SiteSetting.form_processor_allowed_referrer}"
        can_send = false
      end
      # is in group allowed to process forms?
      can_send &&= user_guardian.can_use_forms?(form_user)
      can_send &&= user_guardian.is_template_topic?(t)
      puts "Can send? #{can_send}"
      if can_send
        template = p.raw + " " + t.title
        allow_list = template.scan(/<%= (.*?) %>/).flatten.map(&:to_sym)
        allow_list = allow_list + %i[success_url failure_url pm_user id]
        puts "my allow: #{allow_list}"
        filtered = params.permit(allow_list)
        # add arrays to filtered list
        allow_list.each do |i|
          filtered = filtered.merge(params.permit(i.to_sym => [])) if params[i].is_a? Array
        end
        # filtered = filtered.merge(params.permit("hosting_service".to_sym => []))
        # .permit("hosting_service".to_sym => [])
        # .permit("favorite_pet".to_sym => [])

        puts "my filtered #{filtered}"
        email = params["email"]
        success_url = params["success_url"]
        failure_url = params["failure_url"]
        puts "Sending for user #{sender.id}. going to redirect to #{failure_url}" if failure_url

        begin
          title = ERB.new(t.title).result_with_hash(filtered)
          raw = ERB.new(p.raw).result_with_hash(filtered)
          puts "This is title: #{title}"
          puts "This is raw: #{raw}"
          puts "Calling create!!! from #{sender.username} to #{form_user.username}"
          new_post =
            PostCreator.create(
              sender,
              title: title,
              raw: raw,
              target_usernames: [form_user.username],
              archetype: Archetype.private_message,
              skip_validations: true,
              topic_opts: {
                custom_fields: {
                  form_data: params.to_json,
                },
              },
            )
        rescue => e
          puts "Failed to render title or raw: #{e}"
        end
      end
      return_text = "OK--#{new_post.id}"
      puts return_text = "THIS WAS NOT SENT: #{deny_reason}" unless can_send
      if !SiteSetting.form_procesor_debug_mode && params["success_url"]
        redirect_to params["success_url"]
      else
        render json: { text: "#{return_text}. #{params}" }
      end
    end
  end
end
