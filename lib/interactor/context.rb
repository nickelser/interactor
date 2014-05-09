require "ostruct"

module Interactor
  class Context < OpenStruct
    def self.build(context = {})
      self === context ? context : new(context)
    end

    def success?
      !failure?
    end

    def failure?
      @failure || false
    end

    def fail!(context = {})
      modifiable.update(context)
      @failure = true
      raise Failure
    end

    def called!(interactor)
      _called << interactor
    end

    def rollback!
      return false if @rolled_back

      _called.reverse_each do |interactor|
        interactor.rollback(self)
      end

      @rolled_back = true
    end

    def _called
      @called ||= []
    end
  end
end
