$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "economics/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "economics"
  s.version     = Economics::VERSION
  s.authors     = ["Yassine Zenati"]
  s.email       = ["yassine@capsens.eu"]
  s.homepage    = "https://github.com/capsens/economics"
  s.summary     = "Summary of Economics."
  s.description = "Description of Economics."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1"
  s.add_dependency "flt"
  s.add_development_dependency "pg"
end
