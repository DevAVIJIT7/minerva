
# frozen_string_literal: true

# NOTE: Define: :target_array, :field
shared_examples 'null_array_check' do
  context 'when checking for NULL' do
    context "when the operator is '='" do
      it 'checks if the array length is zero' do
        result = target_array.to_sql(double(value: 'NULL', operator: '='))
        expect(result.sql).to eq("array_length(#{field}, 1) IS NULL OR array_length(#{field}, 1) = 0")
      end
    end

    context "when the operator is '<>'" do
      it "checks if the array's length is present and greater than zero" do
        result = target_array.to_sql(double(value: 'NULL', operator: '<>'))
        expect(result.sql).to eq("array_length(#{field}, 1) IS NOT NULL AND array_length(#{field}, 1) > 0")
      end
    end
  end
end

# NOTE: Define: :target_array, :field, :var_name, :clause_equal, :clause_unequal
shared_examples 'text_arrays' do
  let(:clause_equal) do
    OpenStruct.new({ value: '10', operator: '=' }.merge!(equal_opts))
  end
  let(:clause_unequal) do
    OpenStruct.new({ value: '10', operator: '<>' }.merge!(unequal_opts))
  end

  context "when the operator is '='" do
    it 'checks if the array is present and contains the value' do
      result = target_array.to_sql(clause_equal)
      expect(result.sql).to match(/array_length\(#{field}, 1\) > 0 AND \(#{field}::citext\[\] && ARRAY\[:#{var_name}_\d+\]::citext\[\]\)/)
      expect(result.sql_params.keys.count).to eq(1)
      expect(result.sql_params.values.first).to eq('10')
    end
  end

  context "when the operator is '<>'" do
    it 'checks if the array is present but does containt the value' do
      result = target_array.to_sql(clause_unequal)
      expect(result.sql).to match(/array_length\(#{field}, 1\) > 0 AND NOT\(#{field}::citext\[\] && ARRAY\[:#{var_name}_\d+\]::citext\[\]\)/)
      expect(result.sql_params.keys.count).to eq(1)
      expect(result.sql_params.values.first).to eq('10')
    end
  end
end
