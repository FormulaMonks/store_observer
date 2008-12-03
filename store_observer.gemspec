Gem::Specification.new do |s|
  s.name = "store_observer"
  s.version = "0.0.1"
  s.date = "2008-12-3"
  s.summary = "Automatic expiration of cached fragments"
  s.email = "michel.martens@citrusbyte.com"
  s.homepage = "http://github.com/citrusbyte/store_observer"
  s.description = "Automatically expire cached fragments based on the state of the models involved."
  s.has_rdoc = true
  s.authors = ["Michel Martens"]
  s.files = [
    "README.rdoc",
    "MIT-LICENSE",
    "store_observer.gemspec",
    "lib/store_observer.rb",
    "init.rb"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.extra_rdoc_files = ['README.rdoc']
end
