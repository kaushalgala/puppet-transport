# Copyright (C) 2013 VMware, Inc.
# Monkey patch transaction to cleanup Transport connection.
# We need this to cleanup ssh/vcenter/vshield connections regardless of resource apply result.
module Puppet
  class Transaction
    alias_method :evaluate_original, :evaluate

    def evaluate
      evaluate_original
      PuppetX::Puppetlabs::Transport.cleanup
    end
  end
end

module PuppetX
  module Puppetlabs
    module Transport
      @@instances = []

      # Accepts a puppet resource reference, resource catalog, and loads connetivity info.
      def self.retrieve(options={})
        unless res_hash = options[:resource_hash]
          catalog  = options[:catalog]
          res_ref  = options[:resource_ref].to_s
          #TODO:  Can we change name to be catalog.resource(res_ref)[:name]?  Not sure of the long term effects of this, but I can't see anything awful happening.
          name     = Puppet::Resource.new(nil, res_ref).title
          res      = catalog.resource(res_ref)
          res_hash = res.to_hash
          [:server, :username, :password, :options].each do |attr|
            res_hash[attr] ||= res.provider.send(attr)
          end
        end

        provider = options[:provider]

        # name sometimes might not be the actual name the transport is initialized with.
        # For example, using Transport[vcenter] for the transport metaparameter could result in a transport object its hostname, like 'vcenter-localhost'
        # name variable above will be == 'vcenter' in this case, so unless we use find method with res_hash[:name], we will initiate a new connection on every resource thinking it doesn't exist
        transport = find(name, provider) || find(res_hash[:name], provider)

        unless transport
          transport = PuppetX::Puppetlabs::Transport::const_get(provider.to_s.capitalize).new(res_hash)
          transport.connect
          @@instances << transport
        end

        transport
      end

      def self.cleanup
        @@instances.each do |i|
          i.close if i.respond_to? :close
        end
      rescue
      end

      private

      def self.find(name, provider)
        @@instances.find{ |x| x.is_a? PuppetX::Puppetlabs::Transport::const_get(provider.to_s.capitalize) and x.name == name }
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def transport
        self.class.transport(resource)
      end

      module ClassMethods
        def transport(resource)
          @transport ||= PuppetX::Puppetlabs::Transport.retrieve(
            :resource_ref => resource[:transport],
            :catalog => resource.catalog,
            :provider => resource.provider.class.name
          )
        end
      end
    end
  end
end
