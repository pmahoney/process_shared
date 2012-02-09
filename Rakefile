require 'ffi'
require 'rake/extensiontask'
require 'rake/testtask'
require 'rake/version_task'
require 'rubygems/package_task'
require 'rubygems/gem_runner'

def gemspec
  @gemspec ||= Gem::Specification.load('process_shared.gemspec')
end

Rake::ExtensionTask.new('helper') do |ext|
  ext.lib_dir = 'lib/process_shared/posix'
end

desc 'Run the tests'
task :default => [:test]

Rake::TestTask.new(:test => [:compile]) do |t|
  if FFI::Platform.mac?
    t.pattern = 'spec/**/*_spec.rb' # only include mach tests on mac
  else
    t.pattern = 'spec/process_shared/**/*_spec.rb'
  end
  t.libs.push 'spec'
end

pkg = Gem::PackageTask.new(gemspec) do |p|
  p.need_tar = true
  p.gem_spec = gemspec
end

task :gem => :compile

Rake::VersionTask.new do |t|
  t.with_git_tag = true
end

task :push => :gem do
  gem_file = File.basename gemspec.cache_file
  gem_path = File.join pkg.package_dir, gem_file
  Gem::GemRunner.new.run(["push", gem_path])
end

if Version.current.prerelease?
  vrelease = Version.current.bump!
  desc "Release version #{vrelease}"
  task :release => [:test, 'version:bump'] do
    # must run in subprocess so tasks use newwer versioned gemspec
    sh %{rake push version:bump:pre}
  end
end
