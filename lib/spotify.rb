# encoding: utf-8
require 'ffi'
require 'libspotify'

# FFI bindings for libspotify.
#
# See {Spotify::API} for the attached libspotify API methods.
#
# See official libspotify documentation for more detailed documentation about
# functions, types, errors, and library behavior.
#
# @see http://developer.spotify.com/en/libspotify/docs/
module Spotify
  # API is the class which has all libspotify functions attached.
  #
  # All functions are attached as both instance methods and class methods, mainly
  # because that’s how FFI works it’s magic with attach_function. However, as this
  # is a class it allows to be instantiated.
  class API
    extend FFI::Library

    begin
      ffi_lib [LIBSPOTIFY_BIN, 'libspotify', '/Library/Frameworks/libspotify.framework/libspotify']
    rescue LoadError
      puts "Failed to load the `libspotify` library. Please make sure you have it
      installed, either globally on your system, in your LD_LIBRARY_PATH, or in
      your current working directory (#{Dir.pwd}).

      For installation instructions, please see:
        https://github.com/Burgestrand/Hallon/wiki/How-to-install-libspotify".gsub(/^ */, '')
      puts
      raise
    end

    # @!group FFI API

    # @param [Symbol] enum either enum name or type
    # @return [FFI::Enum] key-value mapping for this enum
    def enum_type(enum)
      self.class.enum_type(enum)
    end

    # Finds an enum that contains the given key, and returns
    # the keys value.
    #
    # @param [Symbol] enum
    # @return [Integer] value of the enum symbol
    def enum_value(enum)
      self.class.enum_value(enum)
    end
  end

  @__actor__ = Spotify::API.new

  class << self
    (instance_methods - [:object_id, :__send__, :method, :name, :to_s, :inspect, :constants, :const_get, :const_missing]).each do |m|
      undef_method(m)
    end

    # Like send, but raises an error if the method returns a non-OK error.
    #
    # @note this works for non-error returning methods as well, it just does
    #       not do anything interesting
    #
    # @param [#to_s] name
    # @param args
    # @raise [Spotify::Error] if an error other than :ok is returned
    def try(name, *args, &block)
      @__actor__.public_send(name, *args, &block).tap do |error|
        error, symbol = Spotify::Error.disambiguate(error)
        next if symbol.nil?
        next if symbol == :ok
        raise Error.new(symbol)
      end
    end

    # Asks the underlying Spotify API if it responds to `name`.
    #
    # @note You never need to call this yourself. It’s automatically
    #       invoked when you do `Spotify.respond_to?`.
    #
    # @return [Boolean] true if the API supports the given method.
    def respond_to_missing?(name, include_private = false)
      @__actor__.respond_to?(name, include_private)
    end

    # Calls the method `name` on the underlying Spotify API.
    #
    # @param [Symbol, String] name
    # @param [Object, …] args
    def method_missing(name, *args, &block)
      @__actor__.public_send(name, *args, &block)
    end
  end
end

require 'spotify/version'
require 'spotify/util'
require 'spotify/types'
require 'spotify/error'
require 'spotify/objects'
require 'spotify/defines'
require 'spotify/structs'
require 'spotify/api'
