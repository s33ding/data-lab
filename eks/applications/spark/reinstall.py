#!/usr/bin/env python3
"""Reinstall Spark on EKS."""
import subprocess, sys, os

DIR = os.path.dirname(os.path.abspath(__file__))
subprocess.run([sys.executable, f"{DIR}/uninstall.py"]).check_returncode()
subprocess.run([sys.executable, f"{DIR}/install.py"]).check_returncode()
