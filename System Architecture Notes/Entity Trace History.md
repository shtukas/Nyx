### Entity Trace History

Entity Trace History is a service that records the [trace], a hash of contents, of Nyx entities, including the asteroids.

The service records arrays of the form 

```
(entityId, trace, timestamp)
```

Given an entity we can then extract its time ordered sequence of traces.

Given two entities E1 and E3 which are originally clone of ech other, we would expect their traces to be identical. If E1 is then modified, it will get a new trace. The latest trace of E2 will no longer be equal to the latest trace of E1, but the latest trace of E2 will appear as a past trace of E1. This means that we can make E2 mirroring E1 to "catchup", at each point E1 and E2 will be identical and wil have similar traces. 

If it ever happens that the traces of E1 and E2 are not identical and do not appear in each other's past, this means that E1 and E2 have both been independently modified (and that there was no reconciliation between the two modifications). Such a case will have to be dealt with manually.

```
entity-trace-history.sqlite3
create table _history_ (_recordId_ text, _entityId_ text, _trace_ text, _unixtime_ real);
```

The command line tool `entity-trace-history` implements the service's interface. 