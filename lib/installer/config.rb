require 'installer/helpers'
require 'versionomy'
require 'yaml'

module Installer
  class Config
    include Installer::Helpers

    attr_reader :default_dir, :default_file, :file_template
    attr_accessor :file_path

    def initialize file_path=nil
      @default_dir = ENV['HOME'] + '/.openshift'
      @default_file = '/oo-install-cfg.yml'
      @file_template = gem_root_dir + '/conf/oo-install-cfg.yml.example'
      if file_path.nil?
        self.file_path = default_dir + default_file
        unless file_check(self.file_path)
          install_default
        end
      else
        self.file_path = init_file_path
      end
    end

    def settings
      @settings ||= YAML.load_file(self.file_path)
    end

    def is_valid?
      unless settings
        puts "Could not parse settings from #{self.file_path}."
        return false
      end
      unless Versionomy.parse(settings['Version']) <= Versionomy.parse(Installer::VERSION)
        puts "Config file is for a newer version of oo-installer."
        return false
      end
      true
    end

    def save_to_disk!
      File.open(file_path, 'w') do |file|
        file.write settings.to_yaml
      end
    end

    def get_deployment
      Installer::Deployment.new(self, (settings.has_key?('Deployment') ? settings['Deployment'] : {}))
    end

    def get_subscription
      Installer::Subscription.new(self, (settings.has_key?('Subscription') ? settings['Subscription'] : {}))
    end

    def set_deployment deployment
      settings['Deployment'] = deployment.to_hash
    end

    def set_subscription subscription
      settings['Subscription'] = subscription.to_hash
    end

    def get_workflow_cfg id
      (settings.has_key?('Workflows') and settings['Workflows'].has_key?(id)) ? settings['Workflows'][id] : {}
    end

    def set_workflow_cfg id, workflow_cfg
      if not settings.has_key?('Workflows')
        settings['Workflows'] = {}
      end
      settings['Workflows'][id] = workflow_cfg
    end

    private
    def install_default
      unless Dir.exists?(default_dir)
        Dir.mkdir(default_dir)
      end
      FileUtils.cp(file_template, self.file_path)
    end
  end
end

