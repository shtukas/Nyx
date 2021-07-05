### Asteroid Ids

An asteroid (full) Id is an expression of the form: `asteroid|nyxId|instanceId`, where `nyxId` is a nyx Id, essentially a UUID, and instance Id is a non empty string without the symbol `|`. An example of astroid Id is `asteroid|c6b038ab-a867-4fa5-9bd9-372f053f0b4b|7c0e`.

To be safe it's a good idea to use unique instance Ids, but the spec requirement is that two instanceIds of the same nyxId are different (which is equivalent to saying that different instances have different asteroid ids)

### Asteroid Database

```
asteroids.sqlite3
create table _asteroids_ (_recordId_ text, _asteroidId_ text, _nyxId_ text, _location_ text, _lastLocationConfirmationUnixtime_ real);
```





