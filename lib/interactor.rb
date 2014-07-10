require "interactor/context"

module Interactor
  class Error < StandardError; end
  class Failure < Error; end

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      include InstanceMethods

      attr_reader :context
    end
  end

  module ClassMethods
    def perform(context = {})
      new(context).tap(&:call_perform).context
    end

    def rollback(context = {})
      new(context).tap(&:call_rollback).context
    end
  end

  module InstanceMethods
    def initialize(context = {})
      @context = Context.build(context)
      @interactors = []
    end

    def setup
    end

    def perform
    end

    def rollback
    end

    def call_rollback
      @interactors.each(&:rollback)
      rollback
    end

    def call_perform
      setup
      perform
    rescue => error
      if error.is_a?(Failure)
        call_rollback
      else
        raise error
      end
    end

    def perform_interactor(interactor)
      perform_interactors(interactor)
    end

    def perform_interactors(*interactors)
      interactors.each do |interactor|
        instance = interactor.new(context)
        instance.call_perform

        if context.failure?
          call_rollback
          raise Failure
        else
          @interactors << instance
        end
      end
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
  end
end
