require "fileutils"
require "yaml"
require "logger"
require "time"
require "addressable/uri"

require "bob/builder"
require "bob/scm"
require "bob/scm/git"
require "bob/background_engines"

module Bob
  # Builds the specified <tt>buildable</tt>. This object must understand the following API:
  #
  # * <tt>buildable.kind</tt>
  #
  #   Should return a Symbol with whatever kind of repository the buildable's code is
  #   in (:git, :svn, etc).
  # * <tt>buildable.uri</tt>
  #
  #   Returns a string like "git://github.com/integrity/bob.git", pointing to the code
  #   repository.
  # * <tt>buildable.branch</tt>
  #
  #   What branch of the repository should we build?
  # * <tt>buildable.build_script</tt>
  #
  #   Returns a string containing the build_script to be run when "building".
  # * <tt>buildable.start_building(commit_id)</tt>
  #
  #   `commit_id` is a String that contains whatever is appropriate for the repo type,
  #   so it would be a SHA1 hash for git repos, or a numeric id for svn, etc. This is a
  #   callback so the buildable can determine how long it takes to build. It doesn't
  #   need to return anything.
  # * <tt>buildable.add_build(commit_id, build_status, build_output)</tt>
  #
  #   Callback for when the build finishes. It doesn't need to return anything. It will
  #   receive a string with the commit identifier, a boolean for the build exit status
  #   (true for successful builds, false fore failed ones) and a string with the build
  #   output (both STDOUT and STDERR).
  #
  #   A successful build is one where the build script returns a zero status code.
  #
  # The build process is to fetch the code from the repository (determined by
  # <tt>buildable.kind</tt> and <tt>buildable.uri</tt>), then checkout the specified
  # <tt>commid_ids</tt>, and finally run <tt>buildable.build_script</tt> on each.
  def self.build(buildable, *commit_ids)
    commit_ids.each do |commit_id|
      Builder.new(buildable, commit_id).build
    end
  end

  # Directory where the code for the different buildables will be checked out. Make sure
  # the user running Bob is allowed to write to this directory.
  def self.base_dir
    @base_dir || "/tmp"
  end

  # What to log with (must implement ruby's Logger interface). Logs to STDOUT by
  # default.
  def self.logger
    @logger || Logger.new(STDOUT)
  end

  # What will you use to build in background. Must respond to <tt>call</tt> and take a block
  # which will be run "in background". The default is to run in foreground.
  def self.background_engine
    @background_engine || BackgroundEngines::Foreground
  end

  class << self
    attr_writer :logger, :base_dir, :background_engine
  end
end
