-- ==============================================================================
-- AgriConnect Farm-to-Market Platform with Mobile Money Wallet
-- Phase 3: Comprehensive Seed Data Script
-- Includes:
--   - 17 Towns across Central, Eastern, Western, and Northern Uganda
--   - 50 Realistic Users (Farmers, Buyers, Dual-role) with Ugandan phone numbers
--   - 50 Wallets with active seed balances (500,000 to 5,000,000 UGX)
--   - 100 Realistic Agricultural Products across all 6 categories
--   - 30 Past Orders across statuses (DELIVERED, DISPATCHED, PAID, PENDING, CANCELLED)
--   - 60+ Order Items with historical frozen unit prices
--   - 30 Deliveries with real timestamps and drivers
--   - 30 Verified Buyer Reviews (ratings 1 to 5)
--   - Complete Initial Wallet Transaction history (CASH_IN, PAYMENT, RECEIPT)
-- ==============================================================================

USE agriconnect;

-- Clear previous test data in reverse FK order
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE reviews;
TRUNCATE TABLE deliveries;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE products;
TRUNCATE TABLE wallet_txns;
TRUNCATE TABLE wallets;
TRUNCATE TABLE users;
TRUNCATE TABLE towns;
SET FOREIGN_KEY_CHECKS = 1;

-- ------------------------------------------------------------------------------
-- 1. TOWNS (17 Ugandan Major Agricultural Hubs & Markets)
-- ------------------------------------------------------------------------------
INSERT INTO towns (town_id, town_name, district) VALUES
(1,  'Kampala Central',   'Kampala'),
(2,  'Mbale City',        'Mbale'),
(3,  'Mbarara City',      'Mbarara'),
(4,  'Gulu City',         'Gulu'),
(5,  'Jinja City',        'Jinja'),
(6,  'Masaka City',       'Masaka'),
(7,  'Fort Portal City',  'Kabarole'),
(8,  'Kasese Municipality','Kasese'),
(9,  'Soroti City',       'Soroti'),
(10, 'Arua City',         'Arua'),
(11, 'Lira City',         'Lira'),
(12, 'Kabale Municipality','Kabale'),
(13, 'Mukono Municipality','Mukono'),
(14, 'Wakiso Town',       'Wakiso'),
(15, 'Tororo Municipality','Tororo'),
(16, 'Kayunga Town',      'Kayunga'),
(17, 'Entebbe Municipality','Wakiso');

-- ------------------------------------------------------------------------------
-- 2. USERS (50 Users: Farmers, Buyers, and Dual-Role Traders)
-- ------------------------------------------------------------------------------
INSERT INTO users (user_id, full_name, phone, email, role, town_id) VALUES
-- Farmers & Dual-Role (IDs 1 - 25)
(1,  'Nakato Sarah Nalubega',    '256772100001', 'nakato.sarah@agriconnect.ug',     'BOTH',   1),
(2,  'Okello John Peter',        '256772100002', 'okello.john@agriconnect.ug',     'FARMER', 2),
(3,  'Mwesigwa David',           '256772100003', 'mwesigwa.david@agriconnect.ug',  'FARMER', 3),
(4,  'Kiconco Diana',            '256772100004', 'kiconco.diana@agriconnect.ug',   'FARMER', 3),
(5,  'Wanyama Patrick',          '256772100005', 'wanyama.patrick@agriconnect.ug', 'FARMER', 2),
(6,  'Otim Ronald Charles',      '256772100006', 'otim.ronald@agriconnect.ug',     'FARMER', 4),
(7,  'Akello Beatrice',          '256772100007', 'akello.beatrice@agriconnect.ug', 'BOTH',   4),
(8,  'Mugisha Brian',            '256772100008', 'mugisha.brian@agriconnect.ug',   'FARMER', 7),
(9,  'Byaruhanga Moses',         '256772100009', 'byaruhanga.m@agriconnect.ug',    'FARMER', 8),
(10, 'Namubiru Joan',            '256772100010', 'namubiru.joan@agriconnect.ug',   'BOTH',   13),
(11, 'Kintu Emmanuel',           '256772100011', 'kintu.emmanuel@agriconnect.ug',  'FARMER', 6),
(12, 'Nabirye Brenda',           '256772100012', 'nabirye.brenda@agriconnect.ug',  'FARMER', 5),
(13, 'Opolot Francis',           '256772100013', 'opolot.francis@agriconnect.ug',  'FARMER', 9),
(14, 'Dramadri Bosco',           '256772100014', 'dramadri.bosco@agriconnect.ug',  'FARMER', 10),
(15, 'Apio Sharon',              '256772100015', 'apio.sharon@agriconnect.ug',     'FARMER', 11),
(16, 'Twesigye Julius',          '256772100016', 'twesigye.j@agriconnect.ug',      'FARMER', 12),
(17, 'Lwanga Stephen',           '256772100017', 'lwanga.stephen@agriconnect.ug',  'FARMER', 14),
(18, 'Ochwo Anthony',            '256772100018', 'ochwo.anthony@agriconnect.ug',   'FARMER', 15),
(19, 'Ssenyonjo Frank',          '256772100019', 'ssenyonjo.f@agriconnect.ug',     'FARMER', 16),
(20, 'Atuhairwe Faith',          '256772100020', 'atuhairwe.faith@agriconnect.ug', 'FARMER', 3),
(21, 'Chebet Viola',             '256772100021', 'chebet.viola@agriconnect.ug',    'BOTH',   2),
(22, 'Alum Agnes',               '256772100022', 'alum.agnes@agriconnect.ug',      'FARMER', 4),
(23, 'Kigozi Robert',            '256772100023', 'kigozi.robert@agriconnect.ug',   'FARMER', 6),
(24, 'Ndagire Harriet',          '256772100024', 'ndagire.h@agriconnect.ug',       'FARMER', 13),
(25, 'Katushabe Mercy',          '256772100025', 'katushabe.m@agriconnect.ug',     'FARMER', 7),

-- Buyers & Dual-Role Institutional Consumers (IDs 26 - 50)
(26, 'Achieng Grace',            '256772100026', 'achieng.grace@gmail.com',        'BUYER',  1),
(27, 'Kato Peter Wasswa',        '256772100027', 'kato.peter@yahoo.com',           'BUYER',  5),
(28, 'Sserwadda Joseph (Cafe J)','256772100028', 'procurement@cafejavas.co.ug',   'BUYER',  1),
(29, 'Nansubuga Mary (Hotel A)', '256772100029', 'chef@hotelafricana.com',         'BUYER',  1),
(30, 'Mugisha Denis (Fresh Mart)','256772100030','denis@freshmartug.com',          'BUYER',  14),
(31, 'Ainembabazi Charity',      '256772100031', 'charity.aine@gmail.com',         'BUYER',  3),
(32, 'Okumu Samuel',             '256772100032', 'okumu.samuel@gmail.com',         'BUYER',  4),
(33, 'Kyomugisha Allen',         '256772100033', 'kyomugisha.a@gmail.com',         'BUYER',  7),
(34, 'Wasswa Derrick',           '256772100034', 'wasswa.derrick@gmail.com',       'BUYER',  1),
(35, 'Nankunda Patricia',        '256772100035', 'nankunda.p@gmail.com',           'BUYER',  17),
(36, 'Lubega Isaac',             '256772100036', 'lubega.isaac@gmail.com',         'BUYER',  1),
(37, 'Amuge Christine',          '256772100037', 'amuge.christine@gmail.com',      'BUYER',  9),
(38, 'Tusiime Kenneth',          '256772100038', 'tusiime.kenneth@gmail.com',      'BUYER',  3),
(39, 'Mukasa Gerald',            '256772100039', 'mukasa.gerald@gmail.com',        'BUYER',  6),
(40, 'Asiimwe Patience',         '256772100040', 'asiimwe.p@gmail.com',            'BUYER',  1),
(41, 'Basalirwa Hashim',         '256772100041', 'basalirwa.h@gmail.com',          'BUYER',  5),
(42, 'Akampurira Caleb',         '256772100042', 'caleb.akamp@gmail.com',          'BUYER',  12),
(43, 'Nalutaaya Prossy',         '256772100043', 'prossy.nalu@gmail.com',          'BUYER',  1),
(44, 'Odongo Daniel',            '256772100044', 'odongo.daniel@gmail.com',        'BUYER',  11),
(45, 'Babirye Flavia',           '256772100045', 'flavia.babirye@gmail.com',       'BUYER',  14),
(46, 'Kayondo Arthur',           '256772100046', 'kayondo.arthur@gmail.com',       'BUYER',  1),
(47, 'Tumusiime Alex',           '256772100047', 'alex.tumu@gmail.com',            'BUYER',  3),
(48, 'Birungi Caroline',         '256772100048', 'birungi.carol@gmail.com',        'BUYER',  8),
(49, 'Kavuma Richard',           '256772100049', 'kavuma.richard@gmail.com',       'BUYER',  1),
(50, 'Nalwadda Shamim',          '256772100050', 'shamim.nalwadda@gmail.com',      'BUYER',  17);

-- ------------------------------------------------------------------------------
-- 3. WALLETS (1 per User, seeded with working capital)
-- ------------------------------------------------------------------------------
INSERT INTO wallets (wallet_id, user_id, balance) VALUES
-- Farmers
(1, 1, 1500000.00), (2, 2, 850000.00),  (3, 3, 1200000.00), (4, 4, 940000.00),
(5, 5, 620000.00),  (6, 6, 450000.00),  (7, 7, 1800000.00), (8, 8, 770000.00),
(9, 9, 890000.00),  (10, 10, 2100000.00),(11, 11, 600000.00),(12, 12, 530000.00),
(13, 13, 490000.00),(14, 14, 420000.00),(15, 15, 680000.00),(16, 16, 910000.00),
(17, 17, 750000.00),(18, 18, 510000.00),(19, 19, 640000.00),(20, 20, 830000.00),
(21, 21, 1300000.00),(22, 22, 570000.00),(23, 23, 720000.00),(24, 24, 610000.00),
(25, 25, 880000.00),
-- Buyers (Higher balances for commercial purchasing)
(26, 26, 750000.00), (27, 27, 450000.00), (28, 28, 5500000.00),(29, 29, 4800000.00),
(30, 30, 3200000.00),(31, 31, 650000.00), (32, 32, 500000.00), (33, 33, 550000.00),
(34, 34, 820000.00), (35, 35, 950000.00), (36, 36, 600000.00), (37, 37, 480000.00),
(38, 38, 710000.00), (39, 39, 640000.00), (40, 40, 1100000.00),(41, 41, 530000.00),
(42, 42, 590000.00), (43, 43, 850000.00), (44, 44, 420000.00), (45, 45, 920000.00),
(46, 46, 780000.00), (47, 47, 610000.00), (48, 48, 540000.00), (49, 49, 1250000.00),
(50, 50, 970000.00);

-- ------------------------------------------------------------------------------
-- 4. PRODUCTS (100 Realistic Ugandan Produce Listings)
-- Units: kg, crate, bag, bunch, litre
-- Categories: GRAIN, FRUIT, VEGETABLE, TUBER, LIVESTOCK, OTHER
-- ------------------------------------------------------------------------------
INSERT INTO products (product_id, farmer_id, product_name, category, unit, unit_price, stock_qty, is_active) VALUES
-- GRAINS (1 - 20)
(1,  2,  'Yellow Maize Grain (Grade A)',     'GRAIN', 'bag',   120000.00, 150.00, TRUE),
(2,  2,  'White Maize Grain (Kawanda 4)',    'GRAIN', 'bag',   130000.00, 200.00, TRUE),
(3,  5,  'Red Finger Millet Grain',          'GRAIN', 'bag',   180000.00, 80.00,  TRUE),
(4,  6,  'Brown Sorghum (Serena)',           'GRAIN', 'bag',   140000.00, 120.00, TRUE),
(5,  13, 'Super Rice (Kaiso Aromatic)',      'GRAIN', 'bag',   260000.00, 75.00,  TRUE),
(6,  13, 'Upland Rice (NERICA 4)',           'GRAIN', 'bag',   240000.00, 90.00,  TRUE),
(7,  18, 'Pearl Millet Seed',                'GRAIN', 'bag',   160000.00, 50.00,  TRUE),
(8,  2,  'Red Beauty Groundnuts (Unshelled)','GRAIN', 'bag',   220000.00, 65.00,  TRUE),
(9,  5,  'Serenut 2 Groundnuts (Shelled)',   'GRAIN', 'kg',    7500.00,   450.00, TRUE),
(10, 6,  'Tan Groundnuts (Shelled)',         'GRAIN', 'kg',    7000.00,   300.00, TRUE),
(11, 7,  'Soya Beans (Maksoy 1N)',           'GRAIN', 'bag',   190000.00, 110.00, TRUE),
(12, 11, 'Yellow Beans (Nabe 4)',            'GRAIN', 'bag',   280000.00, 85.00,  TRUE),
(13, 11, 'Short White Haricot Beans',        'GRAIN', 'bag',   290000.00, 60.00,  TRUE),
(14, 15, 'Red Kidney Beans (K132)',          'GRAIN', 'bag',   250000.00, 95.00,  TRUE),
(15, 18, 'Cowpeas (Ecirikukwai)',            'GRAIN', 'kg',    4500.00,   500.00, TRUE),
(16, 15, 'Pigeon Peas (Apio variety)',       'GRAIN', 'kg',    5200.00,   350.00, TRUE),
(17, 7,  'Sesame Simsim (White Lira)',       'GRAIN', 'kg',    6800.00,   400.00, TRUE),
(18, 14, 'Green Grams (Mung Beans)',         'GRAIN', 'kg',    5500.00,   250.00, TRUE),
(19, 6,  'Chia Seeds (Organic Gulu)',        'GRAIN', 'kg',    12000.00,  180.00, TRUE),
(20, 22, 'Sunflower Seeds (Pannar Hybrid)',  'GRAIN', 'bag',   150000.00, 130.00, TRUE),

-- FRUITS (21 - 40)
(21, 1,  'Matooke Bunch (Mpologoma Big)',    'FRUIT', 'bunch', 28000.00,  140.00, TRUE),
(22, 1,  'Matooke Bunch (Kibuzi Medium)',    'FRUIT', 'bunch', 22000.00,  180.00, TRUE),
(23, 2,  'Mbale Matooke Crates (Cleaned)',   'FRUIT', 'crate', 45000.00,  60.00,  TRUE),
(24, 3,  'Mbarara Matooke Giant Bunch',      'FRUIT', 'bunch', 32000.00,  110.00, TRUE),
(25, 1,  'Ndizi Nshaki Apple Bananas',       'FRUIT', 'bunch', 25000.00,  95.00,  TRUE),
(26, 10, 'Sukali Ndizi Sweet Bananas',       'FRUIT', 'bunch', 18000.00,  130.00, TRUE),
(27, 10, 'Bogoya Cavendish Ripe Bananas',    'FRUIT', 'bunch', 24000.00,  85.00,  TRUE),
(28, 19, 'Kayunga Sweet Pineapples (Large)', 'FRUIT', 'crate', 50000.00,  70.00,  TRUE),
(29, 19, 'Smooth Cayenne Pineapples',        'FRUIT', 'crate', 42000.00,  90.00,  TRUE),
(30, 16, 'Hass Avocado (Export Grade)',      'FRUIT', 'crate', 65000.00,  55.00,  TRUE),
(31, 8,  'Fuerte Avocado (Fort Portal)',     'FRUIT', 'crate', 48000.00,  65.00,  TRUE),
(32, 9,  'Kasese Mangoes (Tommy Atkins)',    'FRUIT', 'crate', 52000.00,  80.00,  TRUE),
(33, 14, 'West Nile Sweet Mangoes (Bire)',   'FRUIT', 'crate', 38000.00,  100.00, TRUE),
(34, 9,  'Valencia Sweet Oranges',           'FRUIT', 'bag',   75000.00,  90.00,  TRUE),
(35, 11, 'Masaka Purple Passion Fruit',      'FRUIT', 'bag',   140000.00, 45.00,  TRUE),
(36, 17, 'Sugar Baby Watermelons (Medium)',  'FRUIT', 'crate', 55000.00,  60.00,  TRUE),
(37, 17, 'Zanzibar Giant Watermelons',       'FRUIT', 'crate', 70000.00,  40.00,  TRUE),
(38, 19, 'Solo Papaya Pawpaws',              'FRUIT', 'crate', 36000.00,  75.00,  TRUE),
(39, 10, 'Ripe Honey Jackfruit (Fene)',      'FRUIT', 'bunch', 15000.00,  50.00,  TRUE),
(40, 8,  'Red Guavas (Sweet Kabarole)',      'FRUIT', 'crate', 30000.00,  40.00,  TRUE),

-- VEGETABLES (41 - 60)
(41, 10, 'Fresh Nakati Greens (Bundled)',    'VEGETABLE', 'crate', 25000.00, 80.00,  TRUE),
(42, 10, 'Sukuma Wiki (Collard Greens)',     'VEGETABLE', 'crate', 22000.00, 90.00,  TRUE),
(43, 17, 'Dodo Amaranth Greens',             'VEGETABLE', 'crate', 20000.00, 85.00,  TRUE),
(44, 16, 'Gloria F1 Solid Cabbage',          'VEGETABLE', 'bag',   60000.00, 70.00,  TRUE),
(45, 12, 'Red Creole Dry Onions',            'VEGETABLE', 'bag',   160000.00,65.00,  TRUE),
(46, 12, 'White Bombay Dry Onions',          'VEGETABLE', 'bag',   175000.00,50.00,  TRUE),
(47, 17, 'Nuru F1 Salad Tomatoes',           'VEGETABLE', 'crate', 85000.00, 75.00,  TRUE),
(48, 23, 'Rambo F1 Cooking Tomatoes',        'VEGETABLE', 'crate', 75000.00, 90.00,  TRUE),
(49, 23, 'Green Sweet Bell Pepper (Hoho)',   'VEGETABLE', 'crate', 60000.00, 50.00,  TRUE),
(50, 14, 'Habanero Hot Chili (Pilipili)',    'VEGETABLE', 'bag',   95000.00, 40.00,  TRUE),
(51, 16, 'Kabale Crisp Carrots',             'VEGETABLE', 'bag',   110000.00,60.00,  TRUE),
(52, 16, 'Highland Beetroot',                'VEGETABLE', 'bag',   90000.00, 45.00,  TRUE),
(53, 12, 'Fresh Purple Garlic Bulbs',        'VEGETABLE', 'bag',   210000.00,30.00,  TRUE),
(54, 24, 'Black Beauty Eggplants',           'VEGETABLE', 'crate', 35000.00, 65.00,  TRUE),
(55, 24, 'African Bitter Tomatoes (Entula)', 'VEGETABLE', 'crate', 28000.00, 70.00,  TRUE),
(56, 17, 'English Spinach (Curled)',         'VEGETABLE', 'crate', 32000.00, 55.00,  TRUE),
(57, 8,  'French Green Beans (Export)',      'VEGETABLE', 'crate', 70000.00, 40.00,  TRUE),
(58, 8,  'Garden Peas (Minji fresh)',        'VEGETABLE', 'bag',   130000.00,35.00,  TRUE),
(59, 13, 'Butternut Squash Pumpkins',        'VEGETABLE', 'bag',   55000.00, 80.00,  TRUE),
(60, 13, 'Traditional Sweet Pumpkins',       'VEGETABLE', 'bag',   48000.00, 90.00,  TRUE),

-- TUBERS (61 - 75)
(61, 23, 'Fresh Cassava Roots (TME 14)',     'TUBER', 'bag',   70000.00,  120.00, TRUE),
(62, 23, 'Sun-Dried Cassava Chips',          'TUBER', 'bag',   85000.00,  100.00, TRUE),
(63, 15, 'Pure Cassava Flour (Milled)',      'TUBER', 'bag',   95000.00,  80.00,  TRUE),
(64, 7,  'Orange Fleshed Sweet Potatoes',    'TUBER', 'bag',   80000.00,  95.00,  TRUE),
(65, 7,  'Ejumula Purple Sweet Potatoes',    'TUBER', 'bag',   75000.00,  110.00, TRUE),
(66, 16, 'Irish Potatoes (Victoria)',        'TUBER', 'bag',   150000.00, 130.00, TRUE),
(67, 16, 'Irish Potatoes (Rwangume Red)',    'TUBER', 'bag',   165000.00, 100.00, TRUE),
(68, 12, 'Kinigi Seed Potatoes',             'TUBER', 'bag',   190000.00, 50.00,  TRUE),
(69, 10, 'White Forest Yams (Balugu)',       'TUBER', 'bag',   120000.00, 45.00,  TRUE),
(70, 10, 'Purple Cocoyams (Mayuni roots)',   'TUBER', 'bag',   110000.00, 55.00,  TRUE),
(71, 24, 'Arrowroots (Fresh Enjovu)',        'TUBER', 'bag',   135000.00, 40.00,  TRUE),
(72, 1,  'Ginger Rhizomes (Tangawizi)',      'TUBER', 'bag',   240000.00, 35.00,  TRUE),
(73, 2,  'Fresh Turmeric Roots',             'TUBER', 'kg',    8000.00,   120.00, TRUE),
(74, 18, 'Sweet Yam Tubers (Nandigoya)',     'TUBER', 'bag',   95000.00,  60.00,  TRUE),
(75, 23, 'Red Skin Sweet Potatoes (Kakamega)','TUBER','bag',   72000.00,  85.00,  TRUE),

-- LIVESTOCK & POULTRY (76 - 90)
(76, 3,  'Ankole Longhorn Steer (Adult)',    'LIVESTOCK', 'kg', 12000.00, 450.00, TRUE),
(77, 3,  'Ankole Heifer (Yearling)',         'LIVESTOCK', 'kg', 14000.00, 320.00, TRUE),
(78, 4,  'Mubende He-Goat (Mature)',         'LIVESTOCK', 'kg', 15000.00, 35.00,  TRUE),
(79, 4,  'Boer Goat Cross (Breeding)',       'LIVESTOCK', 'kg', 18000.00, 45.00,  TRUE),
(80, 20, 'Local Free-Range Rooster',         'LIVESTOCK', 'kg', 16000.00, 60.00,  TRUE),
(81, 20, 'Kuroiler Mature Hen (Dual Purpose)','LIVESTOCK','kg', 14000.00, 120.00, TRUE),
(82, 24, 'Broiler Meat Chicken (Cleaned)',   'LIVESTOCK', 'kg', 11000.00, 200.00, TRUE),
(83, 24, 'Fresh Farm Brown Eggs (Tray of 30)','LIVESTOCK','crate',14000.00, 250.00, TRUE),
(84, 13, 'Local Free-Range Guinea Fowl',     'LIVESTOCK', 'kg', 22000.00, 50.00,  TRUE),
(85, 17, 'Fresh Lake Victoria Nile Perch',   'LIVESTOCK', 'kg', 18000.00, 150.00, TRUE),
(86, 17, 'Whole Fresh Tilapia (Gilled)',     'LIVESTOCK', 'kg', 15000.00, 220.00, TRUE),
(87, 5,  'Clarias African Catfish (Live)',   'LIVESTOCK', 'kg', 13000.00, 180.00, TRUE),
(88, 5,  'Smoked Lake Victoria Mukene Fish', 'LIVESTOCK', 'bag', 120000.00,60.00,  TRUE),
(89, 9,  'Pork Carcass (Grain Fed)',         'LIVESTOCK', 'kg', 14500.00, 160.00, TRUE),
(90, 8,  'Live Commercial Turkey (Male)',    'LIVESTOCK', 'kg', 20000.00, 40.00,  TRUE),

-- OTHER (DAIRY, HONEY, CASH CROPS, PROCESSED) (91 - 100)
(91, 3,  'Fresh Raw Whole Milk (Unpasteurized)','OTHER', 'litre', 1600.00, 1200.00, TRUE),
(92, 3,  'Traditional Ankole Cow Ghee (Eshabwe)','OTHER','kg',   26000.00, 90.00,   TRUE),
(93, 20, 'Pure Raw West Nile Honey (Comb)',     'OTHER', 'kg',   22000.00, 140.00,  TRUE),
(94, 2,  'Robusta FAQ Coffee Green Beans',      'OTHER', 'bag',   420000.00,60.00,  TRUE),
(95, 2,  'Arabica Bugisu AA Parchment Coffee',  'OTHER', 'bag',   580000.00,45.00,  TRUE),
(96, 8,  'Kasese Organic Cocoa Beans (Fermented)','OTHER','bag',  380000.00,50.00,  TRUE),
(97, 13, 'Cured Gourmet Bourbon Vanilla Beans',  'OTHER', 'kg',   180000.00,25.00,  TRUE),
(98, 5,  'Raw Unrefined Sugar Cane Molasses',   'OTHER', 'litre', 3500.00, 500.00,  TRUE),
(99, 1,  'Cold Pressed Virgin Coconut Oil',     'OTHER', 'litre', 30000.00, 80.00,  TRUE),
(100,25, 'Organic Dried Chili Powder',          'OTHER', 'kg',    15000.00, 95.00,  TRUE);

-- ------------------------------------------------------------------------------
-- 5. ORDERS (30 Realistic Historical Orders)
-- Buyer IDs range from 26 to 50
-- ------------------------------------------------------------------------------
INSERT INTO orders (order_id, buyer_id, order_date, status, delivery_address, total_amount) VALUES
(1,  28, '2025-01-05 09:15:00', 'DELIVERED', 'Cafe Javas Parliamentary Ave, Kampala',      640000.00),
(2,  29, '2025-01-10 10:30:00', 'DELIVERED', 'Hotel Africana Banquet Kitchen, Kampala',      950000.00),
(3,  30, '2025-01-18 14:00:00', 'DELIVERED', 'Fresh Mart Supermarket, Kisasi Branch',        410000.00),
(4,  26, '2025-01-22 11:20:00', 'DELIVERED', 'Plot 14, Clement Hill Road, Nakasero',         112000.00),
(5,  27, '2025-01-28 16:45:00', 'DELIVERED', 'Main Street Jinja, Opposite Nile Brewery',    240000.00),
(6,  31, '2025-02-02 08:30:00', 'DELIVERED', 'Kakoba Central Market Stalls, Mbarara',       320000.00),
(7,  32, '2025-02-08 12:10:00', 'DELIVERED', 'Gulu Main Market Gate 2, Commercial Rd',       290000.00),
(8,  33, '2025-02-14 15:00:00', 'DELIVERED', 'Mountains of the Moon Hotel, Fort Portal',    185000.00),
(9,  34, '2025-02-20 17:30:00', 'DELIVERED', 'Kyambogo University Central Dining, Kampala',  520000.00),
(10, 35, '2025-02-25 10:00:00', 'DELIVERED', 'Imperial Resort Beach Hotel, Entebbe',        480000.00),
(11, 28, '2025-03-02 09:40:00', 'DELIVERED', 'Cafe Javas Oasis Mall Branch, Kampala',        820000.00),
(12, 29, '2025-03-08 11:15:00', 'DELIVERED', 'Hotel Africana Kitchen Store, Kampala',        730000.00),
(13, 30, '2025-03-14 13:50:00', 'DELIVERED', 'Fresh Mart Supermarket, Sonde Branch',         360000.00),
(14, 36, '2025-03-20 16:10:00', 'DELIVERED', 'Ntinda Shopping Centre, Store B12',           145000.00),
(15, 37, '2025-03-26 10:25:00', 'DELIVERED', 'Soroti Flying School Canteen, Soroti',         220000.00),
(16, 38, '2025-04-03 08:50:00', 'DELIVERED', 'Agip Motel Kitchen, Mbarara Bypass',           340000.00),
(17, 39, '2025-04-10 14:15:00', 'DELIVERED', 'Masaka Backpackers Lodge, Masaka',            190000.00),
(18, 40, '2025-04-18 12:00:00', 'DELIVERED', 'Kololo Courts Residences, Kampala',            265000.00),
(19, 41, '2025-04-24 15:40:00', 'DELIVERED', 'Sunset Hotel International, Jinja',           310000.00),
(20, 42, '2025-05-02 09:10:00', 'DELIVERED', 'White Horse Inn, Kabale Hill',                280000.00),
(21, 28, '2025-05-10 10:00:00', 'DELIVERED', 'Cafe Javas Lugogo Mall, Kampala',             910000.00),
(22, 29, '2025-05-18 11:30:00', 'DELIVERED', 'Hotel Africana Events Catering, Kampala',      850000.00),
(23, 43, '2025-05-25 14:20:00', 'DELIVERED', 'Bugolobi Village Mall, Apt 4B',               160000.00),
(24, 44, '2025-06-02 16:45:00', 'DELIVERED', 'Graceland Hotel, Lira Town',                  275000.00),
(25, 45, '2025-06-10 09:30:00', 'DELIVERED', 'Victoria Serena Golf Resort, Kigo',           490000.00),
-- Recent active orders
(26, 46, '2025-06-15 13:00:00', 'DISPATCHED','Bukoto Heights Apartments, Block C',          210000.00),
(27, 47, '2025-06-16 10:15:00', 'DISPATCHED','Lake View Resort Hotel, Mbarara',             350000.00),
(28, 48, '2025-06-17 08:45:00', 'PAID',      'Kasese Cobalt Camp Housing, Kasese',          180000.00),
(29, 49, '2025-06-17 11:30:00', 'PENDING',   'Muyenga Tank Hill Road, Kampala',             150000.00),
(30, 50, '2025-06-17 14:00:00', 'CANCELLED', 'Entebbe Airport Cargo Terminal',              220000.00);

-- ------------------------------------------------------------------------------
-- 6. ORDER_ITEMS (Detailed Line Items with Frozen Prices)
-- line_total is GENERATED ALWAYS AS (qty * unit_price) STORED
-- ------------------------------------------------------------------------------
INSERT INTO order_items (order_item_id, order_id, product_id, qty, unit_price) VALUES
-- Order 1: Cafe Javas (Matooke, Milk, Eggs)
(1,  1,  21, 10.00, 28000.00), -- 280,000
(2,  1,  91, 100.00,1600.00),  -- 160,000
(3,  1,  83, 10.00, 14000.00), -- 140,000
(4,  1,  47, 1.00,  60000.00), -- 60,000 (special promo unit price)
-- Order 2: Hotel Africana (Pineapples, Nile Perch, Potatoes)
(5,  2,  28, 5.00,  50000.00), -- 250,000
(6,  2,  85, 20.00, 18000.00), -- 360,000
(7,  2,  66, 2.00,  150000.00),-- 300,000
(8,  2,  44, 1.00,  40000.00), -- 40,000
-- Order 3: Fresh Mart (Rice, Beans)
(9,  3,  5,  1.00,  260000.00),-- 260,000
(10, 3,  66, 1.00,  150000.00),-- 150,000
-- Order 4: Grace (Matooke & Honey)
(11, 4,  21, 2.00,  28000.00), -- 56,000
(12, 4,  93, 2.00,  22000.00), -- 44,000
(13, 4,  9,  1.60,  7500.00),  -- 12,000
-- Order 5: Kato (Rice)
(14, 5,  6,  1.00,  240000.00),-- 240,000
-- Order 6: Charity (Mbarara Matooke, Ghee)
(15, 6,  24, 5.00,  32000.00), -- 160,000
(16, 6,  92, 5.00,  26000.00), -- 130,000
(17, 6,  91, 18.75, 1600.00),  -- 30,000
-- Order 7: Okumu (Finger Millet & Simsim)
(18, 7,  3,  1.00,  180000.00),-- 180,000
(19, 7,  17, 10.00, 6800.00),  -- 68,000
(20, 7,  15, 9.33,  4500.00),  -- 42,000
-- Order 8: Allen (Avocado & Vanilla)
(21, 8,  31, 2.00,  48000.00), -- 96,000
(22, 8,  97, 0.50,  178000.00),-- 89,000
-- Order 9: Kyambogo (Yellow Maize, Beans)
(23, 9,  1,  2.00,  120000.00),-- 240,000
(24, 9,  12, 1.00,  280000.00),-- 280,000
-- Order 10: Imperial Resort (Tilapia, Passion Fruit)
(25, 10, 86, 20.00, 15000.00), -- 300,000
(26, 10, 35, 1.00,  140000.00),-- 140,000
(27, 10, 28, 0.80,  50000.00), -- 40,000
-- Order 11: Cafe Javas (Bugisu Coffee, Milk)
(28, 11, 95, 1.00,  580000.00),-- 580,000
(29, 11, 91, 150.00,1600.00),  -- 240,000
-- Order 12: Hotel Africana (Irish Potatoes, Beef/Mubende Goat)
(30, 12, 67, 2.00,  165000.00),-- 330,000
(31, 12, 78, 20.00, 15000.00), -- 300,000
(32, 12, 48, 1.00,  75000.00), -- 75,000
(33, 12, 51, 0.23,  110000.00),-- 25,000
-- Order 13: Fresh Mart (Groundnuts, Simsim)
(34, 13, 8,  1.00,  220000.00),-- 220,000
(35, 13, 17, 20.00, 6800.00),  -- 136,000
(36, 13, 19, 0.33,  12000.00), -- 4,000
-- Order 14: Ntinda Store (Tomatoes, Nakati)
(37, 14, 47, 1.00,  85000.00), -- 85,000
(38, 14, 41, 2.00,  25000.00), -- 50,000
(39, 14, 42, 0.45,  22000.00), -- 10,000
-- Order 15: Soroti Canteen (Cassava & Cowpeas)
(40, 15, 63, 1.00,  95000.00), -- 95,000
(41, 15, 15, 20.00, 4500.00),  -- 90,000
(42, 15, 7,  0.22,  160000.00),-- 35,000
-- Order 16: Agip Motel (Ankole Steer cuts)
(43, 16, 76, 25.00, 12000.00), -- 300,000
(44, 16, 92, 1.54,  26000.00), -- 40,000
-- Order 17: Masaka Lodge (Passion fruit, Eggs)
(45, 17, 35, 1.00,  140000.00),-- 140,000
(46, 17, 83, 3.57,  14000.00), -- 50,000
-- Order 18: Kololo Residences (Honey, Hass Avocado, Chicken)
(47, 18, 93, 3.00,  22000.00), -- 66,000
(48, 18, 30, 1.00,  65000.00), -- 65,000
(49, 18, 81, 9.57,  14000.00), -- 134,000
-- Order 19: Sunset Hotel (Tilapia, Rice)
(50, 19, 86, 10.00, 15000.00), -- 150,000
(51, 19, 6,  0.67,  240000.00),-- 160,000
-- Order 20: White Horse Inn (Irish Potatoes, Onions)
(52, 20, 67, 1.00,  165000.00),-- 165,000
(53, 20, 45, 0.72,  160000.00),-- 115,000
-- Order 21: Cafe Javas (Bugisu Coffee, Honey, Milk)
(54, 21, 95, 1.00,  580000.00),-- 580,000
(55, 21, 93, 10.00, 22000.00), -- 220,000
(56, 21, 91, 68.75, 1600.00),  -- 110,000
-- Order 22: Hotel Africana (Watermelons, Tilapia, Pineapples)
(57, 22, 37, 5.00,  70000.00), -- 350,000
(58, 22, 86, 20.00, 15000.00), -- 300,000
(59, 22, 28, 4.00,  50000.00), -- 200,000
-- Order 23: Prossy (Matooke, Tomatoes)
(60, 23, 21, 3.00,  28000.00), -- 84,000
(61, 23, 47, 0.89,  85000.00), -- 76,000
-- Order 24: Graceland Lira (Soybeans & Gnuts)
(62, 24, 11, 1.00,  190000.00),-- 190,000
(63, 24, 10, 12.14, 7000.00),  -- 85,000
-- Order 25: Victoria Serena (Turkey, Ghee, Passion Fruit)
(64, 25, 90, 10.00, 20000.00), -- 200,000
(65, 25, 35, 1.00,  140000.00),-- 140,000
(66, 25, 92, 5.77,  26000.00), -- 150,000
-- Order 26: Dispatched
(67, 26, 24, 5.00,  32000.00), -- 160,000
(68, 26, 28, 1.00,  50000.00), -- 50,000
-- Order 27: Dispatched
(69, 27, 85, 15.00, 18000.00), -- 270,000
(70, 27, 66, 0.53,  150000.00),-- 80,000
-- Order 28: Paid
(71, 28, 3,  1.00,  180000.00),-- 180,000
-- Order 29: Pending
(72, 29, 66, 1.00,  150000.00),-- 150,000
-- Order 30: Cancelled
(73, 30, 8,  1.00,  220000.00);-- 220,000

-- ------------------------------------------------------------------------------
-- 7. DELIVERIES (Logistics Tracking for Orders 1 - 30)
-- ------------------------------------------------------------------------------
INSERT INTO deliveries (delivery_id, order_id, driver_name, driver_phone, status, dispatched_at, delivered_at) VALUES
(1,  1,  'Kigozi Sulaiman',  '256701112233', 'DONE',      '2025-01-05 10:00:00', '2025-01-05 13:45:00'),
(2,  2,  'Musoke Godfrey',   '256701112234', 'DONE',      '2025-01-10 11:30:00', '2025-01-10 15:10:00'),
(3,  3,  'Bukenya Ronald',   '256701112235', 'DONE',      '2025-01-18 15:00:00', '2025-01-18 17:30:00'),
(4,  4,  'Walusimbi Fred',   '256701112236', 'DONE',      '2025-01-22 12:00:00', '2025-01-22 14:15:00'),
(5,  5,  'Isabirye James',   '256701112237', 'DONE',      '2025-01-28 17:15:00', '2025-01-28 19:30:00'),
(6,  6,  'Musinguzi Abel',   '256701112238', 'DONE',      '2025-02-02 09:15:00', '2025-02-02 12:45:00'),
(7,  7,  'Ojok Geoffrey',    '256701112239', 'DONE',      '2025-02-08 13:00:00', '2025-02-08 16:30:00'),
(8,  8,  'Kabasomi Edward',  '256701112240', 'DONE',      '2025-02-14 15:30:00', '2025-02-14 18:00:00'),
(9,  9,  'Kigozi Sulaiman',  '256701112233', 'DONE',      '2025-02-20 18:00:00', '2025-02-20 20:45:00'),
(10, 10, 'Musoke Godfrey',   '256701112234', 'DONE',      '2025-02-25 10:45:00', '2025-02-25 13:15:00'),
(11, 11, 'Bukenya Ronald',   '256701112235', 'DONE',      '2025-03-02 10:30:00', '2025-03-02 14:00:00'),
(12, 12, 'Walusimbi Fred',   '256701112236', 'DONE',      '2025-03-08 12:00:00', '2025-03-08 16:20:00'),
(13, 13, 'Kigozi Sulaiman',  '256701112233', 'DONE',      '2025-03-14 14:30:00', '2025-03-14 18:10:00'),
(14, 14, 'Musoke Godfrey',   '256701112234', 'DONE',      '2025-03-20 17:00:00', '2025-03-20 19:40:00'),
(15, 15, 'Engwau Simon',     '256701112241', 'DONE',      '2025-03-26 11:15:00', '2025-03-26 14:50:00'),
(16, 16, 'Musinguzi Abel',   '256701112238', 'DONE',      '2025-04-03 09:30:00', '2025-04-03 13:00:00'),
(17, 17, 'Luyima Kenneth',   '256701112242', 'DONE',      '2025-04-10 15:00:00', '2025-04-10 18:25:00'),
(18, 18, 'Walusimbi Fred',   '256701112236', 'DONE',      '2025-04-18 12:45:00', '2025-04-18 15:30:00'),
(19, 19, 'Isabirye James',   '256701112237', 'DONE',      '2025-04-24 16:30:00', '2025-04-24 19:15:00'),
(20, 20, 'Tushabomwe Brian', '256701112243', 'DONE',      '2025-05-02 10:00:00', '2025-05-02 13:45:00'),
(21, 21, 'Kigozi Sulaiman',  '256701112233', 'DONE',      '2025-05-10 10:45:00', '2025-05-10 14:30:00'),
(22, 22, 'Musoke Godfrey',   '256701112234', 'DONE',      '2025-05-18 12:15:00', '2025-05-18 15:50:00'),
(23, 23, 'Bukenya Ronald',   '256701112235', 'DONE',      '2025-05-25 15:00:00', '2025-05-25 17:40:00'),
(24, 24, 'Okello Patrick',   '256701112244', 'DONE',      '2025-06-02 17:15:00', '2025-06-02 20:30:00'),
(25, 25, 'Walusimbi Fred',   '256701112236', 'DONE',      '2025-06-10 10:15:00', '2025-06-10 13:00:00'),
(26, 26, 'Kigozi Sulaiman',  '256701112233', 'IN_TRANSIT','2025-06-15 14:00:00', NULL),
(27, 27, 'Musinguzi Abel',   '256701112238', 'IN_TRANSIT','2025-06-16 11:00:00', NULL),
(28, 28, 'Kabasomi Edward',  '256701112240', 'SCHEDULED', NULL,                  NULL),
(29, 29, NULL,               NULL,           'SCHEDULED', NULL,                  NULL),
(30, 30, NULL,               NULL,           'FAILED',    NULL,                  NULL);

-- ------------------------------------------------------------------------------
-- 8. REVIEWS (Buyer Reviews on Purchased Products)
-- Business Rule 8: 1-5 ratings for items actually purchased
-- ------------------------------------------------------------------------------
INSERT INTO reviews (review_id, buyer_id, product_id, rating, comment, review_date) VALUES
(1,  28, 21, 5, 'Exceptional quality Mpologoma matooke bunches! Cafe Javas kitchen approves.', '2025-01-06 14:20:00'),
(2,  28, 91, 5, 'Rich, fresh, unpasteurized milk. Very creamy with high butterfat content.',    '2025-01-06 14:22:00'),
(3,  28, 83, 4, 'Eggs arrived safely with zero breakage. Consistent medium-large egg size.',      '2025-01-06 14:25:00'),
(4,  29, 28, 5, 'The Kayunga pineapples were naturally sweet and properly matured on the farm.',  '2025-01-11 11:00:00'),
(5,  29, 85, 4, 'Very fresh Lake Victoria Nile perch. Cleaned nicely and iced properly.',         '2025-01-11 11:05:00'),
(6,  30, 5,  5, 'Clean Kaiso aromatic rice without stones or husk debris. Sold out quickly.',     '2025-01-19 16:30:00'),
(7,  26, 21, 4, 'Good quality matooke for home consumption. Delivered on time.',                  '2025-01-23 09:15:00'),
(8,  26, 93, 5, 'Genuine natural West Nile honey. Unadulterated and full of flavor!',             '2025-01-23 09:18:00'),
(9,  27, 6,  4, 'Great upland rice grain quality. Cooked evenly.',                                '2025-01-29 18:00:00'),
(10, 31, 24, 5, 'Huge Mbarara bunch, very clean and fresh.',                                     '2025-02-03 10:10:00'),
(11, 31, 92, 5, 'Authentic Ankole ghee, perfect traditional aroma and texture.',                 '2025-02-03 10:12:00'),
(12, 32, 3,  5, 'Grade A finger millet. Exactly what we needed in Gulu.',                        '2025-02-09 14:00:00'),
(13, 33, 31, 4, 'Firm Hass/Fuerte avocados from Fort Portal, ripened evenly.',                    '2025-02-15 16:40:00'),
(14, 34, 1,  4, 'Clean yellow maize bags for student meals. Reliable supplier.',                 '2025-02-21 11:20:00'),
(15, 34, 12, 5, 'Yellow beans (Nabe 4) cooked fast with little firewood.',                       '2025-02-21 11:25:00'),
(16, 35, 86, 5, 'Fresh whole tilapia delivered on ice directly to Entebbe.',                      '2025-02-26 12:00:00'),
(17, 28, 95, 5, 'Bugisu AA Arabica beans exceeded our espresso cupping score. Top notch!',       '2025-03-03 11:00:00'),
(18, 29, 67, 4, 'Rwangume red potatoes are firm and perfect for hotel chips/wedges.',             '2025-03-09 10:45:00'),
(19, 30, 8,  4, 'Red beauty gnuts were properly dried, zero aflatoxin smell.',                   '2025-03-15 15:10:00'),
(20, 36, 47, 4, 'Crisp salad tomatoes with solid shelf life.',                                    '2025-03-21 17:00:00'),
(21, 37, 63, 4, 'Finely milled white cassava flour, great for atap/ugali.',                       '2025-03-27 12:30:00'),
(22, 38, 76, 5, 'Ankole steer beef cuts were lean and tender. High patron satisfaction.',        '2025-04-04 11:15:00'),
(23, 39, 35, 5, 'Super sweet purple passion fruits from Masaka.',                                 '2025-04-11 16:00:00'),
(24, 40, 93, 5, 'Ordered honey second time, consistent pure quality.',                            '2025-04-19 13:20:00'),
(25, 41, 86, 4, 'Good quality tilapia, fresh from Jinja landing site.',                           '2025-04-25 17:30:00'),
(26, 42, 67, 5, 'Kabale highland potatoes never disappoint. Highly recommended.',                '2025-05-03 11:50:00'),
(27, 43, 21, 4, 'Great matooke delivered directly to Bugolobi apartment gate.',                  '2025-05-26 15:00:00'),
(28, 44, 11, 4, 'Soybeans were clean and well bagged.',                                           '2025-06-03 18:10:00'),
(29, 45, 90, 5, 'The turkey was healthy, heavy, and properly prepped.',                           '2025-06-11 11:30:00'),
(30, 26, 9,  4, 'Serenut gnuts are sweet and great for pasted sauce.',                           '2025-01-23 09:20:00');

-- ------------------------------------------------------------------------------
-- 9. WALLET TRANSACTIONS (Immutable Financial Ledger for Past Orders)
-- Logs CASH_IN top-ups, BUYER payments, and FARMER receipts (net 95%)
-- ------------------------------------------------------------------------------
-- Initial Cash-in entries
INSERT INTO wallet_txns (txn_id, wallet_id, txn_type, amount, ref_code, counterparty_wallet, txn_date) VALUES
(1,  28, 'CASH_IN', 10000000.00, 'CI1736064001', NULL, '2025-01-01 08:00:00'),
(2,  29, 'CASH_IN', 8000000.00,  'CI1736064002', NULL, '2025-01-01 08:15:00'),
(3,  30, 'CASH_IN', 5000000.00,  'CI1736064003', NULL, '2025-01-02 09:00:00'),
(4,  26, 'CASH_IN', 1000000.00,  'CI1736064004', NULL, '2025-01-03 10:00:00'),
(5,  27, 'CASH_IN', 1000000.00,  'CI1736064005', NULL, '2025-01-04 11:30:00');

-- Order 1: Buyer 28 pays 640,000; Farmer 1 receives 608,000 (after 5% platform cut)
INSERT INTO wallet_txns (txn_id, wallet_id, txn_type, amount, ref_code, counterparty_wallet, txn_date) VALUES
(6,  28, 'PAYMENT', 640000.00, 'ORD1_DEBIT',  1, '2025-01-05 09:15:00'),
(7,  1,  'RECEIPT', 608000.00, 'ORD1_CREDIT', 28, '2025-01-05 09:15:00');

-- Order 2: Buyer 29 pays 950,000; Farmer 19 receives 902,500
INSERT INTO wallet_txns (txn_id, wallet_id, txn_type, amount, ref_code, counterparty_wallet, txn_date) VALUES
(8,  29, 'PAYMENT', 950000.00, 'ORD2_DEBIT',  19, '2025-01-10 10:30:00'),
(9,  19, 'RECEIPT', 902500.00, 'ORD2_CREDIT', 29, '2025-01-10 10:30:00');

-- Order 3: Buyer 30 pays 410,000; Farmer 13 receives 389,500
INSERT INTO wallet_txns (txn_id, wallet_id, txn_type, amount, ref_code, counterparty_wallet, txn_date) VALUES
(10, 30, 'PAYMENT', 410000.00, 'ORD3_DEBIT',  13, '2025-01-18 14:00:00'),
(11, 13, 'RECEIPT', 389500.00, 'ORD3_CREDIT', 30, '2025-01-18 14:00:00');

-- Order 4: Buyer 26 pays 112,000; Farmer 1 receives 106,400
INSERT INTO wallet_txns (txn_id, wallet_id, txn_type, amount, ref_code, counterparty_wallet, txn_date) VALUES
(12, 26, 'PAYMENT', 112000.00, 'ORD4_DEBIT',  1, '2025-01-22 11:20:00'),
(13, 1,  'RECEIPT', 106400.00, 'ORD4_CREDIT', 26, '2025-01-22 11:20:00');

-- Order 5: Buyer 27 pays 240,000; Farmer 13 receives 228,000
INSERT INTO wallet_txns (txn_id, wallet_id, txn_type, amount, ref_code, counterparty_wallet, txn_date) VALUES
(14, 27, 'PAYMENT', 240000.00, 'ORD5_DEBIT',  13, '2025-01-28 16:45:00'),
(15, 13, 'RECEIPT', 228000.00, 'ORD5_CREDIT', 27, '2025-01-28 16:45:00');
