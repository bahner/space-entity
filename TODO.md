# Baby steps

Subscribe to channel
Only read messages that are encrypted to it.
NB! The supervisors crashes on the slightest error. Find a way to confine errors.

Add task queue for publication of objects. We want to make sure they are carried out sequentially.
Depends a bit of how often state.object is changed. If it only contains definitions, it probably not so important.
But if an attribute, eg. hair-color is changed 31 times in 3 seconds, then.  We have a problem. Periodic publications is propably a better idea.
Another idea is to save the object to a file, so we always have copy, and then publish every now and then

Vault
---

Find a nice implementatoin for storing secrets. We should probably add the possibility of  VAULT_TOKEN to object. This should be set from the outside, as it's not possible to store in the object in any way. This means that there must exist some Dispatcher, which creates objects and map them to the vault. For dev we can just deliver out the root token, but later this requires it's own sensitive genserver, which distributes tokens. This should also be the object dispathcher.

Ideally it just stores one admin token, and generates the rest on the fly.

The intention is to store ssh keys and passwords in there, so it's a big deal.

This opens up a whole can of worms: who owns the object and how to implement AUTHZ in usage. Bit did:ipid is definitely a start.

Which identity should be granted access? IPNS or oid? Obviously if I have ipns://bahner.com the could be granted access. That means I can rekey it, 

# state.dag
The object object should not be stored in the actual object. It should have it's own agent which handles this KV. This way we can easily dag the *whole* remaining object and create a dag for that and store that.

Hrm, but the key is also not permanenet and saving the private key is a clear NO. So, we need a mini me. And a seed object containting, the ID, create, object_dag, So actual we can just have a gen_seed function which wraps the *permament* parameters. When doing this the state.object should be stored and the dag updated firshould not be stored in the actual object. It should have it's own agent which handles this KV. This way we can easily dag the *whole* remaining object and create a dag for that and store that.

Hrm, but the key is also not permanenet and saving the private key is a clear NO. So, we need a mini me. And a seed object containting, the ID, create, object_dag, So actual we can just have a gen_seed function which wraps the *permament* parameters. When doing this the state.object should be stored and the dag updated first. Then it's pretty much ready for offline storage in the form of a dag..
This dag can then be store in a long file of objects to start / create when the application starts.
MyspaceObject.new(dag) then gets a new meaning. It's not the dag of the state.object, but of an object containing the state object
state.object: mystateobjectdag
  contents:
    - Pick Axe
    - Ender Pearl
    - Diamond
  description: A chest
  traits:
    - lockable
    - containable
  methods:
    - put
    - get
    - open
    - close
    - lock
    - unlock
  state.created: 2023-02-18T23:07:42.010631Z
  state.id: :kVdRwgKEIBGi39H2GFPU_
  
  minime: ObjectDAG
    id: :kVdRwgKEIBGi39H2GFPU_
    created: 2023-02-18T23:07:42.010631Z
    object: %{/: mystateobjectdag}

Do remember, that if you store these vaules in MFS they are automatically pinned. Or you could use a pinning service. To be reckoned with.
This is not for the MyspaceObject module, though. That's more for Myspace
