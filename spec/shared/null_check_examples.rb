
# frozen_string_literal: true

# NOTE: Define: :target, :field

shared_examples 'null_check' do
  context 'NULL check' do
    context "operator '='" do
      it 'filters on field IS NULL' do
        result = target.to_sql(double(value: 'NULL', operator: '=', 'value=' => 'ok'))
        expect(result.sql).to eq("#{field} IS NULL")
      end
    end

    context "operator '<>'" do
      it 'filters on field IS NOT NULL' do
        result = target.to_sql(double(value: 'NULL', operator: '<>', 'value=' => 'ok'))
        expect(result.sql).to eq("#{field} IS NOT NULL")
      end
    end
  end
end
