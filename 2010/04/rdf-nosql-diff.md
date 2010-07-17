_This [started out][origin] as an answer at [Semantic Overflow][] on how RDF database systems differ from other currently available NoSQL solutions. I've here expanded the answer somewhat and added some general-audience context._

[RDF][] database systems are the only standardized [NoSQL][] solutions available at the moment, being built on a [simple, uniform data model][RDF intro] and a [powerful, declarative query language][SPARQL]. These systems offer data portability and toolchain interoperability among the dozens of competing implementations that are available at present, avoiding any need to bet the farm on a particular product or vendor.

In case you're not familiar with the term, NoSQL ("Not only SQL") is a [loosely-defined](http://nosql-database.org/) umbrella moniker for describing the new generation of non-relational database systems that have sprung up in the last several years. These systems tend to be inherently distributed, schema-less, and horizontally scalable. Present-day NoSQL solutions can be broadly categorized into four groups:

* **Key-value databases** are familiar to anyone who has worked with the likes of the venerable [Berkeley DB][]. These systems are about as simple as databases get, being in essence variations on the theme of a persistent hash table. Current examples include [MemcacheDB][], [Tokyo Cabinet][], [Redis][] and [SimpleDB][].

* **Document databases** are key-value stores that treat stored values as [semi-structured data][semi-structured] instead of as opaque blobs. Prominent examples at the moment include [CouchDB][], [MongoDB][] and [Riak][].

* **Wide-column databases** tend to draw inspiration from Google's [BigTable][] model. Open-source examples include [Cassandra][], [HBase][] and [Hypertable][].

* **Graph databases** include generic solutions like [Neo4j][], [InfoGrid][] and [HyperGraphDB][] as well as all the numerous RDF-centric solutions out there: [AllegroGraph][], [4store][], [Virtuoso][], and [many, many others][RDF databases].

RDF database systems form the largest subset of this last NoSQL category. RDF data can be thought of in terms of a decentralized [directed labeled graph][directed graph] wherein the arcs start with subject URIs, are labeled with predicate URIs, and end up pointing to object URIs or scalar values. Other equally valid ways to understand RDF data include the resource-centric approach (which maps well to object-oriented programming paradigms and to [RESTful][REST] architectures) and the statement-centric view (the _object-attribute-value_ or [EAV][] model).

Without just now extolling too much the virtues of RDF as a _particular_ data model, the key differentiator here is that RDF database systems embrace and build upon W3C's [Linked Data][] technology stack and are the only _standardized_ NoSQL solutions available at the moment. This means that RDF-based solutions, when compared to run-of-the-mill NoSQL database systems, have benefits such as the following:

* **A simple and uniform standard data model.** NoSQL databases typically have one-off, ad-hoc data models and capabilities designed specifically for each implementation in question. As a rule, these data models are neither interoperable nor standardized. Take e.g. Cassandra, which has a somewhat baroque [data model][Cassandra model] that "can most easily be thought of as a four or five dimensional hash" and the specifics of which are described in a wiki page, [blog posts][Cassandra WTF] here and there, and ultimately only nailed down in version-specific API documentation and the code base itself. Compare to RDF database systems that all share the same [well-specified and W3C-standardized][RDF] data model at their base.

* **A powerful standard query language.** NoSQL databases typically [do not provide][NoSQL slideshow] any high-level [declarative][] query language equivalent of SQL. Querying these databases is a programmatic data-model-specific, language-specific and even application-specific affair. Where query languages do exist, they are entirely implementation-specific (think SimpleDB or GQL). [SPARQL][] is a very big win for RDF databases here, providing a standardized and interoperable query language that even non-programmers can make use of, and one which meets or exceeds SQL in its capabilities and power while retaining much of the familiar syntax.

* **Standardized data interchange formats.** RDBMSes have (somewhat implementation-specific) SQL dumps, and some NoSQL databases have import/export capability from/to implementation-specific structures expressed in an XML or JSON format. RDF databases, by contrast, all have import/export capability based on well-defined, standardized, entirely implementation-agnostic serialization formats such as [N-Triples][] and [N-Quads][].

From the preceding points it follows that RDF-based NoSQL solutions enjoy some very concrete advantages such as:

* **Data portability.** Should you need to switch between competing database systems in-house, to make use of multiple different solutions concurrently, or to share data with external parties, your data travels with you without needing to write and utilize any custom glue code for converting some ad-hoc export format and data structure into some other incompatible ad-hoc import format and data structure.

* **Toolchain interoperability.** The RDBMS world has its various database abstraction layers, but the very concept is nonsensical for NoSQL solutions in general (see "ad-hoc data model"). RDF solutions, however, represent a special case: libraries and toolchains for RDF are typically only loosely coupled to any particular DBMS implementation. Learn to use and program with [Jena][] or [Sesame][] for Java and Scala, [RDFLib][] for Python, or [RDF.rb][] for Ruby, and it generally doesn't matter which particular RDF-based system you are accessing. Just as with RDBMS-based database abstraction layers, your RDF-based code does not need to change merely because you wish to do the equivalent of switching from MySQL to PostgreSQL.

* **No vendor or product lock-in.** If the RDF database solution *A* was easy to get going with but eventually for some reason hits a brick wall, just switch to RDF database solution *B* or *C* or any other of the many available interoperable solutions. Unlike switching between two non-RDF solutions, this does not have to be a big deal. Needless to say there are also ecosystem benefits with regards to the available talent pool and the commercial support options.

* **Future proof.** With RDF now [emerging][Tim BL @ TED] as the definitive standard for publishing [Linked Data][] on the web, and being entirely built on top of indelibly-established lower-level standards like [URIs][URI], it's not an unreasonable bet that your RDF data will still be usable as-is by, say, [2038][Y2K38]. It's not at all evident, however, that the same could be asserted for any of the other NoSQL solutions out there at the moment, many which will inevitably prove to be rather short-lived in the bigger picture.

RDF-based systems also offer unique advantages such as support for globally-addressable row identifiers and property names, web-wide decentralized and dynamic schemas, data modeling standards and tooling for creating and publishing such schemas, metastandards for being able to declaratively specify that one piece of information entails another, and inference engines that implement such data transformation rules.

All these features are mainly due to the characteristics and capabilities of RDF's data model, though, and have already been amply described elsewhere, so I won't go further into them just here and now. If you wish to learn more about RDF in general, a great place to start would be the excellent [RDF in Depth](http://rdfabout.com/intro/?section=contents) tutorial by Joshua Tauberer.

And should you be interested in the growing intersection between the NoSQL and Linked Data communities, you will be certain to enjoy the recording of Sandro Hawke's presentation [Toward Standards for NoSQL][Sandro talk] ([slides][Sandro slides], [blog post][Sandro post]) at the recent [NoSQL Live in Boston][NoSQL Live] conference in March 2010.

[origin]: http://www.semanticoverflow.com/questions/723/rdf-storages-vs-other-nosql-storages/755#755
[Semantic Overflow]:  http://www.semanticoverflow.com/
[RDF]:                http://www.w3.org/RDF/
[RDF intro]:          http://rdfabout.com/quickintro.xpd
[NoSQL]:              http://en.wikipedia.org/wiki/NoSQL
[Cassandra model]:    http://wiki.apache.org/cassandra/DataModel
[NoSQL slideshow]:    http://www.slideshare.net/harrikauhanen/nosql-3376398
[SPARQL]:             http://en.wikipedia.org/wiki/SPARQL
[Sesame]:             http://www.openrdf.org/
[Jena]:               http://jena.sourceforge.net/
[RDFLib]:             http://www.rdflib.net/
[RDF.rb]:             http://blog.datagraph.org/2010/03/rdf-for-ruby
[Berkeley DB]:        http://en.wikipedia.org/wiki/Berkeley_DB
[MemcacheDB]:         http://memcachedb.org/
[Tokyo Cabinet]:      http://1978th.net/tokyocabinet/
[Redis]:              http://code.google.com/p/redis/
[SimpleDB]:           http://aws.amazon.com/simpledb/
[CouchDB]:            http://couchdb.apache.org/
[MongoDB]:            http://www.mongodb.org/
[Riak]:               http://www.slideshare.net/hemulen/introducing-riak
[BigTable]:           http://en.wikipedia.org/wiki/BigTable
[Cassandra]:          http://cassandra.apache.org/
[HBase]:              http://hadoop.apache.org/hbase/
[Hypertable]:         http://hypertable.org/
[Neo4j]: http://www.slideshare.net/emileifrem/neo4j-the-benefits-of-graph-databases-oscon-2009
[InfoGrid]:           http://infogrid.org/
[HyperGraphDB]:       http://code.google.com/p/hypergraphdb/
[AllegroGraph]:       http://www.franz.com/agraph/allegrograph/
[4store]:             http://4store.org/
[Virtuoso]:           http://virtuoso.openlinksw.com/dataspace/dav/wiki/Main/
[RDF databases]:      http://www.w3.org/2001/sw/wiki/Category:Triple_Store
[Y2K38]:              http://en.wikipedia.org/wiki/Year_2038_problem
[semi-structured]:    http://en.wikipedia.org/wiki/Semi-structured_data
[RDF & NoSQL]:        http://decentralyze.com/2010/03/09/rdf-meets-nosql/
[Linked Data]:        http://linkeddata.org/
[N-Triples]:          http://blog.datagraph.org/2010/03/grepping-ntriples
[N-Quads]:            http://sw.deri.org/2008/07/n-quads/
[Cassandra WTF]:      http://arin.me/blog/wtf-is-a-supercolumn-cassandra-data-model
[Tim BL @ TED]:       http://www.youtube.com/watch?v=3YcZ3Zqk0a8
[directed graph]:     http://en.wikipedia.org/wiki/Directed_graph
[REST]:               http://en.wikipedia.org/wiki/Representational_State_Transfer
[EAV]:                http://en.wikipedia.org/wiki/Entity-attribute-value_model
[declarative]:        http://en.wikipedia.org/wiki/Declarative_programming
[URI]:                http://en.wikipedia.org/wiki/Uniform_Resource_Identifier
[Sandro post]:        http://decentralyze.com/2010/03/09/rdf-meets-nosql/
[Sandro talk]:        http://comlounge.tv/databases/cltv46
[Sandro slides]:      http://www.w3.org/2010/Talks/0311-nosql/talk.pdf
[NoSQL Live]:         http://nosql.mypopescu.com/post/443539413/reports-from-nosql-live-in-boston
