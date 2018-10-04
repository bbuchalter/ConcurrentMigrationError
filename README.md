This repo demonstrates an undesirable behavior currently found in ActiveRecord 5.2 and master:

Given a database which supports advisory locks,

When there are no runnable migrations,

Then ActiveRecord::Migrator should not attempt to acquire an advisory lock.

To see this behavior in action, simply run `run_test.sh`. Because this test requires a database which supports advisory locks, this script uses [dbdeployer](https://github.com/datacharmer/dbdeployer) to install, setup and run and teardown a sandboxed instance of MySQL. The script only modifies the contents of own directory.  It is safe to run repeatedly.

To understand why this behavior is undesirable, we have to look at a project outside Rails called [LHM](https://github.com/Shopify/lhm/). The purpose of LHM is to allow database migrations on large tables without downtime. Its primary value is being able to run for long periods of time, in the background, preparing a new version of the large table, and when ready, briefly holding a lock so it can switch out the old table for the table.

LHM migrations rely on the same underlying machinery as ActiveRecord migrations for determining which migrations have been run. As such, they are invoked within an ActiveRecord::Migration class. Thus, they acquire an advisory lock, just as an ActiveRecord migration would.

Since LHM migrations are generally long running, they are typically deployed via a separate process to avoid blocking code deployments. Additionally, the primary code deployment process typically includes a step to invoke ActiveRecord migrations automatically for convenience. Thus we come to the undesired behavior:
* When a LHM, wrapped in an ActiveRecord migration class, is deployed in a separate, long-running process, it acquires a lock.
* When a developer wishes to deploy code, NOT migrations, via another deployment process which invokes the ActiveRecord::Migrator...
* The [ConcurrentMigrationError](https://github.com/rails/rails/blob/v5.2.1/activerecord/lib/active_record/migration.rb#L1361) exception is raised, preventing deployments.
