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
    location VARCHAR(255) NOT NULL DEFAULT 'Toronto Metropolitan University',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_id UUID NOT NULL REFERENCES auth.users(id),
    email VARCHAR(255) NOT NULL DEFAULT 'no-email'
);

ALTER TABLE
    posts ENABLE ROW LEVEL SECURITY;

-- trigger that sets the email of the post to the email of the user
CREATE FUNCTION public .set_post_email() RETURNS TRIGGER LANGUAGE PLPGSQL SECURITY DEFINER
set
    search_path = public AS $$ BEGIN
        NEW .email = (
            SELECT
                email
            FROM
                auth.users
            WHERE
                id = NEW .user_id
        );

RETURN NEW;

END;

$$;

CREATE TRIGGER set_post_email_trigger BEFORE
INSERT
    ON posts FOR EACH ROW EXECUTE PROCEDURE public .set_post_email();

UPDATE
    posts
SET
    email = (
        SELECT
            email
        FROM
            auth.users
        WHERE
            id = user_id
    );

-- allow anyone to read all posts
CREATE POLICY "Read All Posts" ON posts FOR
SELECT
    USING (true);

CREATE POLICY "Read All Posts Anon" ON posts FOR
SELECT
    to anon USING (true);

-- allow users to create posts
CREATE POLICY "Create Post" ON posts FOR
INSERT
    to authenticated WITH CHECK (auth.uid() = user_id);

-- allow users to update their own posts
CREATE POLICY "Update Own Post" ON posts FOR
UPDATE
    USING (auth.uid() = user_id);

-- allow users to delete their own posts
CREATE POLICY "Delete Own Post" ON posts FOR
DELETE
    USING (auth.uid() = user_id);

CREATE TABLE images (
    id BIGSERIAL PRIMARY KEY NOT NULL,
    link VARCHAR(255) NOT NULL,
    alt_text VARCHAR(255) NOT NULL DEFAULT 'no-alt-text',
    post_id BIGINT NOT NULL REFERENCES posts(id)
);

CREATE TYPE db_role AS ENUM ('admin', 'user');

CREATE TABLE verify (
    id UUID NOT NULL REFERENCES auth.users(id),
    email VARCHAR(255) NOT NULL,
    type db_role NOT NULL DEFAULT 'user',
    secret UUID NOT NULL DEFAULT gen_random_uuid()
);

ALTER TABLE
    verify ENABLE ROW LEVEL SECURITY;

CREATE TABLE user_info (
    id UUID NOT NULL PRIMARY KEY REFERENCES auth.users(id),
    email VARCHAR(255) NOT NULL
);

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

CREATE FUNCTION public .create_user_info_row() RETURNS TRIGGER LANGUAGE PLPGSQL SECURITY DEFINER
set
    search_path = public AS $$ BEGIN
        INSERT INTO
            public .user_info (id, email)
        VALUES
            (NEW .id, NEW .email);

RETURN NEW;

END;

$$;

CREATE TRIGGER create_verify_row_trigger AFTER
INSERT
    ON auth.users FOR EACH ROW EXECUTE PROCEDURE public .create_verify_row();

CREATE TRIGGER create_user_info_row_trigger AFTER
INSERT
    ON auth.users FOR EACH ROW EXECUTE PROCEDURE public .create_user_info_row();

-- read the auth.users and generate a new verify row
INSERT INTO
    public .verify (id, email)
SELECT
    id,
    email
FROM
    auth.users;

INSERT INTO
    public .user_info (id, email)
SELECT
    id,
    email
FROM
    auth.users;

CREATE POLICY "Give users access to own folder READ" ON storage.objects FOR
SELECT
    TO authenticated USING (
        bucket_id = 'images'
        AND (storage.foldername(name)) [ 1 ] = 'uploads'
        AND auth.uid() :: text = (storage.foldername(name)) [ 2 ]
    );

CREATE POLICY "Give users access to own folder WRITE" ON storage.objects FOR
INSERT
    TO authenticated WITH CHECK (
        bucket_id = 'images'
        AND (storage.foldername(name)) [ 1 ] = 'uploads'
        AND auth.uid() :: text = (storage.foldername(name)) [ 2 ]
    );

CREATE POLICY "Give users access to own folder EDIT" ON storage.objects FOR
UPDATE
    TO authenticated USING (
        bucket_id = 'images'
        AND (storage.foldername(name)) [ 1 ] = 'uploads'
        AND auth.uid() :: text = (storage.foldername(name)) [ 2 ]
    );

CREATE POLICY "Give users access to own folder DELETE" ON storage.objects FOR
DELETE
    TO authenticated USING (
        bucket_id = 'images'
        AND (storage.foldername(name)) [ 1 ] = 'uploads'
        AND auth.uid() :: text = (storage.foldername(name)) [ 2 ]
    );

-- TEST DATA POSTS TABLE
INSERT INTO
    public .posts (
        title,
        content,
        price,
        type,
        location,
        created_at,
        user_id
    )
VALUES
    (
        'hmm',
        'hmmmm',
        0.0,
        'items_wanted',
        'M5B2K3',
        '2024-03-30 15:57:57.350193',
        '02c55b63-a4f5-4b50-8fba-5dbd61a9f291'
    ),
    (
        'hmm',
        'hmmmm',
        10.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-30 16:59:37.589435',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'hmm',
        'hmmmm',
        10.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-30 16:59:49.462681',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'hello',
        'hmm',
        10.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-30 17:00:08.622948',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'hello',
        'hmm',
        10.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-30 17:00:20.07774',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'hmm',
        'hmmmm',
        1.0,
        'academic_services',
        'M5B2K3',
        '2024-03-30 17:01:39.296192',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'Hmm',
        'Hello',
        10.0,
        'academic_services',
        'M5B2K3',
        '2024-03-30 18:16:10.167332',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'hmm',
        'hmmmm',
        10.0,
        'items_wanted',
        'M5B2K3',
        '2024-03-30 18:30:02.017138',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'dsnkjsldbnf',
        'dsfsdf',
        5.0,
        'academic_services',
        'M5B2K3',
        '2024-03-30 18:30:18.110973',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'yaba',
        'yabbbababa',
        10.0,
        'items_wanted',
        'M5B2K3',
        '2024-03-30 18:45:01.359439',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'dfskjfnsdlkjf',
        'hmm',
        5.0,
        'academic_services',
        'M5B2K3',
        '2024-03-30 18:45:13.823914',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'uhhh',
        'ok',
        3.0,
        'items_wanted',
        'M5B2K3',
        '2024-03-31 16:13:27.458704',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'hmmmm',
        'kdnfksnk',
        10.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 16:23:24.840396',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'uhhh',
        'fkdflsd',
        100.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 16:35:37.751855',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'hmm',
        'okokok',
        10.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 16:40:38.091172',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'hmm',
        'okokok',
        10.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 16:41:11.462416',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'hmm',
        'ok yabba',
        300.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 16:57:35.45285',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'uhhhhh',
        'hmmmm',
        10.0,
        'items_wanted',
        'M5B2K3',
        '2024-03-31 17:01:58.568661',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'funny raccoon',
        'worth a lot',
        1000.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 17:06:10.307962',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'funny monkey',
        'not a monkey',
        1000.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 17:07:59.684974',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'funny monkey',
        'not a monkey',
        1000.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 17:08:34.023317',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'fix my code',
        'please its bad',
        10.0,
        'items_wanted',
        'M5B2K3',
        '2024-03-31 17:44:10.688446',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'hello',
        'hmm',
        10.0,
        'items_wanted',
        'M5B2K3',
        '2024-03-31 17:46:37.088214',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'Funny monkey',
        'monkey so cute',
        100000.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 17:55:43.58597',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'monkey',
        'uhh',
        10.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 17:56:48.433654',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'want this monkey',
        'pleaseee',
        10000.0,
        'items_wanted',
        'M5B2K3',
        '2024-03-31 18:00:13.705056',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'want the monkey',
        'uhh',
        10.0,
        'items_wanted',
        'M5B2K3',
        '2024-03-31 18:00:48.875862',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'need this monkey',
        'need it now',
        5.0,
        'items_wanted',
        'M5B2K3',
        '2024-03-31 18:12:19.33443',
        '652630e9-a92f-4c3e-ae7a-b74a6fef939d'
    ),
    (
        'Test',
        'Test',
        10.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 22:32:17.254343',
        '19c5bfcb-909e-4796-881c-31bcde94be66'
    ),
    (
        'Hi',
        'asdasd',
        10.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 22:33:44.160691',
        '19c5bfcb-909e-4796-881c-31bcde94be66'
    ),
    (
        'asdasd',
        'asdasd',
        1211.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 22:35:37.892555',
        '19c5bfcb-909e-4796-881c-31bcde94be66'
    ),
    (
        'Test',
        'test',
        123.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 22:37:18.811335',
        '19c5bfcb-909e-4796-881c-31bcde94be66'
    ),
    (
        'asdasdasd',
        'asdasdasdasd',
        1231.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 22:41:37.487189',
        '19c5bfcb-909e-4796-881c-31bcde94be66'
    ),
    (
        'asdasdasd',
        'sadasdads',
        1231.0,
        'items_for_sale',
        'M5B2K3',
        '2024-03-31 22:47:02.067131',
        '19c5bfcb-909e-4796-881c-31bcde94be66'
    );

-- TEST DATA IMAGES TABLE
INSERT INTO
    public .images (
        link,
        alt_text,
        post_id
    )
VALUES
    (
        'https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads%2F652630e9-a92f-4c3e-ae7a-b74a6fef939d%2F334438_monke.png',
        'silly monkey',
        1
    ),
    (
        'https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads%2F652630e9-a92f-4c3e-ae7a-b74a6fef939d%2F334438_monke.png',
        'silly monkey',
        2
    ),
    (
        'https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads%2F652630e9-a92f-4c3e-ae7a-b74a6fef939d%2F334438_monke.png',
        'silly monkey',
        11
    ),
    (
        'https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads%2F652630e9-a92f-4c3e-ae7a-b74a6fef939d%2F334438_monke.png',
        'silly monkey',
        20
    );