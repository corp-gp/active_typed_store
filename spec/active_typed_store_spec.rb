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
      m = model.new(asap: true)

      expect(m.asap).to be true
    end

    it "casting for saved model" do
      m = model.new(task_id: "123", notify_at: "2020-02-02 11:11:11")
      m.save!
      m.reload

      expect(m.task_id).to eq 123
      expect(m.notify_at).to eq Time.parse("2020-02-02 11:11:11")
    end

    it "changes works for update model" do
      m = model.create!(task_id: "123", notify_at: "2020-02-02 11:11:11")

      m.update(task_id: "456", notify_at: "2020-02-02 09:09:09")

      expect(m.previous_changes["params"][0]["notify_at"]).to start_with("2020-02-02")
      expect(m.previous_changes["params"][0]["task_id"]).to eq 123
      expect(m.previous_changes["params"][1]).to eq({ "notify_at" => Time.parse("2020-02-02 09:09:09"), "task_id" => 456 })
    end

    it "check *_changed? methods" do
      m = model.new(task_id: "123")
      expect(m.task_id_was).to be_nil
      expect(m.task_id_changed?).to be true
    end

    it "changes is empty, if assign same data" do
      m = model.new(task_id: "123", notify_at: "2020-02-02 11:11:11")
      m.save!
      m.reload

      m.update(task_id: "123", notify_at: "2020-02-02 11:11:11")

      expect(m.previous_changes).to be_empty
    end

    it "remove key from json if set nil" do
      m = model.create!(task_id: "123", notify_at: "2020-02-02 11:11:11")

      m.update(task_id: "123", notify_at: nil)

      expect(m.params).to eq({ "task_id"=>123 })
    end

    it "remove all nil keys from json" do
      m = model.create!(task_id: "123", notify_at: "2020-02-02 11:11:11")

      m.update(task_id: nil, notify_at: nil)

      expect(m.params).to be_empty
    end

    it "works with nil value" do
      m = model.new(asap: nil)

      expect(m.params).to eq({})
    end

    it "same object id for typed attribute" do
      m = model.new(params: { notify_at: "2020-02-02 11:11:11" })

      obj_id = m.notify_at.object_id
      3.times { expect(m.notify_at.object_id).to eq(obj_id) }
    end

    it "check actual value when mutate model attibute" do
      m = model.create(name: "name")
      expect(m.name).to eq "name"

      m.name << "123"
      expect(m.name).to eq "name123"
      expect(m.params["name"]).to eq "name123"

      m.update(params: { name: "n" })
      expect(m.name).to eq "n"
    end

    it "mutate default" do
      m = model.create(name: "name")
      expect(m.title).to eq "T"

      m.title << "i"
      expect(m.title).to eq "Ti"
    end

    it "check lock" do
      m = model.create(name: "name", notify_at: "2025-01-01")
      m.title
      m.settings
      m.notify_at

      m.with_lock { m.save }

      expect(m.title).to eq "T"
    end

    it "sync value with storage" do
      m = model.create(name: "name")

      m.params["name"] = +"name123"
      expect(m.name).to eq "name123"

      m.params["name"] << "456"
      expect(m.name).to eq "name123456"
    end

    it "return default value" do
      expect(model.new.asap).to be(false)
    end

    it "return default value" do
      m = model.new(params: { settings: { tariff_id: 1, type: "retail" } })
      expect(m.settings).to eq({ "tariff_id" => 1, "type" => "retail" })
    end

    it "predicate methods" do
      m = model.new(task_id: "123", notify_at: nil)

      expect(m).to be_task_id
      expect(m).not_to be_notify_at
      expect(m).not_to be_asap
    end

    it "not allows hash accesses by symbol" do
      m = model.create(task_id: "123", settings: { foo: "bar" })

      expect(m.params["task_id"]).to eq(123)
      expect { m.params[:task_id] }.to raise_error(ActiveTypedStore::SymbolKeysDisallowed)

      expect(m.settings["foo"]).to eq("bar")
      expect(m.params["settings"]["foo"]).to eq("bar")
      expect { m.settings[:foo] }.to raise_error(ActiveTypedStore::SymbolKeysDisallowed)
      expect { m.params["settings"][:foo] }.to raise_error(ActiveTypedStore::SymbolKeysDisallowed)
    end
  end

  context "when active model type" do
    class TestModel < ActiveRecord::Base
      typed_store(:params) do
        attr :task_id,    :integer
        attr :name,       :string
        attr :notify_at,  :datetime
        attr :asap,       :boolean, default: false
        attr :settings,   :json
        attr :title,      :string, default: "T"
      end
    end

    include_examples "common examples", TestModel
  end

  context "when dry-types" do
    module Types
      include Dry.Types()
    end

    class TestModelDry < ActiveRecord::Base
      self.table_name = "test_models"

      typed_store(:params) do
        attr :task_id,    Types::Params::Integer
        attr :name,       Types::Params::String
        attr :notify_at,  Types::Params::DateTime
        attr :asap,       Types::Params::Bool.default(false)
        attr :email,      Types::String.constrained(format: /@/)
        attr :settings,   Types::Params::Hash.default({})
        attr :title,      Types::Params::String.default("T")
      end
    end

    include_examples "common examples", TestModelDry

    it "raise error when email invalid casting for new model" do
      expect { TestModelDry.new(email: "test.gmail.com") }.to raise_error(Dry::Types::ConstraintError)
    end
  end

  context "with disabled hash safety" do
    let(:m_klass) do
      described_class.configure do |config|
        config.hash_safety = false
      end

      Class.new(ActiveRecord::Base) do
        self.table_name = "test_models"

        typed_store(:params) do
          attr :task_id,    :integer
          attr :settings,   :json, default: {}
        end
      end
    end

    it "allows hash access by symbols with disabled hash_safety" do
      m = m_klass.create(task_id: "123", settings: { foo: "bar" })
      expect(m.params["task_id"]).to eq(123)
      expect(m.params[:task_id]).to be_nil
      expect(m.params["settings"]["foo"]).to eq("bar")
      expect(m.settings[:foo]).to be_nil
    end

    it "check assign for json field with default value" do
      m = m_klass.create(task_id: "123")

      m.settings["foo"] = "bar"
      m.save
      m.reload
      expect(m.settings["foo"]).to eq("bar")

      m.settings["foo2"] = "bar2"
      expect(m.settings["foo"]).to eq("bar")
      expect(m.settings["foo2"]).to eq("bar2")
    end
  end
end
