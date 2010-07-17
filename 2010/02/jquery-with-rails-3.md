One of the most talked about features in Rails 3 is its plug & play architecture with various frameworks like Datamapper in place of ActiveRecord for the ORM or jQuery for javascript.  However, I've yet to see much info on how to actually do this with the javascript framework.

Fortunately, it looks like a lot of the hard work has already been done.  Rails now emits HTML that is compatible with the unobtrusive approach to javascript.  Meaning, instead of seeing a delete link like this:

    <a href="/users/1" onclick="if (confirm('Are you sure?')) { var f = document.createElement('form'); f.style.display = 'none'; this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;var m = document.createElement('input'); m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'delete'); f.appendChild(m);f.submit(); };return false;">Delete</a>

you'll now see it written as

    <a rel="nofollow" data-method="delete" data-confirm="Are you sure?" class="delete" href="/user/1">Delete</a>

This makes it very easy for a javascript driver to come along, pick out and identify the relevant pieces, and attach the appropriate handlers.

So, enough blabbing.  How do you get jQuery working with Rails 3?  I'll try to make this short and sweet.

Grab the jQuery driver at [http://github.com/rails/jquery-ujs](http://github.com/rails/jquery-ujs) and put it in your javascripts directory.  The file is at src/rails.js

Include jQuery (I just use the google hosted version) and the driver in your application layout or view.  In HAML it would look something like.

    = javascript_include_tag "http://ajax.googleapis.com/ajax/libs/jquery/1.4.1/jquery.min.js"
    = javascript_include_tag 'rails'

Rails requires an authenticity token to do form posts back to the server.  This helps protect your site against CSRF attacks.  In order to handle this requirement the driver looks for two meta tags that must be defined in your page's head. This would look like:

    <meta name="csrf-token" content="<%= form_authenticity_token %>" />
    <meta name="csrf-param" content="authenticity_token" />

In HAML this would be:

    %meta{:name => 'csrf-token', :content => form_authenticity_token}
    %meta{:name => 'csrf-param', :content => 'authenticity_token'}

**Update:** Jeremy Kemper points out that the above meta tags can written out with a single call to "csrf_meta_tag".

That should be all you need.  Remember, this is still a work in progress, so don't be surprised if there's a few bugs.  Please also note this has been tested with Rails 3.0.0.beta.
