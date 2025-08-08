-- Inserts for table: users
INSERT INTO users VALUES (1, 'alvesyan@example.org', '+55 71 6184 9593', '2022-06-04 21:21:59.316978', '832.714.065-53', 1654, True);
INSERT INTO users VALUES (2, 'joao-lucassousa@example.org', '+55 (084) 0341 3164', '2022-07-13 12:29:37.105453', '701.269.835-77', 1114, False);
INSERT INTO users VALUES (3, 'pastorlavinia@example.org', '(051) 5255-3419', '2025-04-27 12:33:04.251691', '179.648.523-37', 1025, True);
INSERT INTO users VALUES (4, 'borgespedro-henrique@example.org', '+55 (041) 8327-6483', '2024-11-19 15:55:11.253492', '824.763.190-31', 1759, True);
INSERT INTO users VALUES (5, 'novaismiguel@example.net', '(061) 0305 6413', '2021-06-20 16:32:23.438415', '465.398.072-10', 1281, True);
INSERT INTO users VALUES (6, 'ccamara@example.net', '0300 537 6724', '2022-10-17 00:12:37.372432', '150.469.872-01', 1250, True);
INSERT INTO users VALUES (7, 'anthony-gabriel26@example.com', '+55 84 3884 9696', '2020-12-30 00:37:47.766429', '031.926.785-77', 1228, True);
INSERT INTO users VALUES (8, 'leonardo35@example.org', '21 3287 1012', '2025-02-02 14:19:34.250276', '382.546.901-89', 1142, True);
INSERT INTO users VALUES (9, 'garciagael@example.com', '+55 (031) 6916-6978', '2024-11-08 19:03:09.222488', '631.058.274-71', 1754, True);
INSERT INTO users VALUES (10, 'vinicius07@example.net', '+55 61 8018-4514', '2021-08-31 02:52:26.656929', '701.832.654-08', 1104, False);

-- Inserts for table: assets
INSERT INTO assets VALUES (1, 'BTC', 'Bitcoin');
INSERT INTO assets VALUES (4, 'USDT', 'Tether');

-- Inserts for table: quotes
INSERT INTO quotes VALUES (1, 1, 'buy', 65392, 54597, 2138, '2025-04-05 11:47:03.217914', '2025-03-30 20:39:06.787109', NULL, 2, 1, 6, '2025-02-10 01:31:26.957462');
INSERT INTO quotes VALUES (2, 6, 'sell', 89131, 44671, 4305, '2025-02-28 16:04:20.083634', '2025-02-22 14:47:43.422170', NULL, 1, 4, 9, NULL);
INSERT INTO quotes VALUES (3, 2, 'sell', 92397, 91070, 4626, '2025-04-04 08:04:05.292328', '2025-07-01 10:12:06.451199', NULL, 3, 1, 2, '2025-07-14 11:11:44.055725');
INSERT INTO quotes VALUES (4, 5, 'buy', 40512, 23238, 2556, '2025-04-26 21:56:48.797544', '2025-01-11 15:43:43.772491', NULL, 3, 4, 6, NULL);
INSERT INTO quotes VALUES (5, 5, 'buy', 89840, 93227, 1700, '2025-07-30 11:28:05.114061', '2025-06-26 02:11:56.750747', NULL, 5, 1, 3, NULL);
INSERT INTO quotes VALUES (6, 9, 'buy', 99733, 52504, 4452, '2025-07-24 02:22:06.255784', '2025-07-15 02:52:24.100657', NULL, 1, 1, 1, NULL);
INSERT INTO quotes VALUES (7, 7, 'sell', 18675, 37653, 4740, '2025-02-05 00:43:06.635481', '2025-04-13 06:57:43.775858', '2025-06-28 18:14:16.077508', 5, 4, 4, NULL);
INSERT INTO quotes VALUES (8, 7, 'sell', 28726, 44718, 1571, '2025-03-26 11:17:48.800635', '2025-01-13 08:24:27.120636', '2025-02-15 00:30:46.666150', 2, 4, 10, NULL);
INSERT INTO quotes VALUES (9, 6, 'buy', 28131, 76784, 3021, '2025-07-27 12:49:48.300037', '2025-02-25 20:37:36.217266', NULL, 1, 1, 2, '2025-03-21 19:44:42.806922');
INSERT INTO quotes VALUES (10, 7, 'buy', 60432, 60019, 3440, '2025-06-15 03:33:05.750477', '2025-04-06 20:06:38.336708', NULL, 4, 4, 9, NULL);
INSERT INTO quotes VALUES (11, 1, 'buy', 99353, 80381, 4075, '2025-07-21 15:19:54.788315', '2025-07-29 15:57:23.533371', '2025-03-31 02:20:35.321617', 3, 4, 2, NULL);
INSERT INTO quotes VALUES (12, 1, 'sell', 75612, 109871, 1731, '2025-04-28 01:27:42.577870', '2025-06-01 07:37:20.207881', NULL, 5, 1, 5, NULL);
INSERT INTO quotes VALUES (13, 9, 'buy', 30032, 59009, 4123, '2025-03-04 11:53:10.779134', '2025-07-24 00:55:05.291021', '2025-02-02 14:30:45.721648', 2, 1, 10, NULL);
INSERT INTO quotes VALUES (14, 6, 'sell', 41385, 17592, 1986, '2025-05-02 23:48:41.591114', '2025-04-25 04:50:54.247563', NULL, 5, 1, 2, NULL);
INSERT INTO quotes VALUES (15, 2, 'buy', 26828, 96474, 2946, '2025-01-13 00:58:33.244059', '2025-05-04 01:04:24.236879', '2025-06-07 13:05:15.803396', 5, 1, 5, NULL);

-- Inserts for table: orders
INSERT INTO orders VALUES (1, 9, '2025-04-16 21:57:23.746051', '2025-03-31 02:20:35.321617', 11, NULL, 1382, 1);
INSERT INTO orders VALUES (2, 10, '2025-06-29 14:34:49.078418', '2025-06-28 18:14:16.077508', 7, '2025-02-09 03:21:46.377889', 1448, 1);
INSERT INTO orders VALUES (3, 7, '2025-02-03 03:50:14.782468', '2025-06-07 13:05:15.803396', 15, NULL, 1921, 1);
INSERT INTO orders VALUES (4, 4, '2025-07-22 08:49:44.028952', '2025-02-15 00:30:46.666150', 8, '2025-05-06 07:57:32.964219', 1529, 1);
INSERT INTO orders VALUES (5, 9, '2025-01-17 20:58:15.922681', '2025-02-02 14:30:45.721648', 13, '2025-05-23 05:15:49.648393', 1462, 2);

-- Inserts for table: card_purchases
INSERT INTO card_purchases VALUES (1, 4, 2, '19985f15-ff00-4d4d-9020-59e4ff9ab5c2', 71993, 2912, 'purchase', 'completed', '2025-01-29 06:51:15.761583', '2025-04-13 21:34:30.211840', 'Novaes', 'AblV');
INSERT INTO card_purchases VALUES (2, 1, 3, '8181a8cc-3691-47eb-89a2-688b12c136e0', 63354, 4538, 'purchase', 'completed', '2025-01-25 07:30:10.536321', '2025-07-10 16:33:43.995078', 'Novais', 'vYAZ');
INSERT INTO card_purchases VALUES (3, 2, 4, '5958a499-eeea-463e-a1e8-ac6843e42caf', 34957, 3986, 'purchase', 'completed', '2025-01-23 13:04:37.435696', '2025-06-28 05:08:05.588114', 'Camargo S/A', 'QVZp');
INSERT INTO card_purchases VALUES (4, 1, 2, '3e896c64-e117-4ac3-919c-4ea3e1805081', 22363, 1221, 'purchase', 'completed', '2025-04-27 12:35:53.572531', '2025-01-20 10:34:39.173811', 'Nogueira Andrade Ltda.', 'rkYS');
INSERT INTO card_purchases VALUES (5, 4, 5, '702cdd20-2862-48b8-88f4-ef125e9953d2', 22704, 3758, 'purchase', 'completed', '2025-02-27 08:44:46.183142', '2025-03-31 05:12:57.195605', 'Lopes Cardoso S/A', 'gycE');
INSERT INTO card_purchases VALUES (6, 2, 2, '4d71c366-b41b-4143-8b10-550cd5704f32', 96374, 3676, 'purchase', 'completed', '2025-05-08 09:28:20.648927', '2025-02-28 06:38:41.617164', 'Fonseca', 'omDw');
INSERT INTO card_purchases VALUES (7, 1, 5, 'ce9e1a11-fcbb-4e59-bbdd-cf7c9c96e9ec', 66498, 3646, 'purchase', 'completed', '2025-06-01 03:35:52.722532', '2025-01-01 17:55:25.666191', 'Fogaça S.A.', 'tYoo');
INSERT INTO card_purchases VALUES (8, 6, 5, 'aaf91531-0200-41f0-8768-a84fa76afde6', 56438, 1403, 'purchase', 'completed', '2025-02-12 21:12:13.723613', '2025-06-12 10:04:52.114405', 'Rios Caldeira Ltda.', 'bQmz');
INSERT INTO card_purchases VALUES (9, 2, 4, 'ee87905e-4ca4-45ea-8dfa-6a56d12dbc9a', 65519, 1248, 'purchase', 'completed', '2025-05-14 14:07:59.919410', '2025-05-15 04:40:07.770019', 'Pinto', 'vreX');
INSERT INTO card_purchases VALUES (10, 9, 2, 'e0ccedc5-f05d-476e-9a84-a51aa9d3d7c7', 63883, 2649, 'purchase', 'completed', '2025-02-25 14:27:49.588348', '2025-02-25 04:12:31.716435', 'da Costa Castro S.A.', 'rwPG');

-- Inserts for table: card_holder
INSERT INTO card_holder VALUES (1, 1, 1, '2025-02-19 12:58:41.156163', '2025-05-11 11:01:57.172882', '506e5a9a-b758-488d-ab73-295b344a54b8');
INSERT INTO card_holder VALUES (2, 10, 2, '2025-01-26 06:02:17.721718', '2025-03-30 07:13:18.803428', '21813d25-6552-48a6-83ff-50113d1a85dd');
INSERT INTO card_holder VALUES (3, 9, 3, '2025-07-07 12:29:13.911076', '2025-05-03 22:31:08.520117', '750cab75-4ccc-4bc2-a53f-8a28abf3e3fc');
INSERT INTO card_holder VALUES (4, 4, 4, '2025-02-21 20:38:31.350922', '2025-04-21 02:42:59.171722', 'ef8c485b-c07a-40f2-add4-253b50f0fd0a');
INSERT INTO card_holder VALUES (5, 10, 5, '2025-05-06 05:21:03.476071', '2025-07-16 21:01:45.082534', '9f044aed-7552-4327-8262-7f7312922f83');

-- Inserts for table: pix_transactions
INSERT INTO pix_transactions VALUES (1, 6, 'received', 'irocha@example.com', 'Nicolas Duarte', 'Macedo', 262.44, 'completed', NULL, '2025-07-06 15:30:23.415869', NULL, NULL);
INSERT INTO pix_transactions VALUES (2, 2, 'sent', 'camargovicente@example.org', 'Laís Novaes', 'Moraes Melo e Filhos', 4996.42, 'reversed', NULL, '2025-05-02 06:04:16.482569', NULL, NULL);
INSERT INTO pix_transactions VALUES (3, 4, 'received', 'breno19@example.com', 'Gael Leão', 'Ribeiro Barros Ltda.', 4181.78, 'pending', NULL, '2025-06-01 07:18:25.362900', NULL, NULL);
INSERT INTO pix_transactions VALUES (4, 4, 'received', 'ana-sophia69@example.net', 'Maria Helena Rocha', 'Borges', 4845.29, 'completed', NULL, '2025-03-22 21:02:51.854228', NULL, NULL);
INSERT INTO pix_transactions VALUES (5, 4, 'sent', 'gomesmateus@example.com', 'Srta. Liz Guerra', 'Rocha das Neves S.A.', 4632.57, 'reversed', NULL, '2025-03-26 04:16:59.879559', NULL, NULL);
INSERT INTO pix_transactions VALUES (6, 9, 'sent', 'santosluiza@example.org', 'Agatha da Rosa', 'Casa Grande Alves S/A', 4244.99, 'pending', NULL, '2025-02-01 01:59:13.954943', NULL, NULL);
INSERT INTO pix_transactions VALUES (7, 8, 'received', 'emanuellalopes@example.org', 'Gustavo Henrique Lopes', 'Melo Pimenta S/A', 839.89, 'reversed', NULL, '2025-05-25 19:59:48.527727', NULL, NULL);
INSERT INTO pix_transactions VALUES (8, 3, 'sent', 'ana-sophia14@example.net', 'Luna Martins', 'Leão', 2433.35, 'failed', NULL, '2025-07-08 00:28:49.699715', NULL, NULL);

-- Inserts for table: internal_transfers
INSERT INTO internal_transfers VALUES (1, 8, '@vasconceloslais', 4, '@cnovaes', 70.35, 'Tempora aspernatur corrupti fugit corrupti distinctio.', 'pending', NULL, '2025-02-24 19:06:53.834319', NULL, NULL);
INSERT INTO internal_transfers VALUES (2, 5, '@luiz-gustavosampaio', 5, '@maria-lauramachado', 320.47, 'Illum molestiae impedit dignissimos in temporibus.', 'pending', NULL, '2025-03-10 22:47:56.114970', NULL, NULL);
INSERT INTO internal_transfers VALUES (3, 7, '@jaragao', 4, '@thales48', 59.64, 'Veniam accusantium sunt nemo labore velit error harum.', 'completed', NULL, '2025-04-06 18:32:54.278518', NULL, NULL);
INSERT INTO internal_transfers VALUES (4, 9, '@joaquimmarques', 1, '@ppires', 482.02, 'Modi quasi reiciendis tempore laborum earum.', 'pending', NULL, '2025-03-13 02:05:50.736536', NULL, NULL);
INSERT INTO internal_transfers VALUES (5, 8, '@maria-fernandarios', 10, '@lunna14', 920.19, 'Adipisci excepturi perspiciatis illo cumque iusto consectetur.', 'pending', NULL, '2025-07-05 06:39:50.181778', NULL, NULL);
INSERT INTO internal_transfers VALUES (6, 3, '@luisa98', 9, '@yagofarias', 535.81, 'Modi tenetur nihil optio assumenda inventore sint delectus.', 'completed', NULL, '2025-02-28 14:36:49.333414', NULL, NULL);

