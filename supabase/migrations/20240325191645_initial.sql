-- Add up migration script here
CREATE TYPE post_type AS ENUM (
    'items_for_sale',
    'items_wanted',
    'academic_services'
);

CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY NOT NULL,
    title VARCHAR(255) NOT NULL DEFAULT 'no-title',
    content VARCHAR(255) NOT NULL DEFAULT 'no-content',
    price NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (price >= 0),
    type post_type NOT NULL DEFAULT 'items_for_sale',
    location VARCHAR(255) NOT NULL DEFAULT 'no-location',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id UUID NOT NULL REFERENCES auth.users(id)
);

ALTER TABLE
    posts ENABLE ROW LEVEL SECURITY;

CREATE TABLE images (
    id BIGSERIAL PRIMARY KEY NOT NULL,
    link VARCHAR(255) NOT NULL,
    alt_text VARCHAR(255) NOT NULL DEFAULT 'no-alt-text',
    post_id BIGINT NOT NULL REFERENCES posts(id)
);

CREATE TABLE verify (
    id UUID NOT NULL REFERENCES auth.users(id),
    email VARCHAR(255) NOT NULL,
    secret UUID NOT NULL DEFAULT gen_random_uuid()
);

ALTER TABLE
    verify ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Read Own Secret" ON verify FOR
SELECT
    USING (auth.uid() = id);

-- triger whenever a new user is created, a new verify row is created
CREATE FUNCTION public .create_verify_row() RETURNS TRIGGER LANGUAGE PLPGSQL SECURITY DEFINER
set
    search_path = public AS $$ BEGIN
        INSERT INTO
            public .verify (id, email)
        VALUES
            (NEW .id, NEW .email);

RETURN NEW;

END;

$$;

CREATE TRIGGER create_verify_row_trigger AFTER
INSERT
    ON auth.users FOR EACH ROW EXECUTE PROCEDURE public .create_verify_row();

-- read the auth.users and generate a new verify row
INSERT INTO
    public .verify (id, email)
SELECT
    id,
    email
FROM
    auth.users;