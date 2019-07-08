# smallfoot

This is a project written using [Lucky](https://luckyframework.org). Enjoy!

The goal is to build smallest Docker image needed to run the app.

### Notes

* The dotenv (.env) file is checked into the repo (normally it wouldn't be!)
* The docker-compose.yml is configured to run migrations and then the app
* To find IP address of the spun db image: ```docker network inspect smallfoot_internal``` after first ```docker-compose up``` attempt.
* It was suggested that I have three images, db, migrator, and app.  However, with this approach,
the first time images are launched, the migrator and app will come up nearly simultaneously and the app with crash out because migrations have not run, yet.  Although subsequent runs will work, it's not good practice anyway to run migrations while the app, that has new code depending on new tables or fields is also running, so this approach is not desired even if first run could be solved.

### Evolution

1. Started with Dockerfile from https://github.com/luckyframework/website-v2/blob/master/Dockerfile
2. Turned into multi-stage build
3. Began minimizing following https://manas.tech/blog/2017/04/03/shipping-crystal-apps-in-a-small-docker-image.html
4. Used https://gist.github.com/bcardiff/85ae47e66ff0df35a78697508fcb49af#gistcomment-2078660 instead of the list-deps.cr script
5. Removed the lucky_cli from system and built it instead from the installed shards of the library

### Setting up the project

### Gotchas

#### If attempting to use ```lucky db.migrate```:
  1. Realized this must be re-compiling on the fly as it needed various dependencies to build.
  2. Came up with alternative approach to add tasks.cr as a shard build target.
  3. This morphs the command to ```/app/bin/tasks db.migrate``` (see below for more)
  4. ```lucky db.migrate``` is a no-go because it will look for and fail to include ```prelude``` (which I verified does exist from shards install) at which point specific error message suggests I forgot to run ```shards install``` -- very likely I missed something obvious when copying files from prior layer's build image.


#### Realized I could compile and run ```tasks.cr``` and thus ```tasks db.migrate```
  1. following the trail of how ```lucky db.migrate``` works, realized ./tasks.cr could be compiled and executed and skip the lucky cli middleman.
  2. Added new target to shards.yml for this.
  3. Now have executable that runs via ```/app/bin/tasks db.migrate``` but will not connect to database when it's host name is ```db```.  It does connect when hostname is IP address of the host.
  4. however, cannot chain the migration together with running the app.  Using ```/app/bin/tasks db.migrate && /app/bin/smallfoot``` I get the following:
    ```
    Attaching to smallfoot_app
    app_1  | ********************************************************************************
    app_1  | production postgres://lucky:developer@172.30.0.2:5432/smallfoot_production
    app_1  | ********************************************************************************
    app_1  | Migrated CreateUsers::V00000000000001
    smallfoot_app exited with code 0
    ```

#### Build one off app that migrates the db and exits, i.e. ```/bin/app/db.migrate```

  1. Attempted to build a one-purpose app that simply connected and ran the migration and exited.
  2. Same issues encountered as with ```tasks db.migrate```
  3. In this case, command was ```/app/bin/db.migrate && /app/bin/smallfoot```

#### Failing to get ```tasks db.migrate```, turned attention to creating a migration specific executable. 

  1. see ```src/db.migrate```
  2. contains monkey patched library class methods so I could emit connect strings and verify
  3. idea was to set docker-compose command to ```/app/bin/db.migrate && /app/bin/smallfoot```
  4. exact same issues as above with ```tasks db.migrate```

#### Run the migration within the app itself!

  1. Final effort, lines 20 ~ 24 in ```config/database.cr``` would simply invoke the migrations before the app started up (currently commented out).
  2. Docker command reduces to just ```/app/bin/smallfoot```
  3. If ```db``` for DB_HOST is used, migrations won't connect and run.  Even if spawned, with sleep delay before attempting.  
  4. If IP address used for DB_HOST, it works, but again, app exits when the migration finishes.


1. [Install required dependencies](http://luckyframework.org/guides/installing.html#install-required-dependencies)
1. Run `script/setup`
1. Run `lucky dev` to start the app

### Learning Lucky

Lucky uses the [Crystal](https://crystal-lang.org) programming language. You can learn about Lucky from the [Lucky Guides](http://luckyframework.org/guides).
