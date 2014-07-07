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
