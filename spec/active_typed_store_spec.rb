# frozen_string_literal: true

RSpec.describe ActiveTypedStore do
  shared_examples "common examples" do |model|
    it "casting for new model" do
      m = model.new(task_id: "123", notify_at: "2020-02-02 11:11:11", asap: "yes")

      expect(m.task_id).to eq 123
      expect(m.notify_at).to eq Time.parse("2020-02-02 11:11:11")
      expect(m.asap).to be true
    end

    it "assign false value" do
      m = model.new(asap: false)

      expect(m.asap).to be false
    end

    it "casting for saved model" do
      m = model.new(task_id: "123", notify_at: "2020-02-02 11:11:11")
      m.save!
      m.reload

      expect(m.task_id).to eq 123
      expect(m.notify_at).to eq Time.parse("2020-02-02 11:11:11")
    end

    it "changes works for update model" do
      m = model.new(task_id: "123", notify_at: "2020-02-02 11:11:11")
      m.save!
      m.reload

      m.update(task_id: "456", notify_at: "2020-02-02 09:09:09")

      expect(m.previous_changes["params"]).to eq [{ "notify_at" => "2020-02-02 11:11:11 UTC", "task_id" => 123 },
                                                  { "notify_at" => Time.parse("2020-02-02 09:09:09"), "task_id" => 456 },]
    end

    it "changes is empty, if assign same data" do
      m = model.new(task_id: "123", notify_at: "2020-02-02 11:11:11")
      m.save!
      m.reload

      m.update(task_id: "123", notify_at: "2020-02-02 11:11:11")

      expect(m.previous_changes).to be_empty
    end

    it "remove key from json if set nil" do
      m = model.new(task_id: "123", notify_at: "2020-02-02 11:11:11")
      m.save!
      m.reload

      m.update(task_id: "123", notify_at: nil)

      expect(m.params).to eq({ "task_id"=>123 })
    end

    it "works with nil value" do
      m = model.new(asap: nil)

      expect(m.params).to eq({})
    end
  end

  context "when active model type" do
    class TestModel < ActiveRecord::Base
      serialize :params, coder: IndifferentCoder.new(:params, JSON)
      typed_store(
        :params,
        task_id:   ActiveModel::Type::Integer,
        notify_at: ActiveModel::Type::DateTime,
        asap:      ActiveModel::Type::Boolean,
      )
    end

    include_examples "common examples", TestModel
  end

  context "when dry-types" do
    require "dry-types"

    module Types
      include Dry.Types()
    end

    class TestModelDry < ActiveRecord::Base
      self.table_name = "test_models"

      serialize :params, coder: IndifferentCoder.new(:params, JSON)
      typed_store(
        :params,
        task_id:   Types::Params::Integer,
        notify_at: Types::Params::DateTime,
        asap:      Types::Bool.default(true),
        email:     Types::String.constrained(format: /@/),
      )
    end

    include_examples "common examples", TestModelDry

    it "raise error when email invalid casting for new model" do
      expect { TestModelDry.new(email: "test.gmail.com") }.to raise_error(Dry::Types::ConstraintError)
    end

    it "return default value" do
      expect(TestModelDry.new.asap).to be(true)
    end
  end
end
