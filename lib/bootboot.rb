# frozen_string_literal: true

require "bootboot/version"
require "bootboot/bundler_patch"

module Bootboot
  autoload :Command,             'bootboot/command'
  autoload :GemfileNextAutoSync, 'bootboot/gemfile_next_auto_sync'
  autoload :Lockfile,            'bootboot/lockfile'

  class << self
    def env_next
      env_prefix + '_NEXT'
    end

    def env_previous
      env_prefix + '_PREVIOUS'
    end

    private

    def env_prefix
      Bundler.settings['bootboot_env_prefix'] || 'DEPENDENCIES'
    end
  end
end

Bootboot::GemfileNextAutoSync.new.setup
Bootboot::Command.new.setup
