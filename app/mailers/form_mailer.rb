# frozen_string_literal: true

class FormMailer < ActionMailer::Base
  include Email::BuildEmailHelper

  def send_form(to_address, opts = {})
    puts "mailer got opts #{opts}--reply: #{opts[:email]}"
    build_email(
      to_address,
      template: "form_mailer",
      custom_headers: "reply-to: #{opts[:email]}",
      **opts,
    )
  end
end
