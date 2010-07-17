The first time I ever sat down to write some real RDF code, I started, as one always should, with some tests.  Most of them went fine, but then I had to write a test that compared the equality of two graphs; I think this was for a parser in Scala, sometime last year, but I've lost track of what exactly I was looking at.  In any case, what a can of worms I opened.

It turns out that graph equality in RDF is hard.  The combination of blank and non-blank nodes makes it a [graph isomorphism problem][Wikipedia] that I have not found an exact equivalence for in straight-up graph theory.  Graphs with named vertices and edges have easy solutions, graphs with unnamed vertices and edges have other, difficult solutions.  The difference, depending on the type of graph, can be between _O(n)_ and _O(n!)_ on the number of nodes, so when selecting a possible solution, we'd like to avoid solutions that don't take naming into account.

The isomorphism problem is hard enough that many popular RDF implementations don't even include a solution for it.  [RDFLib][] for Python has an [approximation with a to-do note][RDFLib graph.py], I don't see an appropriate function in [Redland's model API][Redland model], and [Sesame][] has [an implementation][Sesame ModelUtil.java] with the following comment:

    // FIXME: this recursive implementation has a high risk of
    // triggering a stack overflow

My Java is rusty and I have no intention of polishing it up for this blog post, but I believe Sesame's implementation has factorial complexity.

Now, don't get me wrong.  Those are all free projects, and it's a tough problem to do right.  We over at [Datagraph][] just made do without an isomorphism function in either Scala or Ruby for several months rather than solve it.  So this is not intended to be a cheap shot at those projects -- in fact, we use both Redland and Sesame, and quite happily.  And if I'm wrong on the sparse nature of this landscape, someone please correct me.

However, we're developing a new [RDF library for Ruby][RDF.rb], so when it came time to really solve the problem, we wanted to solve it right.  Like most problems in computer science, it's actually old news.  [Jeremy Carroll][] solved it and [implemented it][Jena ModelMatcher.java] for [Jena][] either before or after writing a [great paper on the topic][HPL-2001-293].  What I'm about to describe is more or less his algorithm, and while I slightly adjusted the following to my style, I'm not about to say much that his paper doesn't.  So just go read the paper if that's your preference.

The algorithm can be described as a refinement of a naive _O(n!)_ graph isomorphism algorithm, in which each blank node is mapped onto each other blank node, followed by a consistency check.  The magic stems from RDF having these nifty [global identifiers][URI] for most vertices and all edges.  If we're smart about it, we can eliminate substantially all of the possible mappings before we try even our first speculative mapping.

I haven't done the math, but it would seem that one could generate a pathological case graph which would be _O(n!)_.  On the other hand, since RDF does not allow blank node predicates, and because the algorithm terminates on the first match, I haven't yet figured out how to create such a pathological graph for this algorithm.  Graphs tend to be either open enough to have a large number of solutions, one of which will be found quickly, or tight enough to have only one.

The algorithm works as follows:

1. Compare graph sizes and all statements without blank nodes.  If they do not match, fail.
1. Repeat, for each graph:
	1. Repeat, for each blank node:
		1. Mark the node as grounded or not.  A grounded node has only non-blank nodes or grounded nodes in statements in which it appears.
		1. Create a signature for the node.  A signature consists of a canonical representation of all of the statements a node appears in.
	1. Terminate unless we marked a node as grounded on this run.
1. Map grounded blank nodes to the other graph's grounded blank nodes where signatures match.
1. If all nodes are mapped, we have a bijection, which we can return.
1. Select ungrounded nodes from each graph with identical signatures.  Mark them as grounded, then recurse to step 2.
1. If no ungrounded nodes have the same signature, or we have tried all matching pairs, a bijection does not exist.  Fail.

In something approaching day-to-day English, what's happening here is that after eliminating the simple possibilities, we're generating a hash of all of the elements that appear with a given node in a graph.  We then create a node-to-hash mapping.  As the hashes will be the same for blank nodes on both input graphs, we use that hash to eliminate possible matchings before we try them.  Instead of trying every mapping, we try mappings only on nodes with the same signature.  The end result is an algorithm that requires a fairly pathological case to recurse *at all*, let alone to recurse deeply.  Nice.

At any rate, you can see the details, along with some test cases to play with, in [`RDF::Isomorphic`][RDF::Isomorphic] for RDF.rb.  This blog post coincides with release 0.1.0, which features a slightly improved signature algorithm, reducing the number of rounds required in some cases.  The [documentation][RDF::Isomorphic API] is also greatly improved -- I spent more time on this problem than I ever intended to, so I hope this can be a readable summary of the algorithm for anyone coming across this in the future.  Of course, RDF.rb's structure means almost anything using RDF.rb [can be tested for isomorphism][Hacking RDF] now, so hopefully it won't ever occur to you to read the code.

Of course, `RDF::Isomorphic` is in the [public domain][Unlicense], so should you find my implementation worthy, feel free to copy the code as directly as your framework or programming language allows.  And please feel free to do that without any obligation to provide attribution or any such silliness.

[Datagraph]:              http://blog.datagraph.org/
[RDF.rb]:                 http://rdf.rubyforge.org/
[RDF::Isomorphic]:        http://rubygems.org/gems/rdf-isomorphic
[RDF::Isomorphic API]:    http://rdf.rubyforge.org/isomorphic/
[RDFLib]:                 http://www.rdflib.net/
[RDFLib graph.py]:        http://code.google.com/p/rdflib/source/browse/trunk/rdflib/graph.py#780
[Redland model]:          http://librdf.org/docs/api/redland-model.html
[Sesame]:                 http://www.openrdf.org/
[Sesame ModelUtil.java]:  http://repo.aduna-software.org/websvn/filedetails.php?repname=aduna&path=%2Forg.openrdf%2Fsesame%2Ftrunk%2Fcore%2Fmodel%2Fsrc%2Fmain%2Fjava%2Forg%2Fopenrdf%2Fmodel%2Futil%2FModelUtil.java
[Jena]:                   http://jena.sourceforge.net/
[Jena ModelMatcher.java]: http://jena.cvs.sourceforge.net/viewvc/jena/jena/src/com/hp/hpl/mesa/rdf/jena/common/ModelMatcher.java?view=markup
[Jeremy Carroll]:         http://semanticweb.org/wiki/Jeremy_J._Carroll
[HPL-2001-293]:           http://www.hpl.hp.com/techreports/2001/HPL-2001-293.pdf
[URI]:                    http://en.wikipedia.org/wiki/Uniform_Resource_Identifier
[Hacking RDF]:            http://blog.datagraph.org/2010/02/hacking-rdf-in-ruby
[Unlicense]:              http://unlicense.org/
[Wikipedia]:              http://en.wikipedia.org/wiki/Graph_isomorphism_problem
