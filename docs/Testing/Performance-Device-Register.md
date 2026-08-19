# Performance Device Register

The devices the [Performance Harness](Performance-Harness) measures against, and
the baselines recorded for each.

A performance number only means something when it is attached to a specific
device. This register is the mapping from the `device_id` recorded in every
`perf-run.json` to the physical hardware it came from.

## Registered Devices

> **No devices are registered yet.** The perf-lab hardware has not been fixed,
> so no device ids, models or baselines can be recorded here. The harness does
> not depend on this table — it parameterizes on device id and records
> `device.model` as `null` until a device is registered.

| `device_id` | Model | Android version | Role | Registered |
|---|---|---|---|---|
| _(none yet)_ | | | | |

## Registering a Device

1. Attach the device to the perf-lab runner and read its id:

   ```bash
   fvm flutter devices --machine
   ```

2. Add a row above with the model and Android version.
3. Set the `PERF_DEVICE_ID` repository variable to the id of the device the
   scheduled run should use.
4. Let at least three scheduled runs complete before recording a baseline. A
   single run is a sample, not a baseline.

## Baselines

> **No baselines are recorded yet.** Recording one before the hardware is fixed
> would produce a number that cannot be reproduced or compared against.

| Device | Journey | Cold start (median) | Warm start (median) | Jank (p90 build) |
|---|---|---|---|---|
| _(none yet)_ | | | | |

Baselines are per **device and journey**. A baseline from one device says
nothing about another, and a baseline from one journey says nothing about a
different journey — see the `journey` field discussion in
[Performance Harness](Performance-Harness).

## Reading the Trend

Recorded runs live on the orphan `perf-data` branch:

```bash
git fetch origin perf-data
git show origin/perf-data:index.json
```

`index.json` carries one summary entry per run, ordered by capture time, with
the median startup figures and the path to the full record.
