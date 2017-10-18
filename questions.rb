require 'sqlite3'
require 'singleton'
require 'active_support/inflector'

class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end

end




class ModelBase

  def self.find_by_id(id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT *
      FROM #{self.table}
      WHERE id = ?
    SQL
    return nil unless data.length > 0
    self.new(data.first)
  end

  def self.all

    data = QuestionsDBConnection.instance.execute(<<-SQL)
      SELECT *
      FROM #{self.table}
    SQL
    data.map {|datum| self.new(datum)}
  end

  def self.table
    "#{self}".tableize
  end

  def save
    if @id
      update
    else
      QuestionsDBConnection.instance.execute(<<-SQL,  *self.instance_variables.map(&:to_s), *self.instance_variables)
        INSERT INTO
          self.table (?, ?)
        VALUES
          (?, ?)
      SQL

      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end

  def update
    raise "user does not exist in db!" unless @id

    QuestionsDBConnection.instance.execute(<<-SQL, *self.instance_variables)
      UPDATE
        self.table
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end

  k = 1
  v = 5
  a = 3

  "[k, v, a] = [1, 5, 3]"


  def self.where(options)
    QuestionsDBConnection.instance.execute(<<-SQL, *options.keys, *options.values)
      SELECT
        #{self}
      FROM
        self.table
      WHERE
        ? = ?
    SQL
  end

end





class User < ModelBase
  attr_reader :id
  attr_accessor :fname, :lname

  def authored_replies
    Reply.find_by_author_id(@id)
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end


  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def save
    if @id
      update
    else
      QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname)
        INSERT INTO
          users (fname, lname)
        VALUES
          (?, ?)
      SQL

      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end

  def update
    raise "user does not exist in db!" unless @id

    QuestionsDBConnection.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end

  def self.find_by_name(fname, lname)
    data = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
      SELECT *
      FROM users
      WHERE fname = ? AND lname = ?
    SQL

    return nil unless data.length > 0
    User.new(data.first)
  end

  def followed_questions
    QuestionFollow.followed_for_user_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def average_karma
    data = QuestionsDBConnection.instance.execute(<<-SQL, @id)
      SELECT CAST(COUNT(user_id) AS FLOAT)/ COUNT(DISTINCT(questions.id)) AS avg_karma
      FROM questions
      LEFT JOIN question_likes ON question_id = questions.id
      WHERE author_id = ?
    SQL

    return nil unless data.length > 0
    data.first['avg_karma']
  end

end











class Question < ModelBase
  attr_reader :id
  attr_accessor :title, :body, :author_id


  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def save
    if @id
      update
    else
      QuestionsDBConnection.instance.execute(<<-SQL, @title, @body, @author_id)
        INSERT INTO
          questions(title, body, author_id)
        VALUES
          (?, ?, ?)
      SQL

      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end

  def update
    raise "question does not exist in db!" unless @id

    QuestionsDBConnection.instance.execute(<<-SQL, @title, @body, @author_id, @id)
      UPDATE
        questions
      SET
        title = ?, body = ?, author_id = ?
      WHERE
        id = ?
    SQL
  end

  def self.find_by_author_id(author_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
      SELECT *
      FROM questions
      WHERE author_id = ?
    SQL

    return nil unless data.length > 0
    data.map { |datum| Question.new(datum) }
  end


  def self.find_by_title(title)
    data = QuestionsDBConnection.instance.execute(<<-SQL, title)
      SELECT *
      FROM questions
      WHERE title = '%?%'
    SQL

    return nil unless data.length > 0
    Question.new(data.first)
  end

  def author
    data = QuestionsDBConnection.instance.execute(<<-SQL)
      SELECT *
      FROM users
      WHERE id = @author_id
    SQL

    User.new(data.first)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def followers
    QuestionFollow.followers_for_question_id(@id)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end
end









class QuestionFollow < ModelBase
  def self.most_followed_questions(n)
    data = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT *
      FROM question_follows
      JOIN questions ON question_id = questions.id
      GROUP BY question_id
      ORDER BY COUNT(user_id) DESC
      LIMIT ?
    SQL

    return nil unless data.length > 0
    data.map { |datum| Question.new(datum) }
  end

  def self.followers_for_question_id(question_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT *
      FROM question_follows
      JOIN users ON user_id = users.id
      WHERE question_id = ?
    SQL

    return nil unless data.length > 0
    data.map { |datum| User.new(datum) }
  end

  def self.followed_for_user_id(user_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM question_follows
      JOIN questions ON question_id = questions.id
      WHERE user_id = ?
    SQL
    return nil unless data.length > 0
    data.map { |datum| Question.new(datum) }
  end


  def initialize(options)
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
end













class Reply < ModelBase
  attr_reader :id
  attr_accessor :question_id, :body, :author_id, :parent_id

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @body = options['body']
    @author_id = options['author_id']
    @parent_id = options['parent_id']
  end

  def save
    if @id
      update
    else
      QuestionsDBConnection.instance.execute(<<-SQL, @author_id, @question_id, @body, @parent_id)
        INSERT INTO
          replies(author_id, question_id, body, parent_id)
        VALUES
          (?, ?, ?, ?)
      SQL

      @id = QuestionsDBConnection.instance.last_insert_row_id
    end
  end

  def update
    raise "reply does not exist in db!" unless @id

    QuestionsDBConnection.instance.execute(<<-SQL, @author_id, @question_id, @body, @parent_id, @id)
      UPDATE
        replies
      SET
        author_id = ?, question_id = ?, body = ?, parent_id = ?
      WHERE
        id = ?
    SQL
  end

  def author
    data = QuestionsDBConnection.instance.execute(<<-SQL, @author_id)
      SELECT *
      FROM users
      WHERE id = ?
    SQL

    return nil unless data.length > 0
    User.new(data.first)
  end

  def question
    data = QuestionsDBConnection.instance.execute(<<-SQL, @question_id)
      SELECT *
      FROM questions
      WHERE id = ?
    SQL

    return nil unless data.length > 0
    Question.new(data.first)
  end

  def parent_reply
    data = QuestionsDBConnection.instance.execute(<<-SQL, @parent_id)
      SELECT *
      FROM replies
      WHERE id = ?
    SQL

    return nil unless data.length > 0
    Reply.new(data.first)
  end

  def child_replies
    data = QuestionsDBConnection.instance.execute(<<-SQL, @id)
      SELECT *
      FROM replies
      WHERE parent_id = ?
    SQL

    return nil unless data.length > 0
    data.map { |datum| Reply.new(datum) }
  end


  def self.find_by_author_id(author_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
      SELECT *
      FROM replies
      WHERE author_id = ?
    SQL

    return nil unless data.length > 0
    data.map { |datum| Reply.new(datum) }
  end


  def self.find_by_question_id(question_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT *
      FROM replies
      WHERE question_id = ?
    SQL

    return nil unless data.length > 0
    data.map { |datum| Reply.new(datum) }
  end
end







class QuestionLike < ModelBase
  attr_accessor :user_id, :question_id


  def initialize(options)
    @user_id = options['user_id']
    @question_id = options['question_id']
  end

  def self.likers_for_question_id(question_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT *
      FROM question_likes
      JOIN users ON user_id = users.id
      WHERE question_id = ?
    SQL

    return nil unless data.length > 0
    data.map { |datum| User.new(datum) }
  end

  def self.num_likes_for_question_id(question_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, question_id)
      SELECT COUNT(user_id) AS count
      FROM question_likes
      GROUP BY question_id
      HAVING question_id = ?
    SQL

    return data.first['count']
  end

  def self.liked_questions_for_user_id(user_id)
    data = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT *
      FROM question_likes
      JOIN questions ON question_id = questions.id
      WHERE user_id = ?
    SQL

    return nil unless data.length > 0
    data.map { |datum| Question.new(datum) }
  end

  def self.most_liked_questions(n)
    data = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT *
      FROM question_likes
      JOIN questions ON question_id = questions.id
      GROUP BY question_id
      ORDER BY COUNT(user_id) DESC
      LIMIT ?
    SQL

    return nil unless data.length > 0
    data.map { |datum| Question.new(datum) }
  end





end
