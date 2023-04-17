RSpec.describe CamelSnakeStruct do
  context 'when once of structs' do
    it "responds correctly to scalar values" do
      result = described_class.new('version' => 1, 'rubyVersion' => '2.5.0')

      expect(result).to have_attributes(
        version: 1, ruby_version: "2.5.0", rubyVersion: "2.5.0"
      )
      expect(result['version']).to eq(1)
    end

    it "responds correctly to missing methods" do
      result = described_class.new('version' => 1, 'rubyVersion' => '2.5.0')

      expect(result).to have_attributes(version?: true, ruby_version?: true, unknown?: false)

      expect { result.unknown }.to raise_error(NoMethodError)
    end

    it "responds correctly to scalar array values" do
      result = described_class.new('versions' => [1, 2, 3], 'rubyVersions' => ['2.5.0', '2.6.0'], 'oldVersions' => [])

      expect(result).to have_attributes(
        versions: [1, 2, 3], ruby_versions: ['2.5.0', '2.6.0'], rubyVersions: ['2.5.0', '2.6.0'],
        old_versions: []
      )
      expect(result['versions'][0]).to eq(1)
    end

    it "responds correctly to hash values" do
      result = described_class.new('enter' => { 'the' => 'dragon', 'oneMore' => { 'layerDeeper' => 'please' } })

      expect(result.enter.the).to eq('dragon')
      expect(result.enter.one_more.layer_deeper).to eq('please')
      expect(result.enter.oneMore.layer_deeper).to eq('please')
      expect(result.enter.one_more.layerDeeper).to eq('please')
      expect(result.enter.one_more.to_h).to eq('layerDeeper' => 'please')
      expect(result['enter']['the']).to eq('dragon')
    end

    it "responds correctly to hash array values" do
      result = described_class.new('onThe' => [{ 'step' => 'good' }, { 'step' => 'bad' }])

      expect(result.on_the.first.step).to eq('good')
      expect(result.on_the[0].step).to eq('good')
      expect(result.on_the[1].step).to eq('bad')
      expect(result.on_the.map(&:step)).to eq(['good', 'bad'])
    end
  end

  context 'when learning structs' do
    it 'remembers that it is array when array of scalars' do
      MyLearningStruct1 = Class.new(described_class)

      result1 = MyLearningStruct1.new('data' => ['Jeff'])
      expect(result1.data).to eq(["Jeff"])

      result2 = MyLearningStruct1.new('errors' => ['failed to get response'])
      expect(result2.data).to eq([])
      expect(result2.errors).to eq(['failed to get response'])

      expect(MyLearningStruct1.instance_methods(false)).to contain_exactly(:data, :errors)
    end

    it 'remembers that it is array when array of hashes' do
      MyLearningStruct2 = Class.new(described_class)

      result1 = MyLearningStruct2.new('data' => [{ 'name' => 'Jeff' }])
      expect(result1.data.map(&:name)).to eq(["Jeff"])

      result2 = MyLearningStruct2.new('errors' => ['failed to get response'])
      expect(result2.data.map(&:name)).to eq([])
    end

    it 'remembers keys of nested values' do
      MyLearningStruct3 = Class.new(described_class)

      result1 = MyLearningStruct3.new('data' => { 'stepUp' => 'Jeff', 'stepDown' => ['1'] })
      expect(result1.data.step_up).to eq('Jeff')
      expect(result1.data.step_down.first).to eq('1')

      result2 = MyLearningStruct3.new('data' => {})
      expect(result2.data.step_up).to be_nil
      expect(result2.data.step_down.first).to be_nil

      result2 = MyLearningStruct3.new('data' => nil)
      expect(result2.data).to be_nil
    end

    it 'learns from example' do
      MyLoadedStruct = Class.new(described_class)

      MyLoadedStruct.example('data' => [{ 'name' => 'Jeff' }], 'errors' => ['text'],
                             'date' => { 'timezone' => 'UTC', 'unixTime' => 0 })

      result3 = MyLoadedStruct.new({})
      expect(result3).to have_attributes(data: [], errors: [], date: nil)

      result4 = MyLoadedStruct.new({ 'date' => {} })
      expect(result4.date).to have_attributes(timezone: nil, unix_time: nil)
    end

    it "responds correctly to missing keys" do
      MyMissingStruct = Class.new(described_class)

      result1 = MyMissingStruct.new('version' => 1, 'rubyVersion' => '2.5.0')
      expect(result1).to have_attributes(version?: true, rubyVersion?: true, ruby_version?: true, unknown?: false)

      result2 = MyMissingStruct.new('unknown' => nil)
      expect(result2).to have_attributes(version?: false, rubyVersion?: false, ruby_version?: false, unknown?: true)
    end

    describe '.types_meta_data' do
      it 'stores types for scalar values' do
        ScalarStruct = Class.new(described_class)
        ScalarStruct.example('scalar' => 1)

        expect(ScalarStruct.types_meta_data.keys).to eq(%w[scalar])
        expect(ScalarStruct.types_meta_data['scalar']).to have_attributes(classes: [Integer], array: false)

        ScalarStruct.example('scalar' => nil)
        expect(ScalarStruct.types_meta_data['scalar']).to have_attributes(classes: [Integer, NilClass],
                                                                          array: false)
      end

      it 'stores types for array scalar values' do
        AsStruct = Class.new(described_class)
        AsStruct.example('as' => ["num", nil])

        expect(AsStruct.types_meta_data.keys).to eq(%w[as])
        expect(AsStruct.types_meta_data['as']).to have_attributes(classes: [String, NilClass], array: true)

        AsStruct.example('as' => [true, :symbol])
        expect(AsStruct.types_meta_data['as']).to have_attributes(
          classes: [String, NilClass, TrueClass, Symbol], array: true
        )
      end

      it 'stores types for complex values' do
        ComplexStruct = Class.new(described_class)
        ComplexStruct.example('complex' => { 'num' => 1 }, 'complex_array' => [{ 'num' => 1 }])

        expect(ComplexStruct.types_meta_data.keys).to eq(%w[complex complex_array])
        expect(ComplexStruct.types_meta_data['complex']).to have_attributes(array: false)
        expect(ComplexStruct.types_meta_data['complex'].classes.size).to eq(1)
        expect(ComplexStruct.types_meta_data['complex'].classes.first.superclass).to eq(described_class)

        expect(ComplexStruct.types_meta_data['complex_array']).to have_attributes(array: true)
        expect(ComplexStruct.types_meta_data['complex'].classes.size).to eq(1)
        expect(ComplexStruct.types_meta_data['complex'].classes.first.superclass).to eq(described_class)
      end
    end
  end
end
