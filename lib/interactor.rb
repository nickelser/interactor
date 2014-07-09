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
  end

  def initialize(context = {})
    @context = Context.build(context)
  end

  def perform_with_hooks
    with_hooks do
      perform
    end
  rescue => error
    if error.is_a?(Failure)
      rollback
    else
      raise error
    end
  end

  def perform
  end

  def rollback
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
      context.send(method)
    else
      super
    end
  end

  def respond_to_missing?(method, *)
    (context && context.respond_to?(method)) || super
  end
end
