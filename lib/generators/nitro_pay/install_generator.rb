require 'colorize'
module NitroPay
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../../templates', __FILE__)
      
      desc 'It automatically create it initializer RentS rails app config'
      
      def copy_initializer
        template 'rents.rb', 'config/initializers/rents.rb'
        puts 'Check your config/initializers/rents.rb & read it comments'.colorize(:light_yellow)
      end
      
    end
  end
end