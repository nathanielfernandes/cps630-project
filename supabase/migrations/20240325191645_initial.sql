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
    role db_role NOT NULL DEFAULT 'user',
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

-- give hizzy admin access
UPDATE
    public .verify
SET
    role = 'admin'
WHERE
    id = 'c2446533-f749-445a-a437-b16dc18c2440';

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
insert into public .posts (title, content, price, type, created_at, user_id) values ('Upcycled metal wall art', 'Nulla ut erat id mauris vulputate elementum. Nullam varius. Nulla facilisi.', 789.51, 'academic_services', '2023-09-24 11:54:24', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Vintage brass candlestick holder', 'Sed ante. Vivamus tortor. Duis mattis egestas metus.', 309.58, 'academic_services', '2024-01-25 11:40:41', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Handmade beaded necklace', 'In congue. Etiam justo. Etiam pretium iaculis justo.', 311.49, 'items_for_sale', '2024-01-25 16:36:02', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Artisanal scented candle', 'Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh.', 630.11, 'academic_services', '2023-09-10 13:16:54', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Hand-dyed silk scarf', 'Aliquam quis turpis eget elit sodales scelerisque. Mauris sit amet eros. Suspendisse accumsan tortor quis turpis.', 691.97, 'academic_services', '2023-07-19 20:59:06', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Handcrafted wooden cutting board', 'Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque.', 163.45, 'items_for_sale', '2023-11-03 06:52:12', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Handcrafted wooden cutting board', 'Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum.', 393.38, 'academic_services', '2023-05-02 01:57:21', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Handwoven straw hat', 'Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum.', 986.68, 'items_for_sale', '2024-03-21 21:51:25', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Upcycled metal wall art', 'Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus.', 498.11, 'items_for_sale', '2023-08-01 11:05:31', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Hand-stitched leather journal', 'Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero.', 282.7, 'academic_services', '2024-01-09 19:13:29', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Upcycled denim tote bag', 'Fusce posuere felis sed lacus. Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl. Nunc rhoncus dui vel sem.', 758.43, 'items_for_sale', '2024-02-18 03:41:22', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Upcycled metal wall art', 'Sed ante. Vivamus tortor. Duis mattis egestas metus.', 368.96, 'items_wanted', '2023-08-22 06:55:56', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Vintage leather camera strap', 'Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo. Morbi ut odio.', 645.73, 'items_wanted', '2024-04-01 15:26:01', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Hand-painted porcelain teacup', 'Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque.', 546.32, 'items_for_sale', '2023-04-09 14:20:28', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Handcrafted wooden cutting board', 'In congue. Etiam justo. Etiam pretium iaculis justo.', 487.91, 'items_for_sale', '2023-11-21 17:26:34', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Antique silver tea set', 'Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat.', 747.36, 'items_wanted', '2023-07-10 20:17:14', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Hand-painted ceramic vase', 'Aenean fermentum. Donec ut mauris eget massa tempor convallis. Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh.', 664.94, 'academic_services', '2023-12-28 10:16:33', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Retro sunglasses', 'In sagittis dui vel nisl. Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus.', 593.77, 'academic_services', '2023-09-04 23:17:31', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Vintage leather camera strap', 'Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem.', 308.81, 'academic_services', '2023-07-28 19:38:21', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Vintage brass candlestick holder', 'Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim. Lorem ipsum dolor sit amet, consectetuer adipiscing elit.', 757.24, 'items_for_sale', '2023-09-13 04:37:38', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Art deco cocktail shaker', 'Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.', 474.98, 'items_for_sale', '2024-01-08 01:45:50', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Handwoven basket', 'Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus.', 269.76, 'academic_services', '2023-11-29 08:49:05', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Handmade soy wax melts', 'Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus. Duis at velit eu est congue elementum.', 915.29, 'items_for_sale', '2023-06-08 10:30:00', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Vintage leather suitcase', 'Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui.', 483.13, 'items_for_sale', '2023-06-28 21:11:38', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Artisanal scented candle', 'Nullam sit amet turpis elementum ligula vehicula consequat. Morbi a ipsum. Integer a nibh.', 662.19, 'academic_services', '2023-11-12 21:30:06', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Art deco cocktail shaker', 'Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat.', 145.67, 'academic_services', '2023-12-17 18:56:07', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Vintage leather suitcase', 'Aenean lectus. Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum.', 568.55, 'items_wanted', '2024-01-14 06:51:35', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Hand-carved wooden figurine', 'In quis justo. Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet.', 686.53, 'items_wanted', '2023-06-19 15:36:55', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Handwoven basket', 'Etiam vel augue. Vestibulum rutrum rutrum neque. Aenean auctor gravida sem.', 312.77, 'items_wanted', '2024-01-13 14:43:23', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, created_at, user_id) values ('Handmade macrame plant hanger', 'Morbi non lectus. Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.', 534.82, 'items_wanted', '2023-05-03 05:44:13', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');

-- TEST DATA IMAGES TABLE
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'quam pharetra magna', 1);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'dui vel nisl', 2);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/334438_monke.png', 'in quis justo maecenas', 3);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'integer tincidunt', 4);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'vel nisl', 5);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'at turpis a pede', 6);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'orci luctus et ultrices', 7);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'nulla dapibus dolor vel', 8);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'est risus auctor sed', 9);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'ipsum aliquam', 10);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'non lectus aliquam', 11);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'cubilia curae', 12);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'pede lobortis ligula sit', 13);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'integer tincidunt ante', 14);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'eros vestibulum', 15);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'metus aenean fermentum', 16);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'lorem quisque ut erat', 17);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'sapien quis libero nullam', 18);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'hac habitasse platea dictumst', 19);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'amet consectetuer adipiscing', 20);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'montes nascetur ridiculus mus', 21);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/334438_monke.png', 'morbi quis', 22);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'ac diam', 23);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'nulla neque libero convallis', 24);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/334438_monke.png', 'integer aliquet', 25);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'magnis dis parturient montes', 26);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'tristique fusce congue diam', 27);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'venenatis non', 28);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'lorem vitae mattis', 29);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/215991272_hat.png', 'scelerisque quam turpis', 30);

insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'cras in', 1);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'ultrices enim', 2);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'quis odio consequat', 3);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'nec molestie', 4);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'proin risus', 5);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'amet consectetuer', 6);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/215991272_hat.png', 'sed nisl nunc', 7);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'turpis sed ante vivamus', 8);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'magnis dis', 9);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'fringilla rhoncus mauris', 10);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'rhoncus aliquet', 11);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'leo rhoncus sed vestibulum', 12);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/334438_monke.png', 'mauris lacinia sapien', 13);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/215991272_hat.png', 'luctus ultricies eu nibh', 14);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'curae nulla dapibus', 15);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'enim blandit mi', 16);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'platea dictumst', 17);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'nibh in hac habitasse', 18);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/215991272_hat.png', 'justo lacinia', 19);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'nam tristique tortor eu', 20);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'augue quam sollicitudin', 21);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'vel dapibus', 22);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'vel augue vestibulum rutrum', 23);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/334438_monke.png', 'volutpat quam', 24);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'ridiculus mus etiam', 25);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'accumsan tellus nisi', 26);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'felis eu sapien', 27);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/215991272_hat.png', 'erat quisque erat eros', 28);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'tortor duis', 29);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/334438_monke.png', 'luctus cum', 30);