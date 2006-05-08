DROP TABLE battle_words;
DROP TABLE practice_words;
DROP TABLE equipment;
DROP TABLE items;
DROP TABLE titles;
DROP TABLE title_levels;
DROP TABLE title_sets;
DROP TABLE channels;
DROP TABLE games_players;
DROP TABLE games;
DROP TABLE players;
DROP TABLE words;

CREATE TABLE title_sets (
    id SERIAL PRIMARY KEY,
    name VARCHAR( 64 ) NOT NULL UNIQUE
);

CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    nick VARCHAR( 64 ) NOT NULL UNIQUE,
    creation_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    title_set_id INTEGER NOT NULL DEFAULT 0 REFERENCES title_sets( id ),
    warmup_points INTEGER DEFAULT 0,
    money INTEGER DEFAULT 0
);

CREATE TABLE words (
    id SERIAL PRIMARY KEY,
    word VARCHAR( 64 ) NOT NULL UNIQUE,
    pos VARCHAR( 32 ) NOT NULL,
    etymology VARCHAR( 256 ) NOT NULL,
    num_syllables INTEGER NOT NULL,
    definition VARCHAR( 512 ) NOT NULL,
    suggester INTEGER REFERENCES players( id )
);

CREATE TABLE battles (
    id SERIAL PRIMARY KEY,
    starter INTEGER NOT NULL REFERENCES players( id ),
    battle_mode VARCHAR( 16 ) NOT NULL
);

CREATE TABLE games (
    id SERIAL PRIMARY KEY,
    word_id INTEGER NOT NULL REFERENCES words( id ),
    start_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP,
    warmup_winner INTEGER REFERENCES players( id ),
    battle_id INTEGER REFERENCES battles( id )
);

CREATE TABLE participations (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES games( id ),
    player_id INTEGER NOT NULL REFERENCES players( id ),
    points_awarded INTEGER,
    team VARCHAR( 32 ) NOT NULL
);

CREATE TABLE channels (
    id SERIAL PRIMARY KEY,
    name VARCHAR( 64 ) NOT NULL
);

CREATE TABLE title_levels (
    id INTEGER PRIMARY KEY,
    points INTEGER NOT NULL
);

CREATE TABLE titles (
    id SERIAL PRIMARY KEY,
    title_set_id INTEGER NOT NULL REFERENCES title_sets( id ),
    title_level_id INTEGER NOT NULL REFERENCES title_levels( id ),
    text VARCHAR( 128 ) NOT NULL,
    UNIQUE( title_set_id, text )
);

CREATE TABLE items (
    id SERIAL PRIMARY KEY,
    code VARCHAR( 32 ) NOT NULL UNIQUE,
    name VARCHAR( 64 ) NOT NULL UNIQUE,
    price INTEGER NOT NULL,
    ownership_limit INTEGER NOT NULL DEFAULT 1
);
INSERT INTO items (code, name, price) VALUES ( 'glass-shield', 'Glass Shield', 300 );

CREATE TABLE equipment (
    id SERIAL PRIMARY KEY,
    player_id INTEGER NOT NULL REFERENCES players( id ),
    item_id INTEGER NOT NULL REFERENCES items( id ),
    equipped BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE practice_words (
    word_id INTEGER NOT NULL REFERENCES words( id )
);
CREATE TABLE battle_words (
    word_id INTEGER NOT NULL REFERENCES words( id )
);

CREATE OR REPLACE VIEW word_frequency AS
SELECT
    words.id,
    (
        SELECT count(*) AS count
        FROM games
        WHERE games.word_id = words.id
            AND games.warmup_winner IS NULL
    ) AS times_used
FROM words
GROUP BY words.id
;

CREATE OR REPLACE VIEW num_participants AS
SELECT
    game_id,
    count(*) AS num_participants
FROM
    participations
GROUP BY
    game_id
ORDER BY
    game_id;
    
CREATE OR REPLACE VIEW game_size_frequencies AS
SELECT
    p.player_id,
    n.num_participants,
    count(*) AS num_games
FROM
    participations p,
    num_participants n
WHERE
    p.game_id = n.game_id
GROUP BY
    p.player_id,
    n.num_participants
;
    