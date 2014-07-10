require "spec_helper"

module Interactor
  describe Interactor do
    let(:interactor) { Class.new.send(:include, described_class) }

    describe ".perform" do
      let(:context) { double(:context) }
      let(:instance) { double(:instance, context: context) }

      it "performs an instance with the given context" do
        expect(interactor).to receive(:new).once.with(foo: "bar") { instance }
        expect(instance).to receive(:call_perform).once.with(no_args)

        expect(interactor.perform(foo: "bar")).to eq(context)
      end

      it "provides a blank context if none is given" do
        expect(interactor).to receive(:new).once.with({}) { instance }
        expect(instance).to receive(:call_perform).once.with(no_args)

        expect(interactor.perform).to eq(context)
      end

      it "calls setup before perform" do
        expect(interactor).to receive(:new).once.with({}) { instance }
        expect(instance).to receive(:call_perform).once.with(no_args)
        expect(instance).to receive(:setup).once.with(no_args)
        expect(instance).to receive(:perform).once.with(no_args)

        expect(interactor.perform).to eq(context)
      end
    end

    describe ".rollback" do
      let(:context) { double(:context) }
      let(:instance) { double(:instance, context: context) }

      it "rolls back an instance with the given context" do
        expect(interactor).to receive(:new).once.with(foo: "bar") { instance }
        expect(instance).to receive(:call_rollback).once.with(no_args)

        expect(interactor.rollback(foo: "bar")).to eq(context)
      end

      it "provides a blank context if none is given" do
        expect(interactor).to receive(:new).once.with({}) { instance }
        expect(instance).to receive(:call_rollback).once.with(no_args)

        expect(interactor.rollback).to eq(context)
      end
    end

    describe ".new" do
      let(:context) { double(:context) }

      it "initializes a context" do
        expect(Interactor::Context).to receive(:build).once.with(foo: "bar") { context }

        instance = interactor.new(foo: "bar")

        expect(instance).to be_a(interactor)
        expect(instance.context).to eq(context)
      end

      it "initializes a blank context if none is given" do
        expect(Interactor::Context).to receive(:build).once.with({}) { context }

        instance = interactor.new

        expect(instance).to be_a(interactor)
        expect(instance.context).to eq(context)
      end
    end

    describe "#perform" do
      let(:instance) { interactor.new }

      it "exists" do
        expect(instance).to respond_to(:perform)
        expect { instance.perform }.not_to raise_error
        expect { instance.method(:perform) }.not_to raise_error
      end
    end

    describe "#rollback" do
      let(:instance) { interactor.new }

      it "exists" do
        expect(instance).to respond_to(:rollback)
        expect { instance.rollback }.not_to raise_error
        expect { instance.method(:rollback) }.not_to raise_error
      end
    end

    describe "#perform_interactor" do
      let(:instance) { interactor.new }
      let(:context) { instance.context }
      let(:interactor2) { double(:interactor2) }
      let(:interactor3) { double(:interactor3) }
      let(:interactor4) { double(:interactor4) }

      it "builds up the called interactors" do
        interactor2.stub(:perform) do
          expect(instance.interactors).to eq([])
          interactor2
        end

        interactor3.stub(:perform) do
          expect(instance.interactors).to eq([interactor2])
          interactor3
        end

        interactor4.stub(:perform) do
          expect(instance.interactors).to eq([interactor2, interactor3])
          interactor4
        end

        expect {
          instance.perform_interactors interactor2, interactor3, interactor4
        }.to change {
          instance.interactors
        }.from([]).to([interactor2, interactor3, interactor4])
      end

      context "when an interactor fails" do
        before do
          interactor2.stub(:perform) { context.fail! }
        end

        it "aborts" do
          expect(interactor4).not_to receive(:perform)

          instance.perform_interactors interactor2, interactor3, interactor4
        end

        it "rolls back" do
          expect(instance).to receive(:rollback).once do
            expect(instance.called).to eq([interactor2])
          end

          instance.perform_interactors interactor2, interactor3, interactor4
        end
      end
    end
  end
end
