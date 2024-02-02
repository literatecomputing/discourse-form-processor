# frozen_string_literal: true

module ::FormsModule
  class Form < ActiveRecord::Base
    def self.create(args)
      puts "Forms model Create! Got #{args}"
    end
  end
end
