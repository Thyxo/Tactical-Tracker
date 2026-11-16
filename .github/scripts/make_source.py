#!/usr/bin/env python3
"""Laver source.json til SideStore/AltStore ud fra den byggede .ipa.

Brug: make_source.py <ipa> <version> <build> <commit> <ud-fil>
"""
import json
import os
import sys
from datetime import datetime, timezone

ipa, version, build, commit, out = sys.argv[1:6]
repo = os.environ.get("GITHUB_REPOSITORY", "thyxo/Tactical-Tracker")
base = f"https://github.com/{repo}"
raw = f"https://raw.githubusercontent.com/{repo}/main"
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
icon = f"{raw}/App/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

source = {
    "name": "Tactical Tracker",
    "identifier": "com.thyxo.tacticaltracker.source",
    "subtitle": "Vane-tracker med en taktisk operatør",
    "description": "Tactical Tracker – vaner som daglige missioner, readiness, rank og udstyr. Alt ligger lokalt på telefonen.",
    "iconURL": icon,
    "website": base,
    "tintColor": "#C8A86B",
    "apps": [
        {
            "name": "Tactical Tracker",
            "bundleIdentifier": "com.thyxo.tacticaltracker",
            "developerName": "Thyxo",
            "subtitle": "Vane-tracker med en taktisk operatør",
            "localizedDescription": (
                "Klar dagens missioner, hold din operatørs readiness oppe, stig i rank og "
                "saml udstyr og våben-skins. Widget og Live Activity. Ingen konto, ingen server."
            ),
            "iconURL": icon,
            "tintColor": "#C8A86B",
            "category": "lifestyle",
            "screenshots": [],
            "versions": [
                {
                    "version": version,
                    "buildVersion": build,
                    "date": now,
                    "localizedDescription": f"Automatisk build af {commit[:7]}.",
                    "downloadURL": f"{base}/releases/download/latest/TacticalTracker.ipa",
                    "size": os.path.getsize(ipa),
                    "minOSVersion": "17.0",
                }
            ],
            "appPermissions": {
                "entitlements": ["com.apple.security.application-groups"],
                "privacy": {},
            },
        }
    ],
    "news": [],
}

with open(out, "w", encoding="utf-8") as f:
    json.dump(source, f, ensure_ascii=False, indent=2)
print(f"source.json: version {version} ({build}), {os.path.getsize(ipa)} bytes")
