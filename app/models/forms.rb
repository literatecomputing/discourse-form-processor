module ::FormsModule
  class Form < ActiveRecord::BasicObject
    def self.create(args)
      puts "Forms model Create! Got #{args}"
    end
  end
end
