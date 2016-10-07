Gem::Specification.new do |s|
  s.name        = "puppet-transport"
  s.version     = "0.0.1"
  s.licenses    = ["Dell 2016"]
  s.summary     = "Dell ASM Puppet Transport"
  s.description = "Dell ASM Puppet Transport"
  s.authors     = ["Dell"]
  s.email       = "asm@dell.com"
  s.homepage    = "https://github.com/dell-asm/puppet-transport"

  s.add_dependency("hashdiff")
  s.add_dependency("rbvmomi")
  s.add_dependency("winrm")
  s.add_dependency("net-ssh")
  s.add_dependency("net-scp")

  s.add_dependency "json_pure", "2.0.1"


  s.files        = Dir.glob("lib/**/*")
  s.require_path = "lib"
end