# StoreObserver
#
# Adds versions to the fragments based on the state of the models involved in.
#
# <% store 'fragment_name', :observe => [:users, :coments] do %>
#   the cached fragment which does something intensive
# <% end %>
#
# This will be cached until a save or destroy occur in the User and Comment models.
#
module ActiveRecord
  module StoreObserver
    def self.included(base)
      [:before_save, :before_destroy].each do |callback|
        base.send(callback) do |record|
          returning true do
            ActionController::Caching::StoreObserver.increment_counter_for(record)
          end
        end
      end
    end
  end
end


module ActionController
  module Caching
    module StoreObserver

      # Increments the counter for a model in the cache.
      def self.increment_counter_for(model)
        model_name = model.class.name.underscore
        store.write(model_name, counter = increment(store.read(model_name)))
      end

      def self.increment(value=nil)
        value ? value.to_i.succ : 0
      end

      # Provides access to the fragment cache.
      def self.store
        Rails.cache
      end

      # Returns the current version of the observed model.
      def stored_counter_for(model_name)
        unless count = StoreObserver.store.read(model_name)
          StoreObserver.store.write(model_name, count = 0)
        end; count
      end

      # Generates a key based on the name and the models passed.
      def fragment_key_for(name, observables, separator = '-')
        observables.map do |observable|
          model_name = observable.to_s.singularize
          model_counter  = stored_counter_for(model_name)
          [model_name, model_counter].join(separator)
        end.unshift(name).join(separator)
      end

      # Reads a fragment from cache or writes it if it's not present.
      def store_fragment(name, observables, fragment_block)

        # Continue only if performing caching
        return fragment_block.call unless perform_caching

        # Fragment key
        fragment_key = fragment_key_for(name, observables)
        fragment_buffer = eval("_erbout", fragment_block.binding)

        if fragment = read_fragment(fragment_key)
          fragment_buffer.concat(fragment)
        else
          position = fragment_buffer.length; fragment_block.call
          write_fragment(fragment_key, fragment_buffer[position..-1])
        end
      end
    end
  end
end

module ActionView
  module Helpers
    module StoreObserverHelper
      class ModelsNotProvided < ArgumentError; end

      # Selects a fragment from the view to be cached.
      # It requires a name, which not necessarily has to be unique,
      # and a list of models to be observed for changes.
      #
      # For this method to work properly, Memcached is
      # highly recommended.
      #
      # Usage:
      #
      #   <% store 'some_name', :observe => [:users, :posts] do %>
      #     ...
      #   <% end %>
      #
      # Or in haml:
      #
      # - store "some_name", :observe => [:users, :posts] do
      #   ...
      #
      def store(name, options = {}, &fragment_block)
        raise ModelsNotProvided unless options[:observe]

        observables = [options[:observe]].flatten
        @controller.store_fragment(name, observables, fragment_block)
      end
    end
  end
end

ActionController::Base.send :include, ActionController::Caching::StoreObserver
ActionView::Base.send :include, ActionView::Helpers::StoreObserverHelper
ActiveRecord::Base.send :include, ActiveRecord::StoreObserver
