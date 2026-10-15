# frozen_string_literal: true

RSpec.describe ActiveTypedStore do
  def model(column: :params, encrypted: true)
    Class.new(ActiveRecord::Base) do
      self.table_name = "test_models"

      typed_store(column, encrypted:) do
        attr :wb_token,       :string
        attr :ozon_client_id, :string
        attr :price,          :decimal
        attr :settings,       :json
      end
    end
  end

  def raw(record, column: :params)
    ActiveRecord::Base.connection.select_value("SELECT #{column} FROM test_models WHERE id = #{record.id}")
  end

  def encrypted?(value) = ActiveRecord::Encryption.encryptor.encrypted?(value)

  let(:m_klass) { model }

  it "keeps keys and encrypts values" do
    m = m_klass.create!(wb_token: "secret", ozon_client_id: "123", settings: { "a" => 1 })

    stored = JSON.parse(raw(m))
    expect(stored.keys).to contain_exactly("wb_token", "ozon_client_id", "settings")
    expect(stored.values).to all(satisfy { encrypted?(_1) })
    expect(raw(m)).not_to include("secret", "123")
  end

  it "decrypts and casts values after reload" do
    m = m_klass.create!(wb_token: "secret", ozon_client_id: "123", price: "516.0", settings: { "a" => 1 })
    m = m_klass.find(m.id)

    expect(m.wb_token).to eq("secret")
    expect(m.ozon_client_id).to eq("123")
    expect(m.price).to eq(BigDecimal("516"))
    expect(m.settings).to eq({ "a" => 1 })
  end

  it "does not change store on read and on assigning the same values" do
    m = m_klass.create!(wb_token: "secret", price: "516.0")
    m = m_klass.find(m.id)

    m.wb_token
    m.price
    expect(m.changed?).to be(false)

    m.update!(wb_token: "secret", price: "516.0")
    expect(m.previous_changes).to be_empty
  end

  it "tracks changes of attributes" do
    m = m_klass.create!(wb_token: "secret")
    m.update!(wb_token: "new secret")

    expect(m.saved_change_to_wb_token).to eq(["secret", "new secret"])
    expect(m_klass.find(m.id).wb_token).to eq("new secret")
  end

  it "keeps encryption in inherited model" do
    m = Class.new(m_klass).create!(wb_token: "secret")

    expect(encrypted?(JSON.parse(raw(m))["wb_token"])).to be(true)
  end

  it "works with text column" do
    m = model(column: :text_params).create!(wb_token: "secret")

    expect(encrypted?(JSON.parse(raw(m, column: :text_params))["wb_token"])).to be(true)
    expect(model(column: :text_params).find(m.id).wb_token).to eq("secret")
  end

  it "works with column default" do
    klass = model(column: :default_params)
    m = klass.new

    expect(m.wb_token).to be_nil
    m.update!(wb_token: "secret")
    expect(klass.find(m.id).wb_token).to eq("secret")
  end

  it "passes encrypts options to scheme" do
    klass = model(encrypted: { deterministic: true })
    first  = klass.create!(wb_token: "secret")
    second = klass.create!(wb_token: "secret")

    expect(raw(first)).to eq(raw(second))
  end

  context "with not encrypted data" do
    let(:record_id) do
      record = m_klass.create!
      m_klass.where(id: record.id).update_all(["params = ?", '{"wb_token":"plain"}'])
      record.id
    end

    it "raises like encrypts" do
      expect { m_klass.find(record_id).wb_token }.to raise_error(ActiveRecord::Encryption::Errors::Decryption)
    end

    it "reads it with support_unencrypted_data" do
      ActiveRecord::Encryption.config.support_unencrypted_data = true

      expect(model(encrypted: { support_unencrypted_data: true }).find(record_id).wb_token).to eq("plain")
    ensure
      ActiveRecord::Encryption.config.support_unencrypted_data = false
    end
  end

  it "uses shared json type without encryption" do
    klass =
      Class.new(ActiveRecord::Base) do
        self.table_name = "test_models"

        typed_store(:params) { attr :name, :string }
      end

    expect(klass.attribute_types["params"]).to be(ActiveTypedStore::Store::CUSTOM_JSON)
  end
end
