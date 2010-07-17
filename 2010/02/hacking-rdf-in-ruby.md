[RDF.rb](http://rubygems.org/gems/rdf) is easily the most fun RDF
library I've used.  It uses Ruby's dynamic system of mixins to create
a library that's very easy to use.

If you're new at Ruby, you might know about mixins in other
languages--[Scala traits](http://www.scala-lang.org/node/126), for
example, are almost exactly functionally equivalent.  They're
distinctly more powerful than Java interfaces or abstract classes.  A
mixin is basically an interface and an abstract class rolled into one.
 Rather than extend an abstract class, one includes a mixin into your
own class.  A mixin will usually require that a given class implement
a particular method.  Ruby's own `Enumerable` class, for example,
requires that implementing classes implement `#each`.  For that tiny
bit of trouble, you get a ton of methods (listed
[here](http://ruby-doc.org/core/classes/Enumerable.html)), including
iterators, mapping, partitions, conversion to arrays, and more.  (If
you're new to Ruby, it might also help you to know that `#method_name`
means 'an instance method named `method_name`').

RDF.rb uses the principle extensively.  `RDF::Repository` is, in fact,
little more than an in-memory reference implementation for 4 traits:
`RDF::Enumerable`, `RDF::Mutable`, `RDF::Queryable`, and
`RDF::Durable`.  `RDF::Sesame::Repository` has the exact same
interface as the in-memory representation, but is based entirely on a
Sesame server.  In order to work as a repository,
`RDF::Sesame::Repository` only had to extend the reference
implementation and implement `#each`, `#insert_statement`, and
`#delete_statement`.  Nice!  Of course, implementing those took some
doing, but it's still exceedingly easy.

[`RDF::Enumerable`](http://rdf.rubyforge.org/RDF/Enumerable.html) is
the key here.  For implementing an `#each` that yields
`RDF::Statement` objects, one gains a ton of functionality:  `#each_subject`,
`#each_predicate`, `#each_object`, `#each_context`, `#has_subject?`,
`#has_triple?`, and more.  It's a key abstraction that provides huge
amounts of functionality.

But the module system goes the other way--not only is it easy to
implement new RDF models, existing ones are easily extended.  I
recently wrote [`RDF::Isomorphic`](http://github.com/bhuga/RDF-Isomorphic),
which extends RDF::Enumerable with `#bijection_to` and
`#isomorphic_with?` methods.  The module-based system provided by
RDF.rb means that my isomorphic methods are now available on
`RDF::Sesame::Repositories`, and indeed anything which includes
`RDF::Enumerable`.  This is everything from repositories to graphs to
query results!  In fact, query results themselves implement
`RDF::Enumerable`, and thus implement `RDF::Queryable` and can be
checked for isomorphism, or whatever else you want to add.  This is
functionality that Sesame does not have natively, and which I wrote
for a completely different purpose (testing parsers).  Every
`RDF::Enumerable` gets it for free because I wanted to compare 2 textual
formats.  Neat!

For example, here's what it takes to extend any RDF collection, from
`RDF::Isomorphic`:

    require 'rdf'
    module RDF
      ##
      # Isomorphism for RDF::Enumerables
      module Isomorphic

        def isomorphic_with(other)
          # code that uses #each, or any other method from RDF::Enumerable goes here
          ...
        end

        def bijection_to(other)
          # code that uses #each, or any other method from RDF::Enumerable goes here
             ...
        end
      end

      # re-open RDF::Enumerable and add the isomorphic methods
      module Enumerable
        include RDF::Isomorphic
      end
    end

Of course, this just can't be done without [monkey
patching.](http://en.wikipedia.org/wiki/Monkey_patch)  Mixins and
monkey patching together make for a powerful toolkit.  To my
knowledge, this is the first RDF library that takes advantage of these
features.

It's possible to provide powerful features to a wide range of
implementations with this.  RDF.rb does not yet have a inference
layer, but any such layer would instantly work for any store which
implements `RDF::Enumerable`.  Want to prototype some custom business
logic that operates over existing RDF data?  Copy it into a local
repository and hack away.  No need for the production RDF store to be
the same at all, but you can still apply the same code.

As a counter-example, compare this to the Java RDF ecosystem.  There
are some excellent implementations (`RDF::Isomorphic` is heavily in
debt to Jena), but they're all incompatible.  Jena's check for
isomorphism is not really translatable to Sesame, or anything else.
RDF.rb, in addition to providing a reference implementation, acts as
an abstraction layer for underlying RDF implementations.  The
difference is night and day--with RDF.rb, you only need to implement a
feature once, at the API layer, to have it apply to any
implementation.  This is not a knock at the very talented people
behind those Java implementations; making this happen is a lot of work
in a language without monkey patching, and RDF.rb is only as good as
it is because of the significant influences those projects have been
on [Arto's](http://ar.to) design.

The end result of the mixin-based approach is a system that is
incredibly easy to extend, and just downright fun.  It would be a
fairly simple task to extend a Ruby class completely unrelated to RDF
with an `#each` method that yields statements, allowing it to work in
[`RDF::Enumerable`](http://rdf.rubyforge.org/RDF/Enumerable.html).
Voila, your existing classes now have an RDF representation.  Along
the same lines, if one is bothered by the statement-oriented nature of
RDF.rb, building a system which took a resource-oriented view would
not require one to 'break away' from the RDF.rb ecosystem.  Just build
your subject-oriented model objects and implement `#each`, and away you
go--you can now run RDF queries and test isomorphism on your model.
Build it to accept an `RDF::Enumerable` in the constructor and you can
use any existing repository or query to initialize your model.

RDF.rb is not yet ready for production use, but it's under heavy
development and already quite useful.  Give it a shot.  You can post
any issues in the [GitHub issue
queue](http://github.com/bendiken/rdf/issues).
