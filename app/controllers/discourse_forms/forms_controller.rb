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
      # filtered = params.permit(:email, :name).transform_keys(&:to_sym)
      filtered = params.permit(:email, :name)
      fields = {}
      SiteSetting
        .form_processor_field_allowlist
        .split("|")
        .each { |field| fields[field.to_sym] = params[field] }
      fields[:form_data] = params.to_s.gsub(",", ",\n")
      puts "controller in a form! Things are really happening"
      puts "params: #{params}"
      puts "fields: #{fields}"
      puts "going to redirect to #{params["success_url"]}" if params["success_url"]
      form_data = params.to_s
      puts "paramstring: #{form_data}"
      puts "filtered: #{filtered}"
      #byebug
      #message = FormMailer.send_form(params['email'], {"email": "jay@pfaffman.com", "name": "Jay Pfaffman"}) # works
      # message = FormMailer.send_form(params['email'], email: "jay@pfaffman.com", name: "Jay Pfaffman" ) # works
      message = FormMailer.send_form(params["email"], **fields)
      # message = FormMailer.send_form(params['email'], filtered ) #broken
      Email::Sender.new(message, :test_message).send

      puts "Message! #{message.body}"
      if params["success_url"]
        redirect_to params["success_url"]
      else
        render json: { hello: "forms are great! I love #{params["name"]}. #{params}" }
      end
    end
  end
end
