DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_likes;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  user_id INTEGER,
  question_id INTEGER
);

CREATE TABLE replies(
  id INTEGER PRIMARY KEY,
  question_id INTEGER,
  author_id INTEGER,
  body TEXT NOT NULL,
  parent_id INTEGER,

  FOREIGN KEY (question_id) REFERENCES questions(id)
  FOREIGN KEY (author_id) REFERENCES users(id)
  FOREIGN KEY (parent_id) REFERENCES replies(id)

);

CREATE TABLE question_likes (
  user_id INTEGER,
  question_id INTEGER
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Kevin','Lee'),
  ('Brill','Wang'),
  ('Francis','Lara');

INSERT INTO
  questions (title,body,author_id)
VALUES
  ('Why?', 'Why are you doing this to me? ~k', (SELECT id FROM users WHERE fname = 'Kevin' AND lname = 'Lee')),
  ('How?', 'How are penguins birds? ~b', (SELECT id FROM users WHERE fname = 'Brill' AND lname = 'Wang')),
  ('How?', 'Does tyler keep beating me at smash? ~f', (SELECT id FROM users WHERE fname = 'Francis' AND lname = 'Lara')),
  ('test', 'How dumb am i~f', 3);
INSERT INTO
  question_follows (user_id, question_id)
VALUES
  (2, 1),
  (1, 3),
  (3, 2),
  (1, 1),
  (3, 1);

INSERT INTO
  replies (author_id, question_id, body, parent_id)
VALUES
  (2, 1, 'because I can! ~brill', NULL),
  (1, 3, 'uhhhh ummmm marth is OP ~kevin', NULL),
  (3, 2, 'cuz they have wings and beaks bruh ~francis', NULL),
  (1, 1, 'thats not cool man. ~kevin', 1),
  (2, 3, 'yeah but marth is cheap. ~brill', 2),
  (3, 1, 'what do you mean? ~francis', NULL);

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  (2, 1),
  (1, 2),
  (2, 2),
  (3, 1),
  (2, 3);
