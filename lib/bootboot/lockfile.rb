# frozen_string_literal: true

module Bootboot
  # If the patch in "bootboot/bundler_patches" to
  # `Bundler::SharedHelpers.default_lockfile` is in effect, this class
  # coordinates, whether to use the original implementation (i.e. return
  # "Gemfile.lock" or "gems.locked") or override with Bootboot's lockfile (i.e.
  # "Gemfile_next.lock" or "gems_next.locked"). If the patch is not in effect,
  # this class has no effect and functions simply as a wrapper around
  # `Bundler.default_lockfile`.
  module Lockfile
    # The use of a Monitor here is not necessarily for concurrency support,
    # though it does function in that respect as well since multiple threads
    # could request the original lockfile in parallel in Rubies without a GIL.
    # Rather the monitor exists primarily so that it is easier to reason about
    # when `@call_original` will be modified. If `enable_dual_booting` has been
    # called and the patch in "bootboot/bundler_pathes" is in effect, we are
    # guaranteed that every caller of `Bundler::SharedHelpers.default_lockfile`
    # will receive `Lockfile.next` except the specific caller that is
    # requesting the original.
    extend MonitorMixin

    @call_original = false

    def self.from_original(original_lockfile)
      synchronize do
        if @call_original
          original_lockfile
        else
          to_next(original_lockfile)
        end
      end
    end

    def self.original
      synchronize do
        begin
          @call_original = true
          Bundler::SharedHelpers.default_lockfile
        ensure
          @call_original = false
        end
      end
    end

    def self.next
      to_next(original)
    end

    class << self
      private

      def to_next(lockfile)
        lockfile.sub('.lock', '_next.lock')
      end
    end
  end
end
