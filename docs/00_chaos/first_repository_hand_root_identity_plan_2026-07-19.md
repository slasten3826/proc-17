# First Repository Hand Root Identity Plan

Status:

```text
layer: CHAOS / implementation boundary
date: 2026-07-19
roadmap: 7.4 of 7.10
production mutation authority: absent
router authority: unchanged
```

Implementation observation:

```text
This boundary was implemented and tested in roadmap step 7.4.
See first_repository_hand_root_identity_results_2026-07-19.md.
```

## 0. Claim

Step 7.4 gives the provider one new ability:

```text
hold and re-observe the identity of one host-granted repository directory
```

It does not give the provider a file operation. The only Linux operations
admitted by this step are read-only descriptor and metadata operations required
to establish or release directory identity:

```text
openat2
fstat/statx
close
```

No Packet, substrate, target repository or semantic field selects the native
module or mints this authority. The trusted host supplies an absolute
`project_base`; the private capability registry supplies the normalized
repository-relative path.

## 1. Root Chain

The native provider must perform one exact chain:

```text
validate bounded project_base and repository_path bytes
  -> open project_base with NO_SYMLINKS + NO_MAGICLINKS
  -> capture base device/inode/mount identity
  -> open repository relative to base with BENEATH + NO_SYMLINKS
     + NO_MAGICLINKS + NO_XDEV
  -> capture repository device/inode/mount identity
  -> retain descriptors, paths and identities in opaque full userdata
  -> return a detached identity record to Lua
```

There is no `open(2)` or `realpath` fallback if `openat2` or its resolution
policy is unavailable.

## 2. Revalidation

`revalidate(handle)` does not trust the retained descriptor alone. It reopens
the named base and repository through the same policy and compares:

```text
base device/inode/mount
repository device/inode/mount
```

Only an exact match returns `outcome=valid`. A missing, replaced, symlinked or
mount-substituted named root returns `root_changed`. The retained descriptor may
still identify the old inode, but authority must not migrate to a replacement
at the old pathname.

## 3. Handle Law

The handle is full userdata with one private metatable. It contains no Lua table
fields and exposes no descriptor, host path or methods. Its only public use is
as an argument to the normalized provider adapter.

```text
foreign userdata -> loud trusted-contract failure
number/string/table -> rejected before native call
explicit close -> closes all retained descriptors exactly once
second close -> true, no syscall against a reused descriptor
garbage collection -> same idempotent close path
revalidate after close -> typed handle_closed refusal
```

## 4. Failure Classes

```text
invalid bounded host request
  -> contract/invalid_request, zero filesystem call

missing/symlink/non-directory/permission/containment failure at first open
  -> typed world failure with no handle

named identity differs after a successful open
  -> world/root_changed

malformed native identity/result, foreign userdata or impossible close state
  -> loud harness failure
```

No failure is converted into Packet death in this step because the provider is
not connected to the effect boundary yet.

## 5. Red Corpus Before Implementation

The 7.4 corpus must grow real lives only inside the identity-owned fixture:

```text
exact base/root opens to opaque userdata
stable revalidation succeeds
repository-root symlink is denied
project-base symlink is denied
missing and non-directory roots are typed
repository replacement is detected
project-base replacement is detected
renamed-away root is detected
explicit close is idempotent
GC returns descriptor count to baseline
foreign userdata and scalar handles fail loudly
real capability mint exposes no path or handle
fixture tree is byte/name/type/mode unchanged by open/revalidate/close
```

The filesystem snapshot is taken only below the fixture identity. Test cleanup
remains owned by `proc17_fixture_guard`; no broad deletion command is admitted.

## 6. Falsifiers

Step 7.4 is false if:

```text
any file or directory is created, renamed, removed or chmodded by production code
any symlink component is followed
repository resolution can leave project_base or cross a mount
revalidation accepts a replacement base/root
a file descriptor or absolute path appears in a public projection
a foreign userdata is accepted as a repository handle
explicit close or GC leaks/re-closes a descriptor
openat2 failure falls back to a weaker path algorithm
```

## 7. Exit Boundary

After 7.4 the body may know where one granted repository physically is and may
prove that it is still the same directory. It still cannot alter that directory.
Step 7.5 alone owns the first mutation primitive.
