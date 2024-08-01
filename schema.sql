CREATE TABLE IF NOT EXISTS produtos (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    preco NUMERIC NOT NULL,
    estoque INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS audit (
    id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    operation TEXT NOT NULL,
    operation_timestamp TIMESTAMPTZ NOT NULL
);

CREATE OR REPLACE FUNCTION validar_preco() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.preco <= 0 THEN
        RAISE EXCEPTION 'O preço deve ser maior que zero.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_validar_preco
BEFORE INSERT OR UPDATE ON produtos
FOR EACH ROW EXECUTE FUNCTION validar_preco();

CREATE OR REPLACE FUNCTION validar_estoque() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.estoque < 0 THEN
        RAISE EXCEPTION 'O estoque não pode ser negativo.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_validar_estoque
BEFORE INSERT OR UPDATE ON produtos
FOR EACH ROW EXECUTE FUNCTION validar_estoque();

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION notify_trigger() RETURNS trigger AS $$
DECLARE
  rec produtos;
  dat produtos;
  payload TEXT;
BEGIN

  -- Set record row depending on operation
  CASE TG_OP
  WHEN 'UPDATE' THEN
     rec := NEW;
     dat := OLD;
  WHEN 'INSERT' THEN
     rec := NEW;
  WHEN 'DELETE' THEN
     rec := OLD;
  ELSE
     RAISE EXCEPTION 'Unknown TG_OP: "%". Should not occur!', TG_OP;
  END CASE;

  -- Build the payload
  payload := json_build_object('timestamp', CURRENT_TIMESTAMP,
                                'action', LOWER(TG_OP),
                                'db_schema', TG_TABLE_SCHEMA,
                                'table', TG_TABLE_NAME,
                                'record', row_to_json(rec), 
                                'old',row_to_json(dat));

  -- Notify the channel
  PERFORM pg_notify('db_event', payload);

  RETURN rec;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER product_notify AFTER INSERT OR UPDATE OR DELETE 
ON produtos
FOR EACH ROW EXECUTE PROCEDURE notify_trigger();

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION audit_log() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit (table_name, operation, operation_timestamp)
    VALUES (TG_TABLE_NAME, TG_OP, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER audit_trigger_produtos
AFTER INSERT OR UPDATE OR DELETE ON produtos
FOR EACH ROW EXECUTE FUNCTION audit_log();
