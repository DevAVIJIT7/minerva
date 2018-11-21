DROP TRIGGER IF EXISTS on_update_resources_trigger ON resources;

CREATE OR REPLACE FUNCTION update_resources() RETURNS TRIGGER AS $$
BEGIN
  UPDATE resources SET
   tsv_text = to_tsvector('english'::regconfig, COALESCE(NEW.name, ''::character varying)::text) || to_tsvector('english'::regconfig, COALESCE(NEW.description, ''::text))  || to_tsvector('english'::regconfig, (SELECT COALESCE(string_agg(name, ' '), ''::text) from subjects where id = ANY(NEW.all_subject_ids))),
   tsv_name = to_tsvector('english'::regconfig, COALESCE(NEW.name, ''::character varying)::text),
   tsv_description = to_tsvector('english'::regconfig, COALESCE(NEW.description, ''::text)),
   tsv_subjects = to_tsvector('english'::regconfig, (SELECT COALESCE(string_agg(name, ' '), ''::text) from subjects where id = ANY(NEW.all_subject_ids)))
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/* create or update triggers */
CREATE TRIGGER on_update_resources_trigger AFTER UPDATE OF name, description, all_subject_ids OR INSERT ON resources FOR EACH ROW EXECUTE PROCEDURE update_resources();
