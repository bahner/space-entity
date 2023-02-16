# Baby steps

Subscribe to channel
Only read messages that are encrypted to it.

Add task queue for publication of objects. We want to make sure they are carried out sequentially.
Depends a bit of how often state.object is changed. If it only contains definitions, it probably not so important.
But if an attribute, eg. hair-color is changed 31 times in 3 seconds, then.  We have a problem. Periodic publications is propably a better idea.
Another idea is to save the object to a file, so we always have copy, and then publish every now and then:x
