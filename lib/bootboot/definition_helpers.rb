# frozen_string_literal: true

module Bootboot
  module DefinitionHelpers
    # Bundler doesn't directly save the value of unlock passed to
    # Definition#initialize to @unlock, but rather stores a hash in @unlock
    # even if the value passed to Definition#ininialize is true, false, or nil.
    # This method infers the original unlock argument. This is tightly coupled
    # to the internals of Bundler since it's not guaranteed that
    # @unlocking_bundler will always correspond to the type of unlock
    def original_unlock(definition)
      unlock_hash = definition.instance_variable_get(:@unlock).dup
      unlock_hash.delete_if { |_k, v| !v || Array(v).empty? }

      unlocking_bundler = definition.instance_variable_get(:@unlocking_bundler)
      unlock_hash[:bundler] = unlocking_bundler if unlocking_bundler

      unlocking = definition.instance_variable_get(:@unlocking)

      if unlocking == true && unlock_hash == {}
        true
      else
        unlock_hash
      end
    end

    extend self
  end
end
