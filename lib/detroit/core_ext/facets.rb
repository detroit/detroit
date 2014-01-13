# I know some people will be deterred by the dependency on Facets b/c they
# see it as a "heavy" dependency. But really that is far from true, consider
# the facet that the following libs are all that it used.

require 'facets/pathname'
#require 'facets/boolean'

require 'facets/array/not_empty'
require 'facets/module/basename'
require 'facets/module/alias_accessor'
require 'facets/kernel/yes'               # pulls in #ask and #no? too.
require 'facets/kernel/silence'           # FIXME ???
require 'facets/kernel/disable_warnings'

