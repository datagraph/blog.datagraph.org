I've just released Spira, a first draft of an RDF ORM, where the 'R' can mean RDF
or Resource at your pleasure.  It's an easy way to create Ruby objects out of
RDF data.  The name is from Latin, for 'breath of life'--it's time to
give those resource URIs some character.  It looks like this (feel free to
copy-paste):

    require 'spira'
    require 'rdf/ntriples'

    repo = "http://datagraph.org/jhacker/foaf.nt"
    Spira.add_repository(:default, RDF::Repository.load(repo))

    class Person
      include Spira::Resource

      property :name,  :predicate => FOAF.name
      property :nick,  :predicate => FOAF.nick
    end
  
    jhacker = RDF::URI("http://datagraph.org/jhacker/#self").as(Person)
    jhacker.name #=> "J. Random Hacker"
    jhacker.nick #=> "jhacker"
    jhacker.name = "Some Other Hacker"
    jhacker.save!


## Why a new project?

I try not to start new projects lightly.  There's plenty of good stuff out
there.  But there wasn't quite what I wanted.

First of all, I want to program in Ruby, so it needed to be Ruby.  Spira, while
different, has a lot of overlap with a traditional ORM, and I was on the fence
for a while about starting Spira or trying to implement things in DataMapper.
There's already an [RDF.rb][] backend for DataMapper, which is cool, but using it
really cuts you off from RDF as RDF.  It's more about making RDF work how
DataMapper likes it.  DataMapper's storage adapter interface is an implicit
data model, one that is not RDF's, and it is not quite what I wanted.

On the RDF-specific front, there's ActiveRDF.  ActiveRDF is based on SPARQL
directly, and thus, while not hiding RDF from you, only gives you access via
Redland.  The Redland Ruby bindings have problems, and do not represent the
entire RDF ecosystem.  I wanted to start on something that completely
abstracted away the data model, so I could focus on the problem at hand, which
means RDF.rb.  The difference is in allowing me to focus on what I'm focusing
on: there exists a perfectly good, working SPARQL client storage adapter for
RDF.rb, but it's one of many pluggable backends instead of a requirement.

Lastly, while both of those projects would represent a workable starting point,
this was something of a journey of exploration in terms of semantics.  Spira
was going to be <strike>'open world'</strike> 'open model' from the start; I
specifically wanted something that could read foreign data.  By 'open model' I
mean that Spira does not expect that a class definition is the authoritative,
exclusive, or complete definition of a model class.  That turns out to make
Spira have some important semantic differences from ORMs oriented around object
or relational databases.  Stumbling on them was part of the fun, and even if I
could have twisted DataMapper around the problem, I'm not sure that starting
from there would have had me focusing on the core semantics.

So I decided to start something new.  To be fair, Spira would suck a lot more
were it not for the projects that came before it.  In particular, it owes an
intellectual debt to DataMapper, which has a generally sane model, readable
code, and had to cover a lot of ground that any object-whatever-mapper would.
It takes some digging, but as an example, one can find [IRC logs][] where the
DataMapper team discusses the ups and downs of identity map implementations in
Ruby.  That stuff is amazing to have available without spending hundreds of
hours fighting it yourself, and again, it saves me a lot of trial and error on
ancilliary considerations.

## Making things simple

Spira's core use case is allowing programmers to create Ruby objects
representing an aspect of an RDF resource.  I'm still working on which
terminology I like best, but I am leaning towards calling instances of Spira
classes 'a projection of a given RDF resource as a Spira resource.'  In the
simplest of terms, Spira tries to let you create classes that easily get and
set values for properties that correspond to RDF predicates.  The README will
explain it better than I want to in this post (now available in [Github][] and
[Yardoc][] flavors).

The hopeful end result is a way to access the RDF data model in a way that
agile web programmers have come to expect, without forcing them to get bogged
down into a world of ontologies, rule languages, inference levels, and lord
knows what-all else.  RDF has taken off in the enterprise because of power user
features, and we're approaching a critical mass of RDFa publishing, but it's
not yet on anyone's radar as a data model for their next weekend project.  I
think that's a shame--RDF's schema-free model should be the easiest thing in
the world to get started on.  So in addition to hopefully being an open-model
ORM, here's hoping Spira is a step in the adoption of RDF as a day-to-day data
model.

## So what's 'Open Model' mean?

Any useful abstraction layer is about applying constraints.  Normal ORMs hide
the power of relational databases to make them into proper object databases.
Spira constrains you to a particular aspect of a resource.  That means that in
the aspect of 'Person', a resource's name is a given predicate, and they only
have one.  A person might also have a label, multiple names, a comment,
function as a category or tag, have friends, have accounts, have tons of other
stuff, but if all you want is their age, you just want to say `person.name` and
`person.age`.  The goal here is to let you use data (or at least, to have
defined behavior for data) that you cannot say for sure meets any sort of
criteria you set in Spira.  Spira will have defined behavior for when data does
not match a model class, and will still let you use that data easily,
pretending it came from a closed system.  That's good enough surprisingly often.

That open-model part is where tough semantics come in.  As an example, I had
intended to publish, with Spira, a reference implementation of SIOC.  The SIOC
core classes are in widespread use, so surely this would find some use, I
figured.  But it's not so simple to make a reference implementation unless you
limit your possibilities.  For example, a SIOC post can have topics (a sub-class of
dcterms:subject).  These topics are RDF resources which may be one (or, I
suppose, both, or neither) of two classes defined in the [SIOC types ontology][],
Category or Tag.  These two classes have completely different
semantics.  Now, a Spira class could be created to deal with either of them,
but to use that class usefully, you'd always be checking what it is, since the
semantics are different.  Spira will eventually have helpers to help you decide
what to do here, but the point is that in RDF, a 'reference implementation'
often doesn't make sense as a concept.  However, this is at least in principle
representable in Spira--I'm not sure it could be done in a traditional ORM, as
it doesn't really match the single-table inheritance model.

Instead, I hope Spira classes are simple enough--throw away, even--that you
can define them when you need them.  Indeed, defining them programmatically
is obvious with the framework in place, I just haven't done it yet.

Another example of differing semantics would be instance creation.  An RDF
resource does not 'exist or not'.  It's either the subject of triples or not.
So what would it mean to create an instance of a Spira resource and save it
when it had no fields?  Would one save a triple declaring the resource to be an
RDF resource?  How about saving the RDF type, should that happen if one has not
saved fields?  There are good arguments for several options.  It's just not the
same model as the 'find, create, find_or_create' trio of constructors that the
world has grown used to, since the identifiers are global and always exist.
Primary keys do not come into existence to allow reference to an object, the
key *is* the object.  I dodged the question and now do construction based on
`RDF::URI`s.

Instantiation looks either like this:

    RDF::URI("http://example.org/bob").as(Person)

or like this:

    Person.for(RDF::URI("http://example.org/bob"))

There's no finding or creating.  Resources just are.  Creating a Spira object
is creating the projection of that resource as a class.  If you've told Spira
about a repository where some information about that resource may or may not
exist, great, but it's not required.

As another example, I see a lot of need for validations on creating an
instance, not just saving one, as in traditional ORMs.  RDF is not like the
data fed to a traditional ORM, which is generally created by that ORM or by a
known list of applications, managed by a set of hard constraints and schema.
RDF data is often found, and used, in the wild.

There's still a ton left to do, but lots of stuff already works.  The
[README][] has a good rundown of where things stand.  I'd enumerate the to-do
list, but I'd rather not feed that to Google, and it's long enough anyway that
if certain deficencies quickly become obvious, I'd attack them first.

Anyways, hope someone has fun with it.  `gem install spira` are the magic
words.  If you want to spoil the magic, the code is [on Github][].

<em><small>The original version of this post used the term 'Open World' instead of 'Open
Model' willy-nilly throughout, but I was corrected from using the term outside
its strict meaning in terms of inference.  See the comments.  If a term exists
for what I'm describing at this level of abstraction, I'm all ears.</small></em>

[IRC logs]:             http://groups.google.com/group/datamapper/browse_thread/thread/570fee8fbcdf0c08
[Github]:               http://github.com/datagraph/spira
[Yardoc]:               http://spira.rubyforge.org
[SIOC types ontology]:  http://rdfs.org/sioc/types
[README]:               http://github.com/datagraph/spira
[RDF.rb]:               http://rdf.rubyforge.org
[on github]:            http://github.com/datagraph/spira
