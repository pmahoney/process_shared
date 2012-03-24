Gem::Specification.new do |s|
  s.name = 'process_shared'
  s.version = File.read(File.expand_path('../VERSION', __FILE__))
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "ChangeLog", "COPYING"]
  s.summary = 'process-shared synchronization primitives'
  s.description = 'FFI wrapper around portable semaphore library with mutex and condition vars built on top.'
  s.author = 'Patrick Mahoney'
  s.email = 'pat@polycrystal.org'
  s.homepage = 'https://github.com/pmahoney/process_shared'
  s.files = Dir['lib/**/*.rb', 'lib/**/libpsem*', 'ext/**/*.{c,h,rb}', 'spec/**/*.rb']
  s.extensions = Dir['ext/**/extconf.rb']

  s.add_dependency('ffi', '~> 1.0')

  s.add_development_dependency('ci_reporter')
  s.add_development_dependency('flog')
  s.add_development_dependency('minitest')
  s.add_development_dependency('minitest-matchers')
  s.add_development_dependency('rake')
  s.add_development_dependency('rake-compiler')
  s.add_development_dependency('version')
end
