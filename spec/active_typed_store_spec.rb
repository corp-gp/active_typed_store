# frozen_string_literal: true

RSpec.describe ActiveTypedStore do
  context 'when active model type' do
    class TestModel < ActiveRecord::Base

      serialize :params, IndifferentCoder.new(:params, JSON)
      typed_store(
        :params,
        task_id:   ActiveModel::Type::Integer,
        notify_at: ActiveModel::Type::DateTime,
        asap:      ActiveModel::Type::Boolean,
      )

    end

    it 'casting for new model' do
      m = TestModel.new(task_id: '123', notify_at: '2020-02-02 11:11:11', asap: '1')

      expect(m.task_id).to eq 123
      expect(m.notify_at).to eq Time.parse('2020-02-02 11:11:11')
      expect(m.asap).to eq true
    end

    it 'casting for saved model' do
      m = TestModel.new(task_id: '123', notify_at: '2020-02-02 11:11:11')
      m.save!
      m.reload

      expect(m.task_id).to eq 123
      expect(m.notify_at).to eq Time.parse('2020-02-02 11:11:11')
    end

    it 'changes works for update model' do
      m = TestModel.new(task_id: '123', notify_at: '2020-02-02 11:11:11')
      m.save!
      m.reload

      m.update(task_id: '456', notify_at: '2020-02-02 09:09:09')

      expect(m.previous_changes['params']).to eq [{ 'notify_at' => '2020-02-02 11:11:11 UTC', 'task_id' => 123 },
                                                  { 'notify_at' => Time.parse('2020-02-02 09:09:09'), 'task_id' => 456 },]
    end

    it 'changes is empty, if assign same data' do
      m = TestModel.new(task_id: '123', notify_at: '2020-02-02 11:11:11')
      m.save!
      m.reload

      m.update(task_id: '123', notify_at: '2020-02-02 11:11:11')

      expect(m.previous_changes).to be_empty
    end

    it 'remove key from json if set nil' do
      m = TestModel.new(task_id: '123', notify_at: '2020-02-02 11:11:11')
      m.save!
      m.reload

      m.update(task_id: '123', notify_at: nil)

      expect(m.params).to eq({ 'task_id'=>123 })
    end
  end

  context 'when dry-types' do
    require 'dry-types'

    module Types

      include Dry.Types()

    end

    class TestModelDry < ActiveRecord::Base

      self.table_name = 'test_models'

      serialize :params, IndifferentCoder.new(:params, JSON)
      typed_store(
        :params,
        task_id:   Types::Params::Integer,
        notify_at: Types::Params::DateTime,
        asap:      Types::Bool.default(true),
        email:     Types::String.constrained(format: /@/),
      )

    end

    it 'casting for new model' do
      m = TestModelDry.new(task_id: '123', notify_at: '2020-02-02 11:11:11', asap: false, email: 'test@gmail.com')

      expect(m.task_id).to eq 123
      expect(m.notify_at).to eq Time.parse('2020-02-02 11:11:11')
    end

    it 'raise error when email invalid casting for new model' do
      expect { TestModelDry.new(email: 'test.gmail.com') }.to raise_error(Dry::Types::ConstraintError)
    end

    it 'works with nil value' do
      m = TestModelDry.new(asap: nil)

      expect(m.params).to eq({})
    end

    it 'return default value' do
      expect(TestModelDry.new.asap).to eq(true)
    end
  end
end
