# Copyright 2026 Thales France
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: Yannick Casamatta (yannick.casamatta@thalesgroup.com)

"""
Minimal stand-in for the CI engine, used by the macros.

A job is any callable; jobs form a dependency graph (the `needs:` of the
CI) run by a thread pool, with a semaphore per CAD tool licence pool. It
knows nothing of CVA6: what the pipeline runs is described by the macro,
in `flows/macros/`.
"""

import threading
import time
from concurrent.futures import ThreadPoolExecutor


# A job is submitted only once its dependencies passed AND a slot of its
# resource is free, so a worker never sits idle holding a license. A job
# whose dependency failed is reported as `skip`, and a failing job never
# stops the other branches of the graph: the whole pipeline is always
# played to the end and reported in one go.


class JobFailure(Exception):
    "Raised by a job to report a functional failure"


class Job:
    "A unit of work in the pipeline graph"

    def __init__(self, name, run, report_dir, deps, resource, allow_failure):
        self.name = name
        self.run = run
        self.report_dir = str(report_dir)
        self.deps = tuple(deps)
        self.resource = resource
        self.allow_failure = allow_failure


class JobResult:
    "Outcome of a job: status is 'pass', 'fail' or 'skip'"

    def __init__(self, job, status, duration=0.0, message=""):
        self.job = job
        self.status = status
        self.duration = duration
        self.message = message


class Scheduler:
    """
    Run a job graph with bounded concurrency per resource.

    `max_workers` caps the total number of running jobs; `resources`,
    e.g. `{"vcs": 10, "spyglass": 1}`, caps each license pool separately.
    All jobs sharing a resource name are counted together, so one pool
    can cover several recipes.

    `on_event(kind, job, result)` is called with kind "start" (result is
    None) then "done" (result is a JobResult), always from inside the
    scheduler lock: callbacks are serialized and may safely write to a
    shared report.
    """

    def __init__(self, resources=None, max_workers=8, on_event=None):
        self.jobs = []
        self.max_workers = max(1, int(max_workers))
        self._resources = dict(resources or {})
        self._on_event = on_event

    def add(self, name, run, report_dir, deps=(), resource=None, allow_failure=False):
        "Register a job and return its name, to be used as a dependency"
        if any(job.name == name for job in self.jobs):
            raise ValueError(f"duplicate job name: {name}")
        self.jobs.append(Job(name, run, report_dir, deps, resource, allow_failure))
        return name

    def unknown_deps(self):
        "Dependencies referencing a job that is not part of the graph"
        names = {job.name for job in self.jobs}
        return {
            job.name: absent
            for job in self.jobs
            if (absent := [d for d in job.deps if d not in names])
        }

    def run(self):
        """
        Execute the graph and return the JobResult list, in insertion
        order. Blocks until every job is done or skipped.
        """
        results = {}
        pending = {job.name: job for job in self.jobs}
        running = set()
        cond = threading.Condition()
        sems = {
            name: threading.Semaphore(max(1, int(limit)))
            for name, limit in self._resources.items()
        }

        def emit(kind, job, result=None):
            if self._on_event:
                self._on_event(kind, job, result)

        def done(job, result):
            "Record a result and emit its event (lock held)"
            results[job.name] = result
            emit("done", job, result)

        def worker(job):
            start = time.monotonic()
            try:
                job.run()
                result = JobResult(job, "pass", time.monotonic() - start)
            except Exception as e:  # a failed job must not kill the pipeline
                message = str(e) or type(e).__name__
                result = JobResult(job, "fail", time.monotonic() - start, message)
            with cond:
                running.discard(job.name)
                sem = sems.get(job.resource)
                if sem is not None:
                    sem.release()
                done(job, result)
                cond.notify_all()

        with ThreadPoolExecutor(
            max_workers=self.max_workers, thread_name_prefix="regression-job"
        ) as pool:
            with cond:
                while pending or running:
                    progress = False
                    for name, job in list(pending.items()):
                        deps = [results.get(d) for d in job.deps]
                        if any(r is None for r in deps):
                            continue
                        broken = [
                            d for d, r in zip(job.deps, deps) if r.status != "pass"
                        ]
                        if broken:
                            del pending[name]
                            reason = f"dependency not passed: {', '.join(broken)}"
                            done(job, JobResult(job, "skip", message=reason))
                            progress = True
                            continue
                        if len(running) >= self.max_workers:
                            break
                        sem = sems.get(job.resource)
                        if sem is not None and not sem.acquire(blocking=False):
                            continue
                        del pending[name]
                        running.add(name)
                        emit("start", job, None)
                        pool.submit(worker, job)
                        progress = True

                    # Nothing running and nothing startable: the rest of
                    # the graph is unreachable (cycle or unknown dep).
                    if pending and not running and not progress:
                        for name, job in list(pending.items()):
                            reason = "unmet dependency or dependency cycle"
                            done(job, JobResult(job, "fail", message=reason))
                            del pending[name]
                        continue

                    if pending or running:
                        cond.wait(timeout=0.2)

        return [results[job.name] for job in self.jobs]
