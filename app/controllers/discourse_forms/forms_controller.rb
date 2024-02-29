# frozen_string_literal: true

module DiscourseForms
  class FormsController < ::ApplicationController
    skip_before_action :check_xhr, :preload_json, :verify_authenticity_token

    requires_plugin PLUGIN_NAME

    def index
      render json: { columns: current_user.forms_results_fields, data: current_user.forms_results }
    end

    def show
      render json: { hello: "this is a show" }
    end

    def create
      deny_reason = ""
      referrer = request.env["HTTP_REFERER"]
      form_user =
        User.find_by_username(params[:formhoster_user]) ||
          User.find_by_username(params[:pm_user]) || User.find(params[:formhoster_id])
      raise Discourse::InvalidAccess unless form_user
      tid = params["id"]
      t = Topic.find(tid)
      raise Discourse::InvalidAccess unless tid
      p = Post.find_by(post_number: 1, topic_id: tid)
      title_match = p.raw.match(Regexp.new("^#{FORM_TITLE_HEADER}:\s?(.*)"))
      title_template = title_match ? title_match[1] : t.title
      sender = User.find_by_username(SiteSetting.form_processor_pm_sender) || User.find(-1)
      user_guardian = Guardian.new(form_user)
      can_send = !form_user.nil?
      if !user_guardian.can_see?(t)
        can_send = false
        deny_reason = "#{form_user.username} cannot read topic #{tid}"
        return render json: failed_json.merge(errors: deny_reason), status: 403
      elsif (t.archetype == Archetype.private_message) &&
            !user_guardian.can_use_pm_forms?(form_user)
        can_send = false
        deny_reason = "PM Forms not allowed. Upgrade your plan."
        return render json: failed_json.merge(errors: deny_reason), status: 403
      elsif !user_guardian.allowed_referrer?(referrer)
        deny_reason += "#{referrer} not in #{form_user.allowed_referrers}"
        can_send = false
        return render json: failed_json.merge(errors: deny_reason), status: 403
      elsif !user_guardian.can_use_forms?(form_user)
        can_send = false
        deny_reason = "Not allowed to use forms. Has your subscription has expired?"
        return render json: failed_json.merge(errors: deny_reason), status: 403
      elsif !user_guardian.is_template_topic?(t)
        can_send = false
        deny_reason = "#{t.id} is not a form template"
        return render json: failed_json.merge(errors: deny_reason), status: 403
      elsif can_send
        template = title_template + " " + p.raw
        allow_list = template.scan(/<%= (.*?) %>/).flatten.map(&:to_sym)
        allow_list = allow_list + %i[success_url failure_url pm_user id debug_mode formhoster_id formhoster_user]
        filtered = params.permit(allow_list)
        # add arrays to filtered list
        allow_list.each do |i|
          filtered = filtered.merge(params.permit(i.to_sym => [])) if params[i].is_a? Array
        end
        email = params["email"] || form_user.email
        name = params["name"] # TODO: add name to the email address in the mailto:
        success_url = params["success_url"]
        failure_url = params["failure_url"]
        debug_mode = params["debug_mode"]
        begin
          title = ERB.new(title_template).result_with_hash(filtered)
          body_template = p.raw.gsub(Regexp.new("#{FORM_TITLE_HEADER}:.*"), "")
          raw = ERB.new(body_template).result_with_hash(filtered)
          reply_to_header =
            (
              if name
                "On #{Time.now} #{name} <#{email}> wrote: \n"
              else
                "On #{Time.now} #{email} wrote: \n"
              end
            )

          quoted_raw = reply_to_header + raw.gsub("\n", "\n>  ")

          mailto_link =
            "\n\n[Reply by email](mailto:#{email}?subject=#{CGI.escape(title)}&body=#{CGI.escape(quoted_raw)})"
          raw = email ? raw + mailto_link : raw

          if !debug_mode
            new_post =
              PostCreator.create(
                sender,
                title: title,
                raw: raw,
                target_usernames: [form_user.username],
                archetype: Archetype.private_message,
                # don't want to be stopped by watched word or post length validations
                skip_validations: true,
                tags: SiteSetting.form_processor_submission_tag.split("|"),
                topic_opts: {
                  custom_fields: {
                    form_data: params.to_json,
                  },
                },
              )
          end
        rescue => e
          Rails.logger.error("Failed to render title or raw: #{e}")
        end
      end
      # filtered = filtered.merge(params.permit("hosting_service".to_sym => []))
      # .permit("hosting_service".to_sym => [])
      # .permit("favorite_pet".to_sym => [])

      if debug_mode
        return_text = "DEBUG MODE! Form Accepted\n\n#{title}\n\n#{raw}\n\n#{params}"
      elsif new_post && can_send
        return_text = "OK"
        return_text += " #{params}" if SiteSetting.form_procesor_debug_mode
        Rails.logger.warn t = "THIS WAS NOT SENT: #{deny_reason}" unless can_send
      else
        return_text = "FAILURE"
      end
      if !debug_mode && params["success_url"]
        redirect_to params["success_url"], allow_other_host: true
      else
        render json: { status: "#{return_text}" }
      end
    end
  end
end
