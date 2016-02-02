$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'wait_for_it'


def fixture_path(name = nil)
  path = Pathname.new(File.expand_path("../fixtures", __FILE__))
  path = path.join(name) if name
  path
end
