
# frozen_string_literal: true

# NOTE: Define :target, :field, :exists_sql, :taxonomy_pluck
shared_examples 'learning_objectives_null_check' do
  context 'null check' do
    it 'filters on field IS NULL' do
      expect(Minerva::Alignments::Taxonomy).to receive(:where).with("#{field} IS NULL").and_return([])
      result = target.to_sql(OpenStruct.new(value: 'NULL', operator: '='))
      expect(result.sql).to eq('1=0')
    end

    it 'filters on field IS NOT NULL' do
      expect(Minerva::Alignments::Taxonomy).to receive(:where).with("#{field} IS NOT NULL").and_return(taxonomy_pluck)
      result = target.to_sql(OpenStruct.new(value: 'NULL', operator: '<>'))
      expect(result.sql).to eq(exists_sql)
    end
  end
end

# NOTE: Define :target, :where_clause, :value, :taxonomy_pluck
# OPTIONALLY define :value2
shared_examples 'learning_objectives_expand_objectives' do
  context 'expand_objectives = true' do
    context "operator is '='" do
      it 'returns sql' do
        new_value = defined?(value2) ? value2 : value
        expect(Minerva::Alignments::Taxonomy).to receive(:where).with(where_clause, value).and_return(taxonomy_pluck)
        result = target.to_sql(OpenStruct.new(value: new_value, operator: '='), expand_objectives: 'true')
        expect(result.sql).to eq('EXISTS(SELECT 1 FROM alignments AS a LEFT OUTER JOIN taxonomy_mappings AS tm ON a.taxonomy_id IN (tm.taxonomy_id, tm.target_id) WHERE (ARRAY[1, 2, 3] && ARRAY[coalesce(tm.taxonomy_id, -1), coalesce(tm.target_id, -1)] OR a.taxonomy_id IN (1,2,3)) AND a.status = 2 AND a.resource_id = resources.id)')
        expect(result.sql_params.keys.count).to eq(0)
      end
    end
  end
end
