Gem::Specification.new do |s|
  s.name        = 'omloga'
  s.version     = '0.0.1'
  s.date        = '2013-10-07'
  s.summary     = "A Ruby on Rails log parser and stitcher."
  s.description = "Stitches together log lines of every request and inserts them as one record in MongoDB for easier analysis"
  s.authors     = ["Srirang G Doddihal"]
  s.email       = 'om.brahmana@gmail.com'
  s.files       = ["lib/omloga.rb", "lib/omloga/request.rb"]
  s.homepage    = 'http://rubygems.org/gems/omloga'
  s.license     = 'MIT'
  s.require_path = 'lib'
  s.executables << 'omloga'
  s.add_dependency("moped",   ["~> 1.4.3"])
end
