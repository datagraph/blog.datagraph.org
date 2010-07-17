[RDF.rb][] is approaching two thousand downloads [on RubyGems][RDF.rb downloads],
and while it has [good documentation][RDF.rb yardocs] it could still use
some more tutorials.  I recently needed to get RDF.rb working with a
PostgreSQL storage backend in order to work with RDF data in a [Rails 3.0][]
application hosted on [Heroku][].  I thought I'd keep track of what I did so
that I could discuss the notable parts.

In this tutorial we'll be implementing an RDF.rb storage adapter called
`RDF::DataObjects::Repository`, which is a simplified version of what I
eventually ended up with.  If you want the real thing, check it out on
[GitHub][GitHub project page] and read [the docs][RDF::DO yardocs].  This
tutorial will only cover the SQLite backend and won't concern itself with
database indexes, performance tweaks, or any other distractions from the
essential RDF.rb interfaces we'll focus on.  There's a copy of the
simplified code used in the tutorial at [the tutorial's project page][]. 
And should you be inspired to build something similar of your own, I have
set up an RDF.rb [storage adapter skeleton][] at GitHub.  Click _fork_, grep
for lines containing a `TODO` comment, and dive right in.

I'll mention, briefly, that I chose [DataObjects][] as the database
abstraction layer, but I don't want to dwell on that -- this post is about
RDF.  DataObjects is just a way to use common methods to talk to different
databases at the SQL level.  It's a leaky abstraction, because we'll want to
be using some SQL constraints to enforce statement uniqueness but those
constraints need to be done differently for different databases.  That means
we still have to get down to the level of database-specific SQL, distasteful
as that may be in this day and age.  However, given that I wanted to be able
to target PostgreSQL and SQLite both, DataObjects is still helpful.

#### Requirements

You just need a few gems for the example repository.  This ought to get you
going.  Even if you have these, make sure you have the latest; RDF.rb gets
updated frequently.

    $ sudo gem install rdf rdf-spec rspec do_sqlite3


## Testing First

So where do we start?  Tests, of course.  RDF.rb has factored out its mixin
specs to the [RDF::Spec][] gem, which provides the [RSpec shared example groups][]
that are also used by RDF.rb for its own tests.  Thus, here is the
complete spec file for the in-memory reference implementation of
`RDF::Repository`:

    require File.join(File.dirname(__FILE__), 'spec_helper')
    require 'rdf/spec/repository'
    
    describe RDF::Repository do
      before :each do
        @repository = RDF::Repository.new
      end
    
      # @see lib/rdf/spec/repository.rb
      it_should_behave_like RDF_Repository
    end

If you haven't seen something like this before, that's an RSpec shared
example group, and it's awesome.  Anything can use the same specs as RDF.rb
itself to verify that it conforms to the interfaces defined by RDF.rb, and
that's exactly what we'll be doing in this tutorial.  Let's implement that
for our repository:

    # spec/sqlite3.spec
    $:.unshift File.dirname(__FILE__) + "/../lib/"
    
    require 'rdf'
    require 'rdf/do'
    require 'rdf/spec/repository'
    require 'do_sqlite3'
    
    describe RDF::DataObjects::Repository do
      context "The SQLite adapter" do
        before :each do
          @repository = RDF::DataObjects::Repository.new "sqlite3::memory:"
        end
    
        after :each do
          # DataObjects pools connections, and only allows 8 at once.  We have
          # more than 60 tests.
          DataObjects::Sqlite3::Connection.__pools.clear
        end
    
        it_should_behave_like RDF_Repository
      end
    end

If you're new to RSpec, run the tests with the `spec` command:

    $ spec -cfn spec/sqlite3.spec

These fail miserably right now, of course, since we don't have an implementation.
So let's make one.

## Initial implementation

RDF.rb's interface for an RDF store is [`RDF::Repository`][RDF::Repository].  That interface
is itself composed of a number of mixins: `RDF::Enumerable`, `RDF::Queryable`,
`RDF::Mutable`, and `RDF::Durable`.

`RDF::Queryable` has a base implementation that works on anything which
implements `RDF::Enumerable`.  And `RDF::Durable` only provides boolean
methods for clients to ask if it is `durable?` or not; the default is that a
repository reports that it is indeed durable, so we don't need to do anything
there.

The takeaway is that to create an RDF.rb storage adapter, we need to implement
`RDF::Enumerable` and `RDF::Mutable`, and the rest will fall into place.
Indeed, the reference implementation is little more than an array which
implements these interfaces.

It turns out we can get away with just three methods to implement those two
interfaces:  `RDF::Enumerable#each`, `RDF::Mutable#insert_statement`, and
`RDF::Mutable#delete_statement`.  The default implementations will use these to
build up any missing methods.  That means we need to implement those first, so
that we have a base to pass our tests.  Then we can iterate further, replacing
methods which iterate over every statement with methods more appropriate for
our backend.

Here's a repository which doesn't implement much more than those three methods.
We'll use it as a starting point.

    # lib/rdf/do.rb

    require 'rdf'
    require 'rdf/ntriples'
    require 'data_objects'
    require 'do_sqlite3'
    require 'enumerator'
    
    module RDF
      module DataObjects
        class Repository < ::RDF::Repository
    
          def initialize(options)
            @db = ::DataObjects::Connection.new(options)
            exec('CREATE TABLE IF NOT EXISTS quads (
                  `subject` varchar(255), 
                  `predicate` varchar(255),
                  `object` varchar(255), 
                  `context` varchar(255), 
                  UNIQUE (`subject`, `predicate`, `object`, `context`))')
          end
   
          # @see RDF::Enumerable#each.
          def each(&block)
            if block_given?
              reader = result('SELECT * FROM quads')
              while reader.next!
                block.call(RDF::Statement.new(
                      :subject   => unserialize(reader.values[0]),
                      :predicate => unserialize(reader.values[1]),
                      :object    => unserialize(reader.values[2]),
                      :context   => unserialize(reader.values[3])))

              end
            else
              ::Enumerable::Enumerator.new(self,:each)
            end
          end
    
          # @see RDF::Mutable#insert_statement
          def insert_statement(statement)
            sql = 'REPLACE INTO `quads` (subject, predicate, object, context) VALUES (?, ?, ?, ?)'
            exec(sql,serialize(statement.subject),serialize(statement.predicate), 
                     serialize(statement.object), serialize(statement.context)) 
          end
    
          # @see RDF::Mutable#delete_statement
          def delete_statement(statement)
            sql = 'DELETE FROM `quads` where (subject = ? AND predicate = ? AND object = ? AND context = ?)'
            exec(sql,serialize(statement.subject),serialize(statement.predicate), 
                     serialize(statement.object), serialize(statement.context)) 
          end
    
    
          ## These are simple helpers to serialize and unserialize component
          # fields.  We use an explicit empty string for null values for clarity in
          # this example; we cannot use NULL, as SQLite considers NULLs as
          # distinct from each other when using the uniqueness constraint we
          # added when we created the table.  It would let us insert duplicate
          # with a NULL context.
          def serialize(value)
            RDF::NTriples::Writer.serialize(value) || ''
          end
          def unserialize(value)
            value == '' ? nil : RDF::NTriples::Reader.unserialize(value)
          end
    
          ## These are simple helpers for DataObjects
          def exec(sql, *args)
            @db.create_command(sql).execute_non_query(*args)
          end
          def result(sql, *args)
            @db.create_command(sql).execute_reader(*args)
          end

        end
      end
    end




And we have a repository.  Poof, done, that's it.  You can get a copy of this
intermediate repository at [the tutorial page][] and run the specs for yourself.  It's not
very efficient for SQL yet, but this is all it takes, strictly speaking.

Since they are so important, the three main methods deserve a little more attention:

### `each`

Each is the only thing we have to implement to get information out after we've
put it in.  `RDF::Enumerable` will provide us tons of things like
`each_subject`, `has_subject?`, `each_predicate`, `has_predicate?`, etc.  If
you were watching the spec output, you'll notice we ran tests for
`RDF::Queryable`.  The default implementation will use `RDF::Enumerable`'s
methods to implement basic querying.  This means we can already do things like:

    # Note that #load actually comes from insert_statement, see below
    repo.load('http://datagraph.org/jhacker/foaf.nt')
    repo.query(:subject => RDF::URI.new('http://datagraph.org/jhacker/foaf'))
    #=> RDF::Enumerable of statements with given URI as subject

Note that if a block is not sent, it's defined to return an
`Enumerable::Enumerator`.

`RDF::Queryable`, which defines `#query`, is probably the thing we can improve
the most on with SQL as opposed to the reference implementation.  We'll revisit
it below.

### `insert_statement`

`insert_statement` inserts an `RDF::Statement` into the repository.  It's
pretty straightforward.  It gives us access to default implementations of
things like `RDF::Mutable#load`, which will load a file by name or import a
remote resource:

    repo.load('http://datagraph.org/jhacker/foaf.nt')
    repo.count
    #=> 10

### `delete_statement`

`delete_statement` deletes an `RDF::Statement`. Again, it's straightforward, and it's
used to implement things like `RDF::Mutable#clear`, which empties the
repository:

    repo.load('http://datagraph.org/jhacker/foaf.nt')
    repo.clear
    repo.count
    #=> 0

## Iterate and Improve

Since we already have a nice test suite that we can pass, we can add
functionality incrementally.  For example, let's implement
`RDF::Enumerable#count` in a fashion that does not require us to enumerate each
statement, which is clearly not ideal for a SQL-based system:

    # lib/rdf/do.rb


    def count
      result = result('SELECT COUNT(*) FROM quads')
      result.next!
      result.values.first
    end

The tests still pass, we can move on.  Wash, rinse, repeat; probably every method
in `RDF::Enumerable` and `RDF::Mutable` can be done more efficiently with SQL.

### `RDF::Queryable`

`RDF::Queryable` is worth mentioning on its own, because the interface takes a
lot of options.  Specifically, it can take a Hash, a smashed Array, an
RDF::Statement, or a Query object.  Fortunately, we can call `super` to defer
to the reference implementation if we get arguments we don't understand, so we
can again be iterative here.

We can start by implementing the hash version, which is the most convienent for
doing the actual SQL query later.  The hash version takes a hash which may have
keys for `:subject`, `:predicate`, `:object`, and `:context`, and returns an
`RDF::Enumerable` which contains all statements matching those parameters


    # lib/rdf/do.rb

          def query(pattern, &block)
            case pattern
              when Hash
                statements = []
                reader = query_hash(pattern)
                while reader.next!
                  statements << RDF::Statement.new(
                          :subject   => unserialize(reader.values[0]),
                          :predicate => unserialize(reader.values[1]),
                          :object    => unserialize(reader.values[2]),
                          :context   => unserialize(reader.values[3]))
                end
                case block_given?
                  when true
                    statements.each(&block)
                  else
                    statements.extend(RDF::Enumerable, RDF::Queryable)
                end
              else
                super(pattern) 
            end
          end

          def query_hash(hash)
            conditions = []
            params = []
            [:subject, :predicate, :object, :context].each do |resource|
              unless hash[resource].nil?
                conditions << "#{resource.to_s} = ?"
                params     << serialize(hash[resource])
              end
            end
            where = conditions.empty? ? "" : "WHERE "
            where << conditions.join(' AND ')
            result('SELECT * FROM quads ' + where, *params)
          end

Our specs still pass.  Note this trick:

    statements.extend(RDF::Enumerable, RDF::Queryable)

`RDF::Queryable` is defined to return something which implements `RDF::Enumerable`
and `RDF::Queryable`.  Since the only thing we need to implement `RDF::Enumerable`
is `#each`, and `Array` already implements that, we can simply extend this `Array`
instance with the mixins and return it.

Note also that while we have taken care of the hard part, we're still calling the
reference implementation if we don't know how to handle our arguments.  Now we
can start adding those other query arguments:

    # lib/rdf/do.rb

          def query(pattern, &block)
            case pattern
              when RDF::Statement
                query(pattern.to_hash)
              when Array
                query(RDF::Statement.new(*pattern))
              when Hash
          .
          .
          .

Our specs still pass!  Moving on, there's a lot more we can implement.  And
once we have implemented it in a straightforward way, we can still implement
things like multiple inserts, paging, and more, all transparant to the user.
You can see the full list of methods to implement in the docs, but don't be
afraid to dive into the code.

If you do, don't forget that RDF.rb is completely [public domain][], so if you want to
copy-paste to bootstrap your implementation, feel free.

#### Any questions?

Hopefully this is enough to get you started.  Remember, the code is at
[the tutorial page][], and don't forget to check out the [storage adapter skeleton][].
The [RDF.rb documentation][RDF.rb yardocs] have a lot of information on the
APIs you'll be using.

And last but not least, a good place to ask questions or leave a comment is on
the [W3C RDF-Ruby mailing list][mailing list].


[RDF.rb]:                       http://blog.datagraph.org/2010/03/rdf-for-ruby
[RDF.rb downloads]:             http://rubygems.org/gems/rdf
[RDF.rb yardocs]:               http://rdf.rubyforge.org/
[Rails 3.0]:                    http://guides.rails.info/3_0_release_notes.html
[Heroku]:                       http://heroku.com/
[DataObjects]:                  http://github.com/datamapper/do
[GitHub project page]:          http://github.com/bhuga/rdf-do
[RDF::DO yardocs]:              http://rdf.rubyforge.org/do/
[the tutorial's project page]:  http://github.com/bhuga/rdf-repository-howto
[RSpec shared example groups]:  http://rspec.info/documentation/
[RDF::Spec]:                     http://rdf.rubyforge.org/spec/
[RDF::Repository]:              http://rdf.rubyforge.org/RDF/Repository.html
[the tutorial page]:            http://github.com/bhuga/rdf-repository-howto
[storage adapter skeleton]:     http://github.com/bhuga/rdf-repository-skeleton
[public domain]:                http://unlicense.org/
[mailing list]:                 http://lists.w3.org/Archives/Public/public-rdf-ruby/
