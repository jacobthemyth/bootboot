# frozen_string_literal: true

module Bootboot
  class GemfileNextAutoSync < Bundler::Plugin::API
    def setup
      check_bundler_version
      opt_in
    end

    private

    def check_bundler_version
      self.class.hook("before-install-all") do
        next if Bundler::VERSION >= "1.17.0" || !GEMFILE_NEXT_LOCK.exist?

        Bundler.ui.warn(<<-EOM.gsub(/\s+/, " "))
          Bootboot can't automatically update the Gemfile_next.lock because you are running
          an older version of Bundler.

          Update Bundler to 1.17.0 to discard this warning.
        EOM
      end
    end

    def opt_in
      self.class.hook("after-install-all") do
        next if !GEMFILE_NEXT_LOCK.exist? ||
                ENV[Bootboot.env_next] ||
                ENV[Bootboot.env_previous]

        update!(Bundler.definition)
      end
    end

    def update!(current_definition)
      env = which_env
      lock = which_lock

      Bundler.ui.confirm("Updating the #{lock}")
      ENV[env] = '1'
      ENV['BOOTBOOT_UPDATING_ALTERNATE_LOCKFILE'] = '1'

      unlock = original_unlock(current_definition)
      definition = Bundler::Definition.build(GEMFILE, lock, unlock)
      definition.resolve_remotely!
      definition.lock(lock)
    ensure
      ENV.delete(env)
      ENV.delete('BOOTBOOT_UPDATING_ALTERNATE_LOCKFILE')
    end

    def which_env
      if Bundler.default_lockfile.to_s =~ /_next\.lock/
        Bootboot.env_previous
      else
        Bootboot.env_next
      end
    end

    def which_lock
      if Bundler.default_lockfile.to_s =~ /_next\.lock/
        GEMFILE_LOCK
      else
        GEMFILE_NEXT_LOCK
      end
    end

    # Bundler doesn't directly save the value of unlock passed to
    # Definition#initialize to @unlock, but rather stores a hash in @unlock
    # even if the value passed to Definition#ininialize is true, false, or nil.
    # This method infers the original unlock argument. This is tightly coupled
    # to the internals of Bundler since it's not guaranteed that
    # @unlocking_bundler will always correspond to the type of unlock
    def original_unlock(definition)
      unlocking_bundler = definition.instance_variable_get(:@unlocking_bundler)
      if unlocking_bundler == false
        definition.instance_variable_get(:@unlocking)
      else
        unlocking_bundler
      end
    end
  end
end
