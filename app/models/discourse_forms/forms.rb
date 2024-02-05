# frozen_string_literal: true

module DiscourseForms
  class Form < ActiveRecord::Base
    def self.create(args)
      puts "Forms model Create! Got #{args}"
    end
  end
end
