require "interactor/context"
require "interactor/organizer"

module Interactor
  def self.included(base)
    base.class_eval do
      extend ClassMethods

      attr_reader :context
    end
  end

  module ClassMethods
    def call(context = {})
      new(context).tap(&:call_with_hooks).context
    end

    def rollback(context = {})
      new(context).tap(&:rollback).context
    end

    def around(&hook)
      around_hooks.push(hook)
    end

    def before(&hook)
      before_hooks.push(hook)
    end

    def after(&hook)
      after_hooks.unshift(hook)
    end

    def around_hooks
      @around_hooks ||= []
    end

    def before_hooks
      @before_hooks ||= []
    end

    def after_hooks
      @after_hooks ||= []
    end
  end

  def initialize(context = {})
    @context = Context.build(context)
  end

  def call_with_hooks
    with_hooks { call }
  end

  def call
  end

  def rollback
  end

  private

  def with_hooks
    call_around_hooks do
      call_before_hooks
      yield
      call_after_hooks
    end
  end

  def call_around_hooks(&block)
    self.class.around_hooks.reverse.inject(block) { |chain, hook|
      proc { instance_exec(chain, &hook) }
    }.call
  end

  def call_before_hooks
    call_hooks(self.class.before_hooks)
  end

  def call_after_hooks
    call_hooks(self.class.after_hooks)
  end

  def call_hooks(hooks)
    hooks.each { |hook| instance_exec(&hook) }
  end
end
