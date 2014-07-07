require "interactor/context"
require "interactor/error"
require "interactor/hooks"
require "interactor/organizer"

module Interactor
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      include Hooks

      attr_reader :context
    end
  end

  module ClassMethods
    def perform(context = {})
      new(context).tap(&:perform_with_hooks).context
    end

    def rollback(context = {})
      new(context).tap(&:rollback).context
    end

    def success?
      context.success?
    end

    def failure?
      context.failure?
    end

    def fail!(*args)
      context.fail!(*args)
    end

    def method_missing(method, *)
      if context.respond_to?(method)
        context.send(:method)
      else
        super
      end
    end

    def respond_to_missing?(method, *)
      (context && contex.respond_to?(method)) || super
    end
  end

  def initialize(context = {})
    @context = Context.build(context)
  end

  def perform_with_hooks
    called = false

    with_hooks do
      perform
      called = true
    end
  rescue => error
    rollback if called
    raise unless error.is_a?(Failure)
  end

  def perform
  end

  def rollback
  end
end
