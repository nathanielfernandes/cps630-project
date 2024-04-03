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
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted porcelain teacup', 'vestibulum eget vulputate ut ultrices vel augue vestibulum ante ipsum', 341.72, 'academic_services', 'M5R 6h9', '2023-06-05 18:46:58', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Repurposed industrial pendant light', 'integer ac leo pellentesque ultrices mattis odio donec vitae nisi nam ultrices libero non', 557.84, 'items_for_sale', 'M5R 3V8', '2024-01-22 21:37:12', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handmade beaded necklace', 'morbi porttitor lorem id ligula suspendisse ornare consequat lectus in est risus auctor sed tristique', 523.08, 'items_for_sale', 'M5R 8q5', '2024-03-06 11:48:46', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage record player', 'cum sociis natoque penatibus et magnis dis parturient montes nascetur ridiculus mus vivamus vestibulum sagittis', 308.84, 'items_for_sale', 'M5R 7x4', '2024-02-04 11:38:05', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Faux fur throw blanket', 'nullam sit amet turpis elementum ligula vehicula consequat morbi a ipsum integer a nibh in', 348.58, 'items_wanted', 'M5R 2i3', '2023-07-24 00:23:18', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage record player', 'nec nisi vulputate nonummy maecenas tincidunt lacus at velit vivamus vel', 769.27, 'items_wanted', 'M5R 8i6', '2023-12-29 20:23:53', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handcrafted leather belt', 'congue diam id ornare imperdiet sapien urna pretium nisl ut', 722.49, 'academic_services', 'M5R 8D7', '2023-08-03 01:14:14', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Retro vinyl record', 'duis bibendum morbi non quam nec dui luctus rutrum nulla tellus', 707.06, 'academic_services', 'M5R 3j8', '2024-01-04 11:01:48', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage brass candlestick holder', 'risus dapibus augue vel accumsan tellus nisi eu orci mauris', 266.65, 'items_for_sale', 'M5R 5U1', '2024-03-25 10:00:57', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage leather camera strap', 'placerat praesent blandit nam nulla integer pede justo lacinia eget', 570.83, 'academic_services', 'M5R 4h0', '2023-12-29 08:46:26', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Upcycled denim tote bag', 'sapien ut nunc vestibulum ante ipsum primis in faucibus orci', 568.22, 'items_wanted', 'M5R 1B3', '2023-05-28 04:23:35', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage brass candlestick holder', 'orci eget orci vehicula condimentum curabitur in libero ut massa volutpat convallis morbi odio', 347.6, 'items_wanted', 'M5R 0c2', '2024-02-04 04:49:34', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-dyed silk scarf', 'elit proin interdum mauris non ligula pellentesque ultrices phasellus id sapien in', 743.57, 'academic_services', 'M5R 5T5', '2023-06-10 19:19:42', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Retro sunglasses', 'justo etiam pretium iaculis justo in hac habitasse platea dictumst etiam faucibus cursus urna ut', 120.67, 'items_wanted', 'M5R 3x9', '2024-03-06 15:43:57', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Faux fur throw blanket', 'congue vivamus metus arcu adipiscing molestie hendrerit at vulputate vitae nisl aenean lectus pellentesque', 938.56, 'items_for_sale', 'M5R 4j6', '2024-02-22 01:26:22', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Art deco cocktail shaker', 'id pretium iaculis diam erat fermentum justo nec condimentum neque sapien placerat ante nulla', 9.09, 'items_wanted', 'M5R 2g7', '2023-09-19 19:37:50', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted ceramic vase', 'pellentesque eget nunc donec quis orci eget orci vehicula condimentum curabitur in libero ut massa', 840.43, 'items_for_sale', 'M5R 6F8', '2023-10-17 07:35:00', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Rustic farmhouse sign', 'pretium iaculis justo in hac habitasse platea dictumst etiam faucibus cursus urna ut tellus nulla', 841.81, 'items_wanted', 'M5R 6F9', '2023-04-21 11:01:07', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Upcycled metal wall art', 'est risus auctor sed tristique in tempus sit amet sem fusce consequat nulla nisl nunc', 591.52, 'items_for_sale', 'M5R 0b8', '2023-11-02 13:58:40', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handcrafted leather belt', 'viverra eget congue eget semper rutrum nulla nunc purus phasellus in felis', 54.86, 'academic_services', 'M5R 8E4', '2023-08-01 10:01:47', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Rustic farmhouse sign', 'etiam vel augue vestibulum rutrum rutrum neque aenean auctor gravida sem praesent', 387.23, 'academic_services', 'M5R 2R0', '2023-09-19 03:04:19', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Repurposed industrial pendant light', 'eget tincidunt eget tempus vel pede morbi porttitor lorem id ligula suspendisse ornare', 534.76, 'academic_services', 'M5R 0z3', '2023-06-03 03:51:42', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage record player', 'interdum mauris non ligula pellentesque ultrices phasellus id sapien in sapien iaculis congue', 899.34, 'items_wanted', 'M5R 3a3', '2024-01-23 15:52:37', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Upcycled metal wall art', 'etiam vel augue vestibulum rutrum rutrum neque aenean auctor gravida sem praesent id', 866.09, 'academic_services', 'M5R 1Z3', '2023-08-25 02:25:47', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Upcycled metal wall art', 'pulvinar lobortis est phasellus sit amet erat nulla tempus vivamus in felis eu sapien cursus', 429.27, 'items_wanted', 'M5R 8e5', '2024-01-04 17:30:53', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-dyed silk scarf', 'est lacinia nisi venenatis tristique fusce congue diam id ornare imperdiet', 818.68, 'academic_services', 'M5R 1x0', '2023-06-11 16:15:05', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted ceramic vase', 'at nunc commodo placerat praesent blandit nam nulla integer pede justo lacinia eget tincidunt', 393.33, 'academic_services', 'M5R 8c5', '2023-07-02 14:32:53', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage silk kimono', 'erat nulla tempus vivamus in felis eu sapien cursus vestibulum proin', 299.48, 'items_wanted', 'M5R 7k3', '2024-02-01 03:42:45', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage record player', 'duis ac nibh fusce lacus purus aliquet at feugiat non pretium', 171.38, 'items_for_sale', 'M5R 3v4', '2023-09-02 21:07:41', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handwoven basket', 'at turpis a pede posuere nonummy integer non velit donec diam neque vestibulum', 284.43, 'items_for_sale', 'M5R 8a5', '2023-06-23 17:22:09', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage leather suitcase', 'mauris laoreet ut rhoncus aliquet pulvinar sed nisl nunc rhoncus dui vel sem sed', 988.71, 'academic_services', 'M5R 2b1', '2023-06-28 13:57:39', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Upcycled denim tote bag', 'rhoncus sed vestibulum sit amet cursus id turpis integer aliquet massa id lobortis convallis tortor', 975.4, 'academic_services', 'M5R 1l6', '2024-03-08 02:10:05', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted porcelain teacup', 'est et tempus semper est quam pharetra magna ac consequat metus sapien', 76.43, 'items_for_sale', 'M5R 2F8', '2023-06-10 22:47:54', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handcrafted leather belt', 'donec ut dolor morbi vel lectus in quam fringilla rhoncus', 601.64, 'items_wanted', 'M5R 8s3', '2023-10-10 12:45:54', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handwoven basket', 'vulputate luctus cum sociis natoque penatibus et magnis dis parturient montes nascetur ridiculus', 449.06, 'items_wanted', 'M5R 1t3', '2023-08-15 19:04:02', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handcrafted wooden cutting board', 'nulla ut erat id mauris vulputate elementum nullam varius nulla', 439.12, 'academic_services', 'M5R 6w0', '2023-05-03 19:28:17', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handcrafted leather belt', 'molestie nibh in lectus pellentesque at nulla suspendisse potenti cras in', 508.3, 'items_wanted', 'M5R 1W7', '2023-07-09 06:49:51', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handmade macrame plant hanger', 'amet nulla quisque arcu libero rutrum ac lobortis vel dapibus at diam nam', 322.69, 'items_for_sale', 'M5R 7p5', '2023-07-13 04:36:29', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Upcycled metal wall art', 'sollicitudin ut suscipit a feugiat et eros vestibulum ac est lacinia nisi venenatis', 413.93, 'items_wanted', 'M5R 1q7', '2023-11-09 08:59:10', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Faux fur throw blanket', 'aliquet ultrices erat tortor sollicitudin mi sit amet lobortis sapien sapien non', 78.91, 'academic_services', 'M5R 9S6', '2024-03-27 19:59:56', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handmade soy wax melts', 'in tempor turpis nec euismod scelerisque quam turpis adipiscing lorem vitae', 397.25, 'items_wanted', 'M5R 0K2', '2023-04-24 02:51:35', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted porcelain teacup', 'nisi nam ultrices libero non mattis pulvinar nulla pede ullamcorper augue a', 300.65, 'items_wanted', 'M5R 9S1', '2023-07-24 21:05:13', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-stitched leather journal', 'ultrices posuere cubilia curae mauris viverra diam vitae quam suspendisse', 496.45, 'academic_services', 'M5R 2D5', '2024-03-31 11:57:14', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Repurposed industrial pendant light', 'vel lectus in quam fringilla rhoncus mauris enim leo rhoncus sed vestibulum sit', 940.54, 'academic_services', 'M5R 7Y0', '2023-08-28 17:13:03', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Art deco cocktail shaker', 'nulla facilisi cras non velit nec nisi vulputate nonummy maecenas', 484.74, 'academic_services', 'M5R 1b6', '2024-03-29 20:04:41', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-carved wooden figurine', 'vel ipsum praesent blandit lacinia erat vestibulum sed magna at nunc commodo placerat praesent blandit', 683.94, 'academic_services', 'M5R 7H0', '2023-04-29 18:29:16', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted porcelain teacup', 'accumsan felis ut at dolor quis odio consequat varius integer ac', 757.4, 'items_for_sale', 'M5R 3j7', '2023-10-26 03:01:57', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted ceramic vase', 'vestibulum velit id pretium iaculis diam erat fermentum justo nec condimentum neque sapien placerat ante', 850.29, 'items_wanted', 'M5R 3x2', '2023-05-11 00:58:11', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handmade pottery mug', 'consectetuer adipiscing elit proin interdum mauris non ligula pellentesque ultrices phasellus id sapien in sapien', 97.73, 'academic_services', 'M5R 7k7', '2023-08-22 05:49:33', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted ceramic vase', 'in eleifend quam a odio in hac habitasse platea dictumst maecenas', 760.54, 'items_for_sale', 'M5R 1u8', '2023-11-01 04:59:43', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');

-- TEST DATA IMAGES TABLE
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'sodales sed tincidunt', 1);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'justo eu massa donec', 2);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'tincidunt eu', 3);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/704056b9-c45f-4731-a150-a43d99d9164e/151436_pngtree-kawaii-little-kitten-picture-image_2777072.jpg', 'nulla elit', 4);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'ut rhoncus aliquet pulvinar', 5);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'eget rutrum at', 6);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'nunc purus phasellus in', 7);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'in faucibus', 8);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'hac habitasse platea', 9);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/704056b9-c45f-4731-a150-a43d99d9164e/151436_pngtree-kawaii-little-kitten-picture-image_2777072.jpg', 'gravida nisi at', 10);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'neque libero', 11);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/704056b9-c45f-4731-a150-a43d99d9164e/151436_pngtree-kawaii-little-kitten-picture-image_2777072.jpg', 'nulla tempus vivamus', 12);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/215991272_hat.png', 'vestibulum ante', 13);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'vivamus vestibulum', 14);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'sapien arcu sed', 15);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/101010_kitten-cat.gif', 'fusce posuere felis', 16);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'scelerisque quam turpis', 17);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/215991272_hat.png', 'sapien quis libero nullam', 18);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'in leo maecenas pulvinar', 19);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'duis bibendum', 20);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'metus arcu', 21);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/215991272_hat.png', 'maecenas leo odio', 22);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'tellus in sagittis', 23);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'justo lacinia', 24);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'eu est', 25);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/704056b9-c45f-4731-a150-a43d99d9164e/151436_pngtree-kawaii-little-kitten-picture-image_2777072.jpg', 'ultrices mattis', 26);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'nulla tempus', 27);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'justo maecenas rhoncus aliquam', 28);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'a feugiat', 29);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'vestibulum ante ipsum', 30);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'tellus nulla ut', 31);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'convallis eget eleifend', 32);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'venenatis turpis enim', 33);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'vulputate justo in', 34);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'nulla pede', 35);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'nulla ultrices aliquet', 36);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'pulvinar lobortis est', 37);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'lectus vestibulum quam sapien', 38);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'magna bibendum imperdiet', 39);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/704056b9-c45f-4731-a150-a43d99d9164e/151436_pngtree-kawaii-little-kitten-picture-image_2777072.jpg', 'lacus at velit vivamus', 40);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'ut at', 41);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'leo rhoncus sed vestibulum', 42);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'nulla nisl nunc nisl', 43);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'in libero ut', 44);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'amet eleifend', 45);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/704056b9-c45f-4731-a150-a43d99d9164e/151436_pngtree-kawaii-little-kitten-picture-image_2777072.jpg', 'nunc commodo placerat praesent', 46);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'a suscipit nulla elit', 47);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'nec molestie', 48);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'lectus suspendisse potenti in', 49);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'elementum nullam varius', 50);

insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/704056b9-c45f-4731-a150-a43d99d9164e/151436_pngtree-kawaii-little-kitten-picture-image_2777072.jpg', 'erat curabitur gravida', 1);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'venenatis lacinia aenean sit', 2);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/101010_kitten-cat.gif', 'nisl nunc rhoncus', 3);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'pede ac', 4);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'ut at dolor quis', 5);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/334438_monke.png', 'erat eros viverra', 6);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/101010_kitten-cat.gif', 'aliquet maecenas leo', 7);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'platea dictumst etiam faucibus', 8);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/704056b9-c45f-4731-a150-a43d99d9164e/151436_pngtree-kawaii-little-kitten-picture-image_2777072.jpg', 'nulla sed', 9);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'mauris viverra diam vitae', 10);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/101010_kitten-cat.gif', 'tincidunt nulla mollis', 11);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'parturient montes', 12);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/101010_kitten-cat.gif', 'cubilia curae duis', 13);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'pellentesque quisque porta', 14);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'imperdiet nullam orci', 15);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'in lacus', 16);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'nulla ultrices', 17);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'curae mauris viverra', 18);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'arcu libero', 19);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'est et tempus', 20);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/334438_monke.png', 'lorem vitae', 21);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/101010_kitten-cat.gif', 'convallis eget eleifend', 22);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/121476_otter2.jpg', 'massa id nisl venenatis', 23);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'leo odio', 24);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/704056b9-c45f-4731-a150-a43d99d9164e/151436_pngtree-kawaii-little-kitten-picture-image_2777072.jpg', 'nisl venenatis', 25);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'donec dapibus duis at', 26);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/215991272_hat.png', 'purus sit amet nulla', 27);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'gravida nisi', 28);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'justo sit', 29);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'nulla mollis molestie lorem', 30);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'ante ipsum primis in', 31);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/334438_monke.png', 'quisque erat eros viverra', 32);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'proin eu mi', 33);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'mattis pulvinar nulla pede', 34);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'tellus nisi eu', 35);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'non ligula', 36);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'nisl duis ac nibh', 37);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/320334_otter.jpg', 'justo pellentesque', 38);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/682113145606_cat1.jpg', 'in felis donec semper', 39);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/101010_kitten-cat.gif', 'dui maecenas tristique est', 40);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/137927_otter3.jpg', 'tempus vivamus in felis', 41);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/278168_otter4.jpg', 'congue risus semper', 42);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/704056b9-c45f-4731-a150-a43d99d9164e/151436_pngtree-kawaii-little-kitten-picture-image_2777072.jpg', 'volutpat in', 43);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/415201_Screen%20Shot%202024-02-07%20at%201.53.41%20PM.png', 'nulla eget', 44);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'sociis natoque', 45);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/606328911924_cat3.jpg', 'pulvinar lobortis est phasellus', 46);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'venenatis tristique fusce congue', 47);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/652630e9-a92f-4c3e-ae7a-b74a6fef939d/173670_silly_monkey.jpg', 'leo odio condimentum id', 48);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'luctus rutrum', 49);
insert into public .images (link, alt_text, post_id) values ('https://wduwhfiooshcbzbgenyy.supabase.co/storage/v1/object/public/images/uploads/ec82ea34-0100-4bf7-a637-015fbbf50c94/828993018656_cat2.jpg', 'magna vulputate', 50);