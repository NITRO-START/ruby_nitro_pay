require 'colorize'
module NitroPay
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../../templates', __FILE__)
      
      desc 'It automatically create it initializer NitroPay rails app config'
      
      def copy_initializer
        template 'nitro_pay.rb', 'config/initializers/nitro_pay.rb'
        puts 'Check your config/initializers/nitro_pay.rb & read it comments'.colorize(:light_yellow)
      end
      
    end
  end
end