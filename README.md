# Reusable Terraform modules for GFW

This module contains reusable terraform modules for GFW.
Currently, the following modules are available.

- AWS Batch Compute Environment
- AWS Container Registry
- AWS Fargate with autoscaling
- AWS SSM parameter store

When using modules, always refer to a version tag, never directly to master since breaking changes may occur.
Speaking of tags, to make a tag do `git tag -a <version_tag>` and then `git push --tags`
For example `git tag -a v0.4.2.8-beta1`.

NOTE: There is an unfortunate disconnect between the `dev` branch and the `master` branch. `master` has quite a few
additions which on brief inspection proved problematic for the GFW Data API use case (the details have been lost to
history). But before we had a chance to sort that out and harmonize the branches, others started consuming tags/releases
based on the master branch. So as it stands we have been making tags of <v0.4.3 used by GFW, while others (I think Pro?)
has been making releases/tags based on master. I am hoping to harmonize the branches soon (tm) and tag a 1.0 release,
and live happily ever after.

More details about usage in the corresponding module folders.
