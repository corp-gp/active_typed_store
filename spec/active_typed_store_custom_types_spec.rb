# frozen_string_literal: true

RSpec.describe ActiveTypedStore do
  let(:m_klass) do
    class Parcel
      include ActiveModel::Attributes
      include ActiveModel::AttributeAssignment

      attribute :height, :float, default: 0
      attribute :weight, :float

      def initialize(attributes = {})
        super()
        assign_attributes(attributes)
      end

      def inspect = "<Parcel #{attributes.map { |k, v| "#{k}=#{v}" }.join(' ')}>"
      def as_json = attributes.compact
    end

    class ParcelType < ActiveRecord::Type::Json
      def cast(value)
        case value
        when Hash   then Parcel.new(value)
        when Parcel then value
        end
      end
    end

    class ParcelArrayType < ActiveRecord::Type::Json
      def cast(value)
        case value
        when Array
          value.map { _1.is_a?(Parcel) ? _1 : Parcel.new(_1) }
        end
      end
    end

    # ActiveRecord::Type.register(:parcel, ParcelType)
    # ActiveRecord::Type.register(:parcel_array, ParcelArrayType)

    Class.new(ActiveRecord::Base) do
      self.table_name = "test_models"

      typed_store(:params) do
        attr :task_id,  :integer
        attr :parcel,   ParcelType.new,      default: Parcel.new
        attr :parcels,  ParcelArrayType.new, default: []
      end
    end
  end

  it "check single custom type" do
    m = m_klass.create(task_id: "123")
    expect(m.params["task_id"]).to eq(123)
    expect(m.parcel.height).to eq 0
    expect(m.parcel.weight).to be_nil
    expect(m.changed?).to be(false)
    m.with_lock { 1 }

    m.parcel.weight = "12"
    m.save!
    expect(m.params["task_id"]).to eq(123)
    expect(m.parcel.height).to eq 0
    expect(m.parcel.weight).to eq 12

    m.reload
    expect(m.params["task_id"]).to eq(123)
    expect(m.parcel.height).to eq 0
    expect(m.parcel.weight).to eq 12
  end

  it "check array of custom type" do
    m = m_klass.create(task_id: "123", parcels: [weight: 2])
    expect(m.params["task_id"]).to eq(123)
    expect(m.parcels[0].height).to eq 0
    expect(m.parcels[0].weight).to eq 2
    expect(m.changed?).to be(false)
    m.with_lock { 1 }

    m.parcels[0].weight = "12"
    m.save!
    expect(m.params["task_id"]).to eq(123)
    expect(m.parcels[0].height).to eq 0
    expect(m.parcels[0].weight).to eq 12

    m.reload
    expect(m.params["task_id"]).to eq(123)
    expect(m.parcels[0].height).to eq 0
    expect(m.parcels[0].weight).to eq 12

    m.parcels << Parcel.new(weight: 33)
    m.save
    m.reload

    expect(m.params["task_id"]).to eq(123)
    expect(m.parcels[1].height).to eq 0
    expect(m.parcels[1].weight).to eq 33
  end

  it "check cross assign types" do
    m = m_klass.create(task_id: "123")

    m.parcel.weight = 12
    expect(m.changed?).to be(true)

    m.parcels
    expect(m.changed?).to be(true)

    m.save
    m.reload

    expect(m.parcel.weight).to eq 12
    expect(m.parcels).to be_empty
  end
end
