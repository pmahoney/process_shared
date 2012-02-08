require 'rake/extensiontask'
require 'rake/testtask'
require 'rubygems/package_task'
require 'ffi'

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

Gem::PackageTask.new(gemspec) do |p|
  p.need_tar = true
  p.gem_spec = gemspec
end

task :gem => :compile
