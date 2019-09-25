
# frozen_string_literal: true

# NOTE: Define :target, :field
shared_examples 'learning_objectives_null_check' do
  context 'null check' do
    it 'filters on field IS NULL' do
      result = target.to_sql(OpenStruct.new(value: 'NULL', operator: '='))
      ids = Minerva::Alignments::Taxonomy.where(field => nil).pluck(:id).join(',')
      if ids.present?
        expect(result.sql).to eq("(resources.direct_taxonomy_ids && ARRAY[#{ids}])")
      else
        expect(result.sql).to eq("1=0")
      end
    end

    it 'filters on field IS NOT NULL' do
      result = target.to_sql(OpenStruct.new(value: 'NULL', operator: '<>'))
      ids = Minerva::Alignments::Taxonomy.where.not(field => nil).pluck(:id).join(',')
      if ids.present?
        expect(result.sql).to eq("(resources.direct_taxonomy_ids && ARRAY[#{ids}])")
      else
        expect(result.sql).to eq("1=0")
      end
    end
  end
end

# NOTE: Define :target, :where_clause, :value, :taxonomy_pluck
# OPTIONALLY define :value2
shared_examples 'learning_objectives_expand_objectives' do
  context 'expand_objectives = true' do
    context "operator is '='" do
      it 'returns sql' do
        result = target.to_sql(OpenStruct.new(value: value, operator: '='), expand_objectives: 'true')
        expect(result.sql).to start_with('(resources.all_taxonomy_ids && ARRAY[')
        expect(result.sql_params.keys.count).to eq(0)
      end
    end
  end
end
