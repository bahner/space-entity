# MyspaceObject

Generic object to be used in Myspace. Such an object could possibly be used on it's own,
and it's implementation has security implications down the road. Seems like a sensible thing 
to keep it separated.

It's intended use is as a generic actor as per Hewitt's actor model.
It uses [IPFS][ipfs], [IPNS][ipns] and [IPLD][ipld] from the InterPlanetary FileSystem
to achieve this. In particular it uses the experimental pubsub experiment,
and as such is likely to change substantially going forward. 

Since IPFS PubSub doesn't support authentication yet - it is just raw text being sent -
MyspaceObject creates and publishes a public key to IPNS in loose accordance with [IPID][ipid].
These keys are of one time used, and will be recreated it time an object is "instantiated".
It tries to preserve the IPNS key's however.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `myspace_object` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:myspace_object, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/myspace_object>.

[ipfs]: https://ipfs.tech/ "Interplanetary FileSystem"
[ipid]: https://did-ipid.github.io/ipid-did-method/ "IPID DID Method"
[ipld]: https://ipld.io/ "InterPlanetary Linked Data"
[ipns]: https://docs.ipfs.tech/concepts/ipns/ "InterPlanetary Name System"
