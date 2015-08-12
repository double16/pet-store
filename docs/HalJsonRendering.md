Sharing Grails HAL and JSON Renderers
=====================================

[Grails](https://grails.org) provides nice features for creating web services, customization is usually terse. According to the "Registering Custom Objects Marshallers" section of the [Grails User Guide](https://grails.org/single-page-documentation.html), custom object marshallers can registered using a simple closure. However, it turns out that these marshallers do not apply if you are serving HAL (HATEOS) in addition to JSON/XML. This post will detail a method to share marshallers across XML, JSON and HAL flavors of web services.

# Create Adapter for Gson
The problem happens because the HAL renderer is using [Gson](https://sites.google.com/site/gson/gson-user-guide) for marshalling which does fit the following pattern in the Grails User Guide:
[addjs src="https://gist.github.com/double16/ba92843a0fc66836bb28.js?file=BootStrap-grailsexample.groovy"]

In order to include HAL in this list, we need to create an adapter class to register the closure. The adapter will then work the closure into the `Gson` library. Note that `Gson` performs input and output processing, the approach here only addresses output processing.

[addjs src="https://gist.github.com/double16/ba92843a0fc66836bb28.js?file=ClosureTypeAdapterFactory.groovy"]

We need a test, right? Of course we do!
[addjs src="https://gist.github.com/double16/ba92843a0fc66836bb28.js?file=ClosureTypeAdapterFactorySpec.groovy"]

# Adapter Registration
Now that we have an adapter we need to register it as a Spring bean to make it available in `BootStrap.groovy`.
[addjs src="https://gist.github.com/double16/ba92843a0fc66836bb28.js?file=resources.groovy"]

# Marshaller Registration
Now for the part for which we've been waiting. These are only examples and not necessary to make this work for your own marshallers.
[addjs src="https://gist.github.com/double16/ba92843a0fc66836bb28.js?file=BootStrap.groovy"]

The new `GSONFAC` has the `registerObjectMarshaller` method like `JSON` and `XML`. Using the Groovy splat operator, we can easily re-use the closure.

This was a difficult find for me, why the JSON tests were working but HAL was not. Hopefully this post will save you time and write less code!

