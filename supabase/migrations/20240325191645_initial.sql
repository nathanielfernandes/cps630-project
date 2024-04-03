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

-- add real time updates
begin;

-- remove the supabase_realtime publication
drop publication if exists supabase_realtime;

-- re-create the supabase_realtime publication with no tables
create publication supabase_realtime;

commit;

-- add a table called 'posts' to the publication
alter publication supabase_realtime
add
    table posts;

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
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handcrafted wooden cutting board', 'condimentum curabitur in libero ut massa volutpat convallis morbi odio odio elementum eu interdum', 19.57, 'items_wanted', 'M5B2K3', '2024-02-04 15:26:58', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Rustic farmhouse sign', 'lacinia erat vestibulum sed magna at nunc commodo placerat praesent blandit nam nulla', 490.84, 'items_for_sale', 'M5B2K3', '2023-05-09 15:02:02', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Retro vinyl record', 'at velit eu est congue elementum in hac habitasse platea dictumst morbi vestibulum velit', 5.15, 'academic_services', 'M5B2K3', '2023-06-09 14:59:08', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-stitched leather journal', 'luctus et ultrices posuere cubilia curae donec pharetra magna vestibulum', 470.52, 'items_wanted', 'M5B2K3', '2023-11-11 05:26:07', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Faux fur throw blanket', 'metus arcu adipiscing molestie hendrerit at vulputate vitae nisl aenean lectus pellentesque eget', 113.8, 'items_for_sale', 'M5B2K3', '2024-03-03 16:35:29', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted ceramic vase', 'eu orci mauris lacinia sapien quis libero nullam sit amet', 509.15, 'academic_services', 'M5B2K3', '2023-08-19 09:35:27', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage leather suitcase', 'et tempus semper est quam pharetra magna ac consequat metus sapien ut nunc vestibulum ante', 587.66, 'items_for_sale', 'M5B2K3', '2024-04-02 00:12:07', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handcrafted wooden cutting board', 'etiam vel augue vestibulum rutrum rutrum neque aenean auctor gravida sem', 193.3, 'items_for_sale', 'M5B2K3', '2023-07-19 10:37:04', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted ceramic vase', 'tincidunt eget tempus vel pede morbi porttitor lorem id ligula suspendisse ornare consequat', 960.51, 'academic_services', 'M5B2K3', '2023-08-14 19:33:21', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Antique silver tea set', 'vel nisl duis ac nibh fusce lacus purus aliquet at feugiat non', 188.26, 'academic_services', 'M5B2K3', '2023-05-06 13:19:02', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage brass candlestick holder', 'suspendisse ornare consequat lectus in est risus auctor sed tristique in tempus sit amet sem', 793.32, 'items_for_sale', 'M5B2K3', '2023-07-27 15:16:37', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted ceramic vase', 'ullamcorper augue a suscipit nulla elit ac nulla sed vel enim sit', 28.08, 'items_for_sale', 'M5B2K3', '2023-10-25 18:51:56', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-stitched leather journal', 'sed vel enim sit amet nunc viverra dapibus nulla suscipit ligula in', 997.93, 'items_for_sale', 'M5B2K3', '2024-02-27 01:50:12', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage silk kimono', 'sodales scelerisque mauris sit amet eros suspendisse accumsan tortor quis turpis sed ante vivamus tortor', 713.47, 'items_for_sale', 'M5B2K3', '2023-07-20 05:32:33', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted porcelain teacup', 'vestibulum rutrum rutrum neque aenean auctor gravida sem praesent id massa', 439.58, 'items_for_sale', 'M5B2K3', '2023-11-03 06:03:27', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Repurposed industrial pendant light', 'vestibulum eget vulputate ut ultrices vel augue vestibulum ante ipsum primis in', 699.85, 'items_for_sale', 'M5B2K3', '2023-05-19 22:57:44', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Rustic farmhouse sign', 'rhoncus aliquet pulvinar sed nisl nunc rhoncus dui vel sem sed', 718.22, 'academic_services', 'M5B2K3', '2023-10-13 04:00:01', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Upcycled denim tote bag', 'molestie sed justo pellentesque viverra pede ac diam cras pellentesque', 298.05, 'items_wanted', 'M5B2K3', '2023-08-27 12:18:57', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Repurposed industrial pendant light', 'lacus at velit vivamus vel nulla eget eros elementum pellentesque quisque', 4.35, 'items_wanted', 'M5B2K3', '2023-04-07 07:10:32', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-painted porcelain teacup', 'ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae nulla dapibus dolor vel', 453.63, 'academic_services', 'M5B2K3', '2023-12-28 09:41:44', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Antique silver tea set', 'integer aliquet massa id lobortis convallis tortor risus dapibus augue vel accumsan tellus nisi', 586.36, 'academic_services', 'M5B2K3', '2023-06-28 23:48:24', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Upcycled metal wall art', 'duis bibendum felis sed interdum venenatis turpis enim blandit mi in', 997.42, 'items_for_sale', 'M5B2K3', '2024-01-20 10:02:46', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Antique silver tea set', 'a libero nam dui proin leo odio porttitor id consequat', 518.44, 'academic_services', 'M5B2K3', '2024-01-31 11:32:14', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-stitched leather journal', 'ipsum ac tellus semper interdum mauris ullamcorper purus sit amet nulla quisque arcu libero', 262.18, 'items_for_sale', 'M5B2K3', '2024-03-26 05:37:29', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handcrafted leather belt', 'pharetra magna ac consequat metus sapien ut nunc vestibulum ante ipsum primis', 891.53, 'items_wanted', 'M5B2K3', '2023-06-17 22:11:07', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Repurposed industrial pendant light', 'orci nullam molestie nibh in lectus pellentesque at nulla suspendisse potenti', 164.05, 'academic_services', 'M5B2K3', '2023-04-25 17:38:29', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Art deco cocktail shaker', 'sit amet erat nulla tempus vivamus in felis eu sapien cursus vestibulum', 417.73, 'items_for_sale', 'M5B2K3', '2024-01-31 11:45:56', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Retro vinyl record', 'sit amet nulla quisque arcu libero rutrum ac lobortis vel dapibus at diam nam', 113.71, 'items_for_sale', 'M5B2K3', '2024-02-21 08:46:15', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage leather suitcase', 'ut ultrices vel augue vestibulum ante ipsum primis in faucibus orci luctus', 180.1, 'items_for_sale', 'M5B2K3', '2024-02-22 22:18:50', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handwoven basket', 'tellus in sagittis dui vel nisl duis ac nibh fusce lacus purus aliquet', 443.41, 'items_for_sale', 'M5B2K3', '2023-07-06 20:22:26', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handwoven straw hat', 'lacinia aenean sit amet justo morbi ut odio cras mi pede malesuada in', 205.75, 'items_for_sale', 'M5B2K3', '2023-12-30 12:06:46', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage leather suitcase', 'ligula nec sem duis aliquam convallis nunc proin at turpis a pede posuere nonummy', 917.92, 'items_wanted', 'M5B2K3', '2023-06-24 20:40:48', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Art deco cocktail shaker', 'eros viverra eget congue eget semper rutrum nulla nunc purus phasellus in felis', 672.28, 'academic_services', 'M5B2K3', '2023-04-21 16:41:35', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Upcycled denim tote bag', 'aenean auctor gravida sem praesent id massa id nisl venenatis', 695.8, 'items_wanted', 'M5B2K3', '2023-11-06 15:28:10', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handmade beaded necklace', 'velit donec diam neque vestibulum eget vulputate ut ultrices vel augue', 444.4, 'items_wanted', 'M5B2K3', '2023-11-04 01:27:44', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Retro sunglasses', 'egestas metus aenean fermentum donec ut mauris eget massa tempor convallis nulla neque', 628.66, 'academic_services', 'M5B2K3', '2023-06-27 05:29:01', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Retro vinyl record', 'rutrum nulla tellus in sagittis dui vel nisl duis ac nibh fusce', 558.35, 'items_for_sale', 'M5B2K3', '2023-12-26 17:45:58', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handcrafted wooden cutting board', 'cras non velit nec nisi vulputate nonummy maecenas tincidunt lacus at velit', 809.54, 'items_wanted', 'M5B2K3', '2023-11-22 06:12:52', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handmade soy wax melts', 'rutrum nulla tellus in sagittis dui vel nisl duis ac nibh fusce', 619.27, 'academic_services', 'M5B2K3', '2023-08-23 11:59:45', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Antique pocket watch', 'tellus semper interdum mauris ullamcorper purus sit amet nulla quisque arcu libero rutrum ac', 74.49, 'items_for_sale', 'M5B2K3', '2023-04-30 13:20:09', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Art deco cocktail shaker', 'integer pede justo lacinia eget tincidunt eget tempus vel pede morbi porttitor lorem id ligula', 928.35, 'items_for_sale', 'M5B2K3', '2023-06-16 16:23:00', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handcrafted wooden cutting board', 'fusce congue diam id ornare imperdiet sapien urna pretium nisl ut volutpat sapien arcu sed', 470.04, 'items_wanted', 'M5B2K3', '2023-05-29 09:58:42', '19c5bfcb-909e-4796-881c-31bcde94be66');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Vintage leather camera strap', 'dapibus dolor vel est donec odio justo sollicitudin ut suscipit a feugiat et eros vestibulum', 162.2, 'items_wanted', 'M5B2K3', '2023-09-27 22:33:23', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Artisanal scented candle', 'felis sed lacus morbi sem mauris laoreet ut rhoncus aliquet pulvinar sed nisl nunc rhoncus', 866.13, 'items_for_sale', 'M5B2K3', '2023-04-05 13:32:07', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Handwoven straw hat', 'blandit nam nulla integer pede justo lacinia eget tincidunt eget', 166.81, 'items_wanted', 'M5B2K3', '2023-06-24 02:17:30', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-carved wooden figurine', 'justo in hac habitasse platea dictumst etiam faucibus cursus urna ut tellus nulla ut', 485.03, 'items_wanted', 'M5B2K3', '2023-04-07 02:43:23', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Repurposed industrial pendant light', 'in purus eu magna vulputate luctus cum sociis natoque penatibus et magnis dis parturient', 624.69, 'items_for_sale', 'M5B2K3', '2023-05-01 21:10:51', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Art deco cocktail shaker', 'ipsum primis in faucibus orci luctus et ultrices posuere cubilia', 991.77, 'academic_services', 'M5B2K3', '2023-11-07 03:02:49', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-dyed silk scarf', 'diam neque vestibulum eget vulputate ut ultrices vel augue vestibulum', 944.63, 'academic_services', 'M5B2K3', '2023-09-30 11:19:25', '02c55b63-a4f5-4b50-8fba-5dbd61a9f291');
insert into public .posts (title, content, price, type, location, created_at, user_id) values ('Hand-dyed silk scarf', 'dolor quis odio consequat varius integer ac leo pellentesque ultrices', 559.68, 'items_wanted', 'M5B2K3', '2024-02-23 09:33:09', '652630e9-a92f-4c3e-ae7a-b74a6fef939d');

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