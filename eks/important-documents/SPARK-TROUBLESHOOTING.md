# Spark on EKS — Troubleshooting

## Why Spark containers kept crashing (2026-05-01)

### Problem

Spark master and worker pods were in `CrashLoopBackOff` / `Completed` status.

### Root cause

We use the **official Apache Spark image** (`spark:3.5.8-python3`) but deploy it with the **Bitnami Helm chart** (`bitnami/spark`). Two issues:

1. **Bitnami's startup scripts don't exist in the official image.** The chart tries to run `/opt/bitnami/scripts/spark/run.sh`, which isn't there. The container exits immediately with no logs.

2. **The official `sbin/start-master.sh` and `start-worker.sh` run in the background.** They fork the JVM process via `spark-daemon.sh` and exit. In a container with no other foreground process, this means the container finishes and Kubernetes restarts it.

### Fix

Override `command` and `args` in `values.yaml` to use `spark-class`, which runs the JVM directly in the foreground:

```yaml
master:
  command:
    - /opt/spark/bin/spark-class
  args:
    - org.apache.spark.deploy.master.Master

worker:
  command:
    - /opt/spark/bin/spark-class
  args:
    - org.apache.spark.deploy.worker.Worker
    - spark://spark-master-svc:7077
```

### Key takeaway

When using a non-Bitnami image with the Bitnami Helm chart, always override `command`/`args` to bypass Bitnami's expected entrypoint. And for any Spark container, use `spark-class` instead of `start-*.sh` to keep the process in the foreground.
