# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../../lib", __FILE__))
require "bootboot"

require "minitest/autorun"
require "minitest/hell"
require "open3"
require "tempfile"

class BootbootTestCase < Minitest::Test
  parallelize_me!

  private

  def plugin
    branch = %x(git rev-parse --abbrev-ref HEAD).strip

    "plugin 'bootboot', git: '#{Bundler.root}', branch: '#{branch}'"
  end

  class BundleInstallError < StandardError; end

  def run_bundler_command(command, gemfile_path, env: {})
    output = nil
    Bundler.with_unbundled_env do
      output, status = Open3.capture2e({ 'BUNDLE_GEMFILE' => gemfile_path }.merge(env), command)

      raise BundleInstallError, "bundle install failed: #{output}" unless status.success?
    end
    output
  end

  def write_gemfile(content = nil)
    dir = Dir.mktmpdir
    file = Tempfile.new('Gemfile', dir).tap do |f|
      f.write(content || <<-EOM)
        source "https://rubygems.org"

        #{plugin}
        Plugin.send(:load_plugin, 'bootboot') if Plugin.installed?('bootboot')

        if ENV['DEPENDENCIES_NEXT']
          enable_dual_booting if Plugin.installed?('bootboot')
        end
      EOM
      f.rewind
    end

    run_bundler_command('bundle install', file.path)

    yield(file, dir)
  ensure
    FileUtils.remove_dir(dir, true)
  end

  def lockfile_path(gemfile)
    "#{gemfile.path}.lock"
  end

  def lockfile_next_path(gemfile)
    "#{gemfile.path}_next.lock"
  end
end
