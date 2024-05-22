import json as j
import math as m
import os
import re
import sys
import typing as ty
from collections import defaultdict as dd
from dataclasses import dataclass
from datetime import date as d
from datetime import datetime as dt
from datetime import time as t
from datetime import timedelta as td
from pathlib import Path as P

import httpx as h
import httpx_auth as ha

c = h.Client()
c.base_url = "https://example.com"
if token := os.environ.get("API_TOKEN"):
    c.auth = ha.HeaderApiKey(f"Bearer {token}", "Authorization")
    print("\x1b[31mRequests will use Bearer token auth\x1b[0m")
