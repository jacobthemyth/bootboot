# frozen_string_literal: true

require "test_helper"
require "tempfile"

class DefinitionHelpersTest < BootbootTestCase
  include Bootboot::DefinitionHelpers

  def test_original_unlock_given_true_returns_true
    write_gemfile do |gemfile|
      definition = Bundler::Definition.build(gemfile.path, lockfile_path(gemfile), true)
      assert_equal(true, original_unlock(definition))
    end
  end

  def test_original_unlock_given_hash_returns_hash
    gemfile_contents = <<~GEMFILE
      source "https://rubygems.org"
      gem "rake"
    GEMFILE

    write_gemfile(gemfile_contents) do |gemfile|
      definition = Bundler::Definition.build(gemfile.path, lockfile_path(gemfile), gems: %w(rake))
      assert_equal({ gems: %w(rake) }, original_unlock(definition))
    end
  end

  # Definition#initialize deletes :bundler from unlock, so we need to test we
  # get it back
  def test_original_unlock_given_hash_with_bundler_returns_hash_with_bundler
    write_gemfile do |gemfile|
      definition = Bundler::Definition.build(gemfile.path, lockfile_path(gemfile), bundler: "> 0.a")
      assert_equal({ bundler: "> 0.a" }, original_unlock(definition))
    end
  end

  # Definition.build accepts nil and false but will pass an empty hash to
  # Definition#initialize (which does not allow nil for unlock and doesn't in
  # practice accept false). There is no way to distinguish whether these or an
  # empty hash was given, but they have no functional difference.

  def test_original_unlock_given_nil_returns_empty_hash
    write_gemfile do |gemfile|
      definition = Bundler::Definition.build(gemfile.path, lockfile_path(gemfile), nil)
      assert_equal({}, original_unlock(definition))
    end
  end

  def test_original_unlock_given_false_returns_empty_hash
    write_gemfile do |gemfile|
      definition = Bundler::Definition.build(gemfile.path, lockfile_path(gemfile), false)
      assert_equal({}, original_unlock(definition))
    end
  end

  # TODO: @unlocking ||= @unlock[:ruby] ||= (!@locked_ruby_version ^ !@ruby_version)

  # Bundler will modify @unlocking if there's an updated ruby version, even if
  # unlock doesn't contain :ruby
  # def test_original_unlock_given_true_and_updated_ruby_version_returns_true
  # end
end
