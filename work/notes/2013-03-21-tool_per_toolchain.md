# Tool Per Toolchain?

Should a tool class be designed specifically for a spefic toolchian
or should tools be able to be used by any toolchain?

If a tool can work for any toolchain, it means that station names are
"global". A station called `document` in one toolchain, for example, would
be expected to represent essentially the same thing in another toolchain. 
That might makes sense for a term like "document", but more abstract station
names might not match up as well, such as "process" or "reduce". It also means
that tools may incidently have methods with names that match a toolchain's
station that were not intended for use with that toolchain. To fix this
some way of designating methods specifically as station calls would be needed.
Implementation wise this is the simplest approach, but it leaves the odus on
the end-user to use only tools that make sense for the given toolchain.

On the other hand, if tools are per toolchain, then a tool class can simply define
the methods that match the station names. That's convenient, but it limits the
usefulness of tools. We would have to create a whole new tool, quite possibly
identical in almost every other respect, just to interface with a different
toolchain. One way around this though is to support adapters which map one toolchain
to another. So if such an adapter exists then the tool can be used even if it wasn't
specifically created for a toolchain. Technically, that might be the most percise
approach. But is it worth the additional complexity?

**(2013-03-21)**
