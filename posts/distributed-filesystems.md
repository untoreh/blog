+++
date = "4/17/2021"
title = "Distributed Filesystems"
tags = ["tools"]
rss_description = "A round-up of distributed file systems"
+++

## Goals

- Ability to store data and **meta data**
- **Resiliency** to single nodes failures
- **Flexibility** to expand or shrink the network at any time
- Being able to run on very **low memory** servers

## Distributed file systems?

A [distributed file system], generally, provide a _ideally_ [POSIX] compliant file system interface. This is the most piece of its definition because building a cluster of nodes that hold data in a distributed fashion can be achieved in many different ways, but building one that provides access to a _usable_ file system interface is challenging. A file filesystem is usually assumed to be _local_ and as such, many applications assume fast access to it, disregarding possible latency issues that might arise on a file-system backed by a remote data. Very few applications discern between local and remote file systems.

Swapping out a file-systems with a distributed one can be considered a form of _backward compatibility_...in the case you want to deploy an application in a cloud environment that relies on file system access for its data layer, the cloud has to provide a file system interface that can arbitrarily replicate across machines. However, in a single user case, it can also be considered as a way to reduce managing overhead...instead of tracking backups for data from every single server you run, you can track the health of the network based file system and schedule backups on it.

If you don't need strict access to file systems semantics, a distributed object storage interface is simpler and as _portable_ and _universal_ as a file system, with less of synchronicity burden on the network since an object storage per se, doesn't hold meta data. Some object storage software offers a file-system interface built on top.

## Round up

Since our goal is **not** big data, we ignore solutions like [HDFS].

- [OpenAFS] : this is not a properly distributed file system, since it is _federated_ which means that single node failures can cause disruption.
- [MinFS] : MinFS is a fuse driver for MinIO, which is a straight forward distributed object storage with erasure coding, but it doesn't appear to be cheap on resources.
- [xtreemefs] : XtreemeFS achieves resiliency with equivalent of RAID0 over network
- [glusterfs] : easy to setup but poor performance
- [ceph] : harder to setup (and manage) but with very good (and tunable) performance
- [lizardfs] : decent performance, low initial memory footprint but high under heavy load
- [orangefs] : minimal footprint, both kernel module and fuser module, waiting on v3 for async metadata
- [beegfs] : low footprint, kernel module (but unmaintained fuser module), best performance
- [seaweedfs] : easily plug-able object storage with fuser module

Here some benchmark result in a table, they do not cover all the file systems, and might be outdated at this point, and in the `f2fs` results caching might have slipped through :)

## Bandwidth

\output{./../benchFs.jl}

## IOPS

\output{./../benchFsIOPS.jl}

## Resources

\output{./../benchFsResources.jl}

## Data

Here are the benchmarks data

- [raw bmark]
- [zfs bmark]
- [f2fs bmark]
- [xtreemfs bmark]
- [glusterfs bmark]
- [orangefs bmark]
- [beegfs bmark]
- [bmark script]
- [bmark config]

The sysctl knobs were tuned for max throughput, but they should be arguably useless, and probably skew the benchmarks, since in an heterogeneous network those knobs are not always applied, and anyways they are _network dependent_, so even if they are applied, there could be other bottlenecks in place.

Additional comparisons, [from wikipedia], [from seaweedfs].

<!-- prettier-ignore-start -->

[from wikipedia]: https://en.wikipedia.org/wiki/Comparison_of_distributed_file_systems
[from seaweedfs]: https://github.com/chrislusf/seaweedfs#compared-to-other-file-systems
[bmark script]: \assets/posts/benchmarks/fs/bench.txt
[bmark config]: \assets/posts/benchmarks/fs/sysctl.txt
[raw bmark]: \assets/posts/benchmarks/fs/rawfs.txt
[zfs bmark]: \assets/posts/benchmarks/fs/zfs.txt
[f2fs bmark]: \assets/posts/benchmarks/fs/f2fs.txt
[xtreemfs bmark]: \assets/posts/benchmarks/fs/xtreemfs.txt
[glusterfs bmark]: \assets/posts/benchmarks/fs/glusterfs.txt
[orangefs bmark]: \assets/posts/benchmarks/fs/orangefs.txt
[beegfs bmark]: \assets/posts/benchmarks/fs/beegfs.txt
[seaweedfs]: https://github.com/chrislusf/seaseaweedfs
[beegfs]: https://www.beegfs.io/c/
[orangefs]: https://github.com/waltligon/orangefs
[lizardfs]: https://github.com/lizardfs/lizardfs
[ceph]: https://docs.ceph.com/en/latest/cephfs/index.html
[glusterfs]: https://www.gluster.org/
[xtreemefs]: http://www.xtreemfs.org/all_features.php
[MinFS]: https://github.com/minio/minfs
[OpenAFS]: https://www.openafs.org/
[HDFS]: https://hadoop.apache.org/
[POSIX]: https://en.wikipedia.org/wiki/POSIX
[distributed file system]: https://en.wikipedia.org/wiki/Clustered_file_system#Distributed_file_systems
[HDFS]: https://hadoop.apache.org/

<!-- prettier-ignore-end -->
